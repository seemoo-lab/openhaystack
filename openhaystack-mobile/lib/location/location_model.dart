import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geocode;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class LocationModel extends ChangeNotifier {
  LatLng? here;
  geocode.Placemark? herePlace;
  StreamSubscription<LocationData>? locationStream;
  final Location _location = Location();
  bool initialLocationSet = false;

  /// Requests access to the device location from the user.
  /// 
  /// Initializes the location services and requests location
  /// access from the user if not granged.
  /// Returns if location access was granted.
  Future<bool> requestLocationAccess() async {
    // Enable location service
    var serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        print('Could not enable location service.');
        return false;
      }
    }

    // Request location access from user if not permanently denied or already granted
    var permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      
    }

    if (permissionGranted == PermissionStatus.granted) {
      // Permission not granted
      return true;
    } else if (permissionGranted == PermissionStatus.grantedLimited) {
      // Permission granted to access approximate location
      return false;
    } else {
      // Permission not granted
      return false;
    }
  }

  /// Requests location updates from the platform.
  /// 
  /// Listeners will be notified about locaiton changes.
  Future<void> requestLocationUpdates() async {
    var permissionGranted = await requestLocationAccess();
    if (permissionGranted) {

      // Handle future location updates
      locationStream ??= _location.onLocationChanged.listen(_updateLocation);

      // Fetch the current location
      var locationData = await _location.getLocation();
      _updateLocation(locationData);
    } else {
      initialLocationSet = true;
      if (locationStream != null) {
        locationStream?.cancel();
        locationStream = null;
      }
      _removeCurrentLocation();
      notifyListeners();
    }
  }

  /// Updates the current location if new location data is available.
  /// 
  /// Additionally updates the current address information to match
  /// the new location.
  void _updateLocation(LocationData locationData) {
    if (locationData.latitude != null && locationData.longitude != null) {
      // print('Locaiton here: ${locationData.latitude!}, ${locationData.longitude!}');
      here = LatLng(locationData.latitude!, locationData.longitude!);
      initialLocationSet = true;
      getAddress(here!)
        .then((value) {
          herePlace = value;
          notifyListeners();
        });
    } else {
      print('Received invalid location data: $locationData');
    }
    notifyListeners();
  }

  /// Cancels the listening for location updates.
  void cancelLocationUpdates() {
    if (locationStream != null) {
      locationStream?.cancel();
      locationStream = null;
    }
    _removeCurrentLocation();
    notifyListeners();
  }

  /// Resets the currently stored location and address information
  void _removeCurrentLocation() {
    here = null;
    herePlace = null;
  }

  /// Returns the address for a given geolocation (latitude & longitude).
  /// 
  /// Only works on mobile platforms with their local APIs.
  static Future<geocode.Placemark?> getAddress(LatLng? location) async {
    if (location == null) {
      return null;
    }
    double lat = location.latitude;
    double lng = location.longitude;

    try {
      List<geocode.Placemark> placemarks = await geocode.placemarkFromCoordinates(lat, lng);
      return placemarks.first;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null; 
    }
  }

}
