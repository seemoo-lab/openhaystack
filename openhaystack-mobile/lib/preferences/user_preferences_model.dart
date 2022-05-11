import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const introductionShownKey = 'INTRODUCTION_SHOWN';
const locationPreferenceKnownKey = 'LOCATION_PREFERENCE_KNOWN';
const locationAccessWantedKey = 'LOCATION_PREFERENCE_WANTED';

class UserPreferences extends ChangeNotifier {

  /// If these settings are initialized.
  bool initialized = false;
  /// The shared preferences storage.
  SharedPreferences? _prefs;

  /// Manages information about the users preferences.
  UserPreferences() {
    _initializeAsync();
  }

  /// Initialize shared preferences access
  void _initializeAsync() async {
    _prefs = await SharedPreferences.getInstance();

    // For Debugging:
    // await prefs.clear();

    initialized = true;
    notifyListeners();
  }

  /// Returns if the introduction should be shown.
  bool? shouldShowIntroduction() {
    if (_prefs == null) {
      return null;
    } else {
      if (!_prefs!.containsKey(introductionShownKey)) {
        return true; // Initial start of the app
      }
      return _prefs?.getBool(introductionShownKey);
    }
  }

  /// Returns if the user's locaiton preference is known.
  bool? get locationPreferenceKnown {
    return _prefs?.getBool(locationPreferenceKnownKey) ?? false;
  }

  /// Returns if the user desires location access.
  bool? get locationAccessWanted {
    return _prefs?.getBool(locationAccessWantedKey);
  }

  /// Updates the location access preference of the user.
  Future<bool> setLocationPreference(bool locationAccessWanted) async {
    _prefs ??= await SharedPreferences.getInstance();
    var success = await _prefs!.setBool(locationPreferenceKnownKey, true);
    if (!success) {
      return Future.value(false);
    } else {
      var result = await _prefs!.setBool(locationAccessWantedKey, locationAccessWanted);
      notifyListeners();
      return result;
    }
    
  }

}
