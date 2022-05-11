import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openhaystack_mobile/accessory/accessory_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:openhaystack_mobile/findMy/find_my_controller.dart';
import 'package:openhaystack_mobile/findMy/models.dart';

const accessoryStorageKey = 'ACCESSORIES';

class AccessoryRegistry extends ChangeNotifier {

  final _storage = const FlutterSecureStorage();
  final _findMyController = FindMyController();
  List<Accessory> _accessories = [];
  bool loading = false;
  bool initialLoadFinished = false;

  /// Creates the accessory registry.
  /// 
  /// This is used to manage the accessories of the user.
  AccessoryRegistry() : super();

  /// A list of the user's accessories.
  UnmodifiableListView<Accessory> get accessories => UnmodifiableListView(_accessories);

  /// Loads the user's accessories from persistent storage.
  Future<void> loadAccessories() async {
      loading = true;
      String? serialized = await _storage.read(key: accessoryStorageKey);
      if (serialized != null) {
        List accessoryJson = json.decode(serialized);
        List<Accessory> loadedAccessories =
          accessoryJson.map((val) => Accessory.fromJson(val)).toList();
        _accessories = loadedAccessories;
      } else {
        _accessories = [];
      }

      // For Debugging:
      // await overwriteEverythingWithDemoDataForDebugging();

      loading = false;

      notifyListeners();
  }

  /// __USE ONLY FOR DEBUGGING PURPOSES__
  /// 
  /// __ALL PERSISTENT DATA WILL BE LOST!__
  /// 
  /// Overwrites all accessories in this registry with demo data for testing.
  Future<void> overwriteEverythingWithDemoDataForDebugging() async {
    // Delete everything to start with a fresh set of demo accessories
    await _storage.deleteAll();

    // Load demo accessories
    List<Accessory> demoAccessories = [
      Accessory(hashedPublicKey: 'TrnHrAM0ZrFSDeq1NN7ppmh0zYJotYiO09alVVF1mPI=',
        id: '-5952179461995674635', name: 'Raspberry Pi', color: Colors.green,
        datePublished: DateTime.fromMillisecondsSinceEpoch(1636390931651),
        icon: 'gift.fill', lastLocation: LatLng(49.874739, 8.656280)),
      Accessory(hashedPublicKey: 'TrnHrAM0ZrFSDeq1NN7ppmh0zYJotYiO09alVVF1mPI=',
        id: '-5952179461995674635', name: 'My Bag', color: Colors.blue,
        datePublished: DateTime.fromMillisecondsSinceEpoch(1636390931651),
        icon: 'case.fill', lastLocation: LatLng(49.874739, 8.656280)),
      Accessory(hashedPublicKey: 'TrnHrAM0ZrFSDeq1NN7ppmh0zYJotYiO09alVVF1mPI=',
        id: '-5952179461995674635', name: 'Car', color: Colors.red,
        datePublished: DateTime.fromMillisecondsSinceEpoch(1636390931651),
        icon: 'car.fill', lastLocation: LatLng(49.874739, 8.656280)),
    ];
    _accessories = demoAccessories;

    // Store demo accessories for later use
    await _storeAccessories();

    // Import private key for demo accessories
    // Public key hash is TrnHrAM0ZrFSDeq1NN7ppmh0zYJotYiO09alVVF1mPI=
    await FindMyController.importKeyPair('siykvOCIEQRVDwrbjyZUXuBwsMi0Htm7IBmBIg==');
  }

  /// Fetches new location reports and matches them to their accessory.
  Future<void> loadLocationReports() async {
    List<Future<List<FindMyLocationReport>>> runningLocationRequests = [];

    // request location updates for all accessories simultaneously
    List<Accessory> currentAccessories = accessories;
    for (var i = 0; i < currentAccessories.length; i++) {
      var accessory = currentAccessories.elementAt(i);

      var keyPair = await FindMyController.getKeyPair(accessory.hashedPublicKey);
      var locationRequest = FindMyController.computeResults(keyPair);
      runningLocationRequests.add(locationRequest);
    }

    // wait for location updates to succeed and update state afterwards
    var reportsForAccessories = await Future.wait(runningLocationRequests);
    for (var i = 0; i < currentAccessories.length; i++) {
      var accessory = currentAccessories.elementAt(i);
      var reports = reportsForAccessories.elementAt(i);
      
      print("Found ${reports.length} reports for accessory '${accessory.name}'");

      accessory.locationHistory = reports
        .where((report) => report.latitude.abs() <= 90 && report.longitude.abs() < 90 )
        .map((report) => Pair<LatLng, DateTime>(
          LatLng(report.latitude, report.longitude),
          report.timestamp ?? report.published,
        ))
        .toList();

      if (reports.isNotEmpty) {
        var lastReport = reports.first;
        accessory.lastLocation = LatLng(lastReport.latitude, lastReport.longitude);
        accessory.datePublished = lastReport.timestamp ?? lastReport.published;
      }
    }

    // Store updated lastLocation and datePublished for accessories
    _storeAccessories();

    initialLoadFinished = true;
    notifyListeners();
  }

  /// Stores the user's accessories in persistent storage.
  Future<void> _storeAccessories() async {
    List jsonList = _accessories.map(jsonEncode).toList();
    await _storage.write(key: accessoryStorageKey, value: jsonList.toString());
  }

  /// Adds a new accessory to this registry.
  void addAccessory(Accessory accessory) {
    _accessories.add(accessory);
    _storeAccessories();
    notifyListeners();
  }

  /// Removes [accessory] from this registry.
  void removeAccessory(Accessory accessory) {
    _accessories.remove(accessory);
    // TODO: remove private key from keychain
    _storeAccessories();
    notifyListeners();
  }

  /// Updates [oldAccessory] with the values from [newAccessory].
  void editAccessory(Accessory oldAccessory, Accessory newAccessory) {
    oldAccessory.update(newAccessory);
    _storeAccessories();
    notifyListeners();
  }
}
