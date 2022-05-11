import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:openhaystack_mobile/accessory/accessory_icon_model.dart';
import 'package:openhaystack_mobile/findMy/find_my_controller.dart';
import 'package:openhaystack_mobile/location/location_model.dart';

class Pair<T1, T2> {
  final T1 a;
  final T2 b;

  Pair(this.a, this.b);
}


const defaultIcon = Icons.push_pin;


class Accessory {
  /// The ID of the accessory key.
  String id;
  /// A hash of the public key.
  /// An identifier for the private key stored separately in the key store.
  String hashedPublicKey;
  /// If the accessory uses rolling keys.
  bool usesDerivation;

  // Parameters for rolling keys (only relevant is usesDerivation == true)
  String? symmetricKey;
  double? lastDerivationTimestamp;
  int? updateInterval;
  String? oldestRelevantSymmetricKey;
  
  /// The display name of the accessory.
  String name;
  /// The display icon of the accessory.
  String _icon;
  /// The display color of the accessory.
  Color color;

  /// If the accessory is active.
  bool isActive;
  /// If the accessory is already deployed
  /// (and could therefore send locations).
  bool isDeployed;

  /// The timestamp of the last known location
  /// (null if no location known).
  DateTime? datePublished;
  /// The last known locations coordinates
  /// (null if no location known).
  LatLng? _lastLocation;

  /// A list of known locations over time.
  List<Pair<LatLng, DateTime>> locationHistory = [];

  /// Stores address information about the current location.
  Future<Placemark?> place = Future.value(null);


  /// Creates an accessory with the given properties.
  Accessory({
    required this.id,
    required this.name,
    required this.hashedPublicKey,
    required this.datePublished,
    this.isActive = false,
    this.isDeployed = false,
    LatLng? lastLocation,
    String icon = 'mappin',
    this.color = Colors.grey,
    this.usesDerivation = false,
    this.symmetricKey,
    this.lastDerivationTimestamp,
    this.updateInterval,
    this.oldestRelevantSymmetricKey,
  }): _icon = icon, _lastLocation = lastLocation, super() {
    _init();
  }

  void _init() {
    if (_lastLocation != null) {
      place = LocationModel.getAddress(_lastLocation!);
    }
  }

  /// Creates a new accessory with exactly the same properties of this accessory.
  Accessory clone() {
    return Accessory(
      datePublished: datePublished,
      id: id,
      name: name,
      hashedPublicKey: hashedPublicKey,
      color: color,
      icon: _icon,
      isActive: isActive,
      isDeployed: isDeployed,
      lastLocation: lastLocation,
      usesDerivation: usesDerivation,
      symmetricKey: symmetricKey,
      lastDerivationTimestamp: lastDerivationTimestamp,
      updateInterval: updateInterval,
      oldestRelevantSymmetricKey: oldestRelevantSymmetricKey,
    );
  }

  /// Updates the properties of this accessor with the new values of the [newAccessory].
  void update(Accessory newAccessory) {
    datePublished = newAccessory.datePublished;
    id = newAccessory.id;
    name = newAccessory.name;
    hashedPublicKey = newAccessory.hashedPublicKey;
    color = newAccessory.color;
    _icon = newAccessory._icon;
    isActive = newAccessory.isActive;
    isDeployed = newAccessory.isDeployed;
    lastLocation = newAccessory.lastLocation;
  }

  /// The last known location of the accessory.
  LatLng? get lastLocation {
    return _lastLocation;
  }

  /// The last known location of the accessory.
  set lastLocation(LatLng? newLocation) {
    _lastLocation = newLocation;
    if (_lastLocation != null) {
      place = LocationModel.getAddress(_lastLocation!);
    }
  }

  /// The display icon of the accessory.
  IconData get icon {
    IconData? icon = AccessoryIconModel.mapIcon(_icon);
    return icon ?? defaultIcon;
  }

  /// The cupertino icon name.
  String get rawIcon {
    return _icon;
  }

  /// The display icon of the accessory.
  setIcon (String icon) {
    _icon = icon;
  }

  /// Creates an accessory from deserialized JSON data.
  /// 
  /// Uses the same format as in [toJson]
  /// 
  /// Typically used with JSON decoder.
  /// ```dart
  ///   String json = '...';
  ///   var accessoryDTO = Accessory.fromJSON(jsonDecode(json));
  /// ```
  Accessory.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        hashedPublicKey = json['hashedPublicKey'],
        datePublished = json['datePublished'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['datePublished']) : null,
        _lastLocation = json['latitude'] != null && json['longitude'] != null
          ? LatLng(json['latitude'].toDouble(), json['longitude'].toDouble()) : null,
        isActive = json['isActive'],
        isDeployed = json['isDeployed'],
        _icon = json['icon'],
        color = Color(int.parse(json['color'], radix: 16)),
        usesDerivation = json['usesDerivation'] ?? false,
        symmetricKey = json['symmetricKey'],
        lastDerivationTimestamp = json['lastDerivationTimestamp'],
        updateInterval = json['updateInterval'],
        oldestRelevantSymmetricKey = json['oldestRelevantSymmetricKey'] {
    _init();
  }

  /// Creates a JSON map of the serialized accessory.
  /// 
  /// Uses the same format as in [Accessory.fromJson].
  /// 
  /// Typically used by JSON encoder.
  /// ```dart
  ///   var accessory = Accessory(...);
  ///   jsonEncode(accessory);
  /// ```
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hashedPublicKey': hashedPublicKey,
    'datePublished': datePublished?.millisecondsSinceEpoch,
    'latitude': _lastLocation?.latitude,
    'longitude': _lastLocation?.longitude,
    'isActive': isActive,
    'isDeployed': isDeployed,
    'icon': _icon,
    'color': color.toString().split('(0x')[1].split(')')[0],
    'usesDerivation': usesDerivation,
    'symmetricKey': symmetricKey,
    'lastDerivationTimestamp': lastDerivationTimestamp,
    'updateInterval': updateInterval,
    'oldestRelevantSymmetricKey': oldestRelevantSymmetricKey,
  };

  /// Returns the Base64 encoded hash of the advertisement key
  /// (used to fetch location reports).
  Future<String> getHashedAdvertisementKey() async {
    var keyPair = await FindMyController.getKeyPair(hashedPublicKey);
    return keyPair.getHashedAdvertisementKey();
  }

  /// Returns the Base64 encoded advertisement key
  /// (sent out by the accessory via BLE).
  Future<String> getAdvertisementKey() async {
    var keyPair = await FindMyController.getKeyPair(hashedPublicKey);
    return keyPair.getBase64AdvertisementKey();
  }

  /// Returns the Base64 encoded private key.
  Future<String> getPrivateKey() async {
    var keyPair = await FindMyController.getKeyPair(hashedPublicKey);
    return keyPair.getBase64PrivateKey();
  }

}
