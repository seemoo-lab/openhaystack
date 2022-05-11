import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openhaystack_mobile/location/location_model.dart';
import 'package:openhaystack_mobile/preferences/user_preferences_model.dart';

class PreferencesPage extends StatefulWidget {

  /// Displays this preferences page with information about the app.
  const PreferencesPage({ Key? key }) : super(key: key);

  @override
  _PreferencesPageState createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<UserPreferences>(
        builder: (BuildContext context, UserPreferences prefs, Widget? child) {
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: ListView(
                children: [
                  SwitchListTile(
                    title: const Text('Show this devices location'),
                    value: !prefs.locationPreferenceKnown! || (prefs.locationAccessWanted ?? true),
                    onChanged: (showLocation) {
                      prefs.setLocationPreference(showLocation);
                      var locationModel = Provider.of<LocationModel>(context, listen: false);
                      if (showLocation) {
                        locationModel.requestLocationUpdates();
                      } else {
                        locationModel.cancelLocationUpdates();
                      }
                    },
                  ),
                  ListTile(
                    title: TextButton(
                      child: const Text('About'),
                      onPressed: () => showAboutDialog(
                        context: context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
