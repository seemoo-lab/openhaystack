import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openhaystack_mobile/accessory/accessory_list.dart';
import 'package:openhaystack_mobile/accessory/accessory_registry.dart';
import 'package:openhaystack_mobile/location/location_model.dart';
import 'package:openhaystack_mobile/map/map.dart';
import 'package:openhaystack_mobile/preferences/preferences_page.dart';
import 'package:openhaystack_mobile/preferences/user_preferences_model.dart';

class DashboardDesktop extends StatefulWidget {

  /// Displays the layout for the desktop view of the app.
  /// 
  /// The layout is optimized for horizontally aligned larger screens
  /// on desktop devices.
  const DashboardDesktop({ Key? key }) : super(key: key);

  @override
  _DashboardDesktopState createState() => _DashboardDesktopState();
}

class _DashboardDesktopState extends State<DashboardDesktop> {

  @override
  void initState() {
    super.initState();

    // Initialize models and preferences
    var userPreferences = Provider.of<UserPreferences>(context, listen: false);
    var locationModel = Provider.of<LocationModel>(context, listen: false);
    var locationPreferenceKnown = userPreferences.locationPreferenceKnown ?? false;
    var locationAccessWanted = userPreferences.locationAccessWanted ?? false;
    if (!locationPreferenceKnown || locationAccessWanted) {
      locationModel.requestLocationUpdates();
    }

    loadLocationUpdates();
  }

  /// Fetch locaiton updates for all accessories.
  Future<void> loadLocationUpdates() async {
    var accessoryRegistry = Provider.of<AccessoryRegistry>(context, listen: false);
    await accessoryRegistry.loadLocationReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 400,
            child: Column(
              children: [
                AppBar(
                  title: const Text('OpenHaystack'),
                  leading: IconButton(
                    onPressed: () { /* reload */ },
                    icon: const Icon(Icons.menu),
                  ),
                  actions: <Widget>[
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PreferencesPage()),
                        );
                      },
                      icon: const Icon(Icons.settings),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.all(5),
                  child: Text('My Accessories')
                ),
                Expanded(
                  child: AccessoryList(
                    loadLocationUpdates: loadLocationUpdates,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: AccessoryMap(),
          ),
        ],
      ),
    );
  }

}
