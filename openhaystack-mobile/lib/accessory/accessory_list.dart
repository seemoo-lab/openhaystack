import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:openhaystack_mobile/accessory/accessory_list_item.dart';
import 'package:openhaystack_mobile/accessory/accessory_list_item_placeholder.dart';
import 'package:openhaystack_mobile/accessory/accessory_registry.dart';
import 'package:openhaystack_mobile/accessory/no_accessories.dart';
import 'package:openhaystack_mobile/history/accessory_history.dart';
import 'package:openhaystack_mobile/location/location_model.dart';

class AccessoryList extends StatefulWidget {
  final AsyncCallback loadLocationUpdates;
  final void Function(LatLng point)? centerOnPoint;

  /// Display a location overview all accessories in a concise list form.
  /// 
  /// For each accessory the name and last known locaiton information is shown.
  /// Uses the accessories in the [AccessoryRegistry].
  const AccessoryList({
    Key? key,
    required this.loadLocationUpdates,
    this.centerOnPoint,
  }): super(key: key);

  @override
  _AccessoryListState createState() => _AccessoryListState();
}

class _AccessoryListState extends State<AccessoryList> {

  @override
  Widget build(BuildContext context) {
    return Consumer2<AccessoryRegistry, LocationModel>(
      builder: (context, accessoryRegistry, locationModel, child) {
        var accessories = accessoryRegistry.accessories;

        // Show placeholder while accessories are loading
        if (accessoryRegistry.loading){
          return LayoutBuilder(
            builder: (context, constraints) {
              // Show as many accessory placeholder fitting into the vertical space.
              // Minimum one, maximum 6 placeholders
              var nrOfEntries = min(max((constraints.maxHeight / 64).floor(), 1), 6);
              List<Widget> placeholderList = [];
              for (int i = 0; i < nrOfEntries; i++) {
                placeholderList.add(const AccessoryListItemPlaceholder());
              }
              return Scrollbar(
                child: ListView(
                  children: placeholderList,
                ),
              );
            }
          );
        }

        if (accessories.isEmpty) {
          return const NoAccessoriesPlaceholder();
        }

        // TODO: Refresh Indicator for desktop
        // Use pull to refresh method
        return SlidableAutoCloseBehavior(child:
          RefreshIndicator(
            onRefresh: widget.loadLocationUpdates,
            child: Scrollbar(
              child: ListView(
                children: accessories.map((accessory) {
                  // Calculate distance from users devices location
                  Widget? trailing;
                  if (locationModel.here != null && accessory.lastLocation != null) {
                    const Distance distance = Distance();
                    final double km = distance.as(LengthUnit.Kilometer, locationModel.here!, accessory.lastLocation!);
                    trailing = Text(km.toString() + 'km');
                  }
                  // Get human readable location
                  return Slidable(
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        if (accessory.isDeployed) SlidableAction(
                          onPressed: (context) async {
                            if (accessory.lastLocation != null && accessory.isDeployed) {
                              var loc = accessory.lastLocation!;
                              await MapsLauncher.launchCoordinates(
                                loc.latitude, loc.longitude, accessory.name);
                            }
                          },
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          icon: Icons.directions,
                          label: 'Navigate',
                        ),
                        if (accessory.isDeployed) SlidableAction(
                          onPressed: (context) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AccessoryHistory(
                                accessory: accessory,
                              )),
                            );
                          },
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          icon: Icons.history,
                          label: 'History',
                        ),
                        if (!accessory.isDeployed) SlidableAction(
                          onPressed: (context) {
                            var accessoryRegistry = Provider.of<AccessoryRegistry>(context, listen: false);
                            var newAccessory = accessory.clone();
                            newAccessory.isDeployed = true;
                            accessoryRegistry.editAccessory(accessory, newAccessory);
                          },
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          icon: Icons.upload_file,
                          label: 'Deploy',
                        ),
                      ],
                    ),
                    child: Builder(
                      builder: (context) {
                        return AccessoryListItem(
                          accessory: accessory,
                          distance: trailing,
                          herePlace: locationModel.herePlace,
                          onTap: () {
                            var lastLocation = accessory.lastLocation;
                            if (lastLocation != null) {
                              widget.centerOnPoint?.call(lastLocation);
                            }
                          },
                          onLongPress: Slidable.of(context)?.openEndActionPane,
                        );
                      }
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
