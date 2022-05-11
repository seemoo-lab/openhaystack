import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:openhaystack_mobile/accessory/accessory_icon.dart';
import 'package:openhaystack_mobile/accessory/accessory_model.dart';
import 'package:intl/intl.dart';

class AccessoryListItem extends StatelessWidget {
  /// The accessory to display the information for.
  final Accessory accessory;
  /// A trailing distance information widget.
  final Widget? distance;
  /// Address information about the accessories location.
  final Placemark? herePlace;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Displays the location of an accessory as a concise list item.
  /// 
  /// Shows the icon and name of the accessory, as well as the current
  /// location and distance to the user's location (if known; `distance != null`)
  const AccessoryListItem({
    Key? key,
    required this.accessory,
    required this.onTap,
    this.onLongPress,
    this.distance,
    this.herePlace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Placemark?>(
      future: accessory.place,
      builder: (BuildContext context, AsyncSnapshot<Placemark?> snapshot) {
        // Format the location of the accessory. Use in this order:
        //   * Address if known
        //   * Coordinates (latitude & longitude) if known
        //   * `Unknown` if unknown
        String locationString = accessory.lastLocation != null
          ? '${accessory.lastLocation!.latitude}, ${accessory.lastLocation!.longitude}'
          : 'Unknown';
        if (snapshot.hasData && snapshot.data != null) {
          Placemark place = snapshot.data!;
          locationString = '${place.locality}, ${place.administrativeArea}';
          if (herePlace != null && herePlace!.country != place.country) {
            locationString = '${place.locality}, ${place.country}';
          }
        }
        // Format published date in a human readable way
        String? dateString = accessory.datePublished != null
          ? ' · ${DateFormat('dd.MM.yyyy kk:mm').format(accessory.datePublished!)}'
          : '';
        return ListTile(
          onTap: onTap,
          onLongPress: onLongPress,
          title: Text(
            accessory.name + (accessory.isDeployed ? '' : ' (not deployed)'),
            style: TextStyle(
              color: accessory.isDeployed
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).disabledColor,
            ),
          ),
          subtitle: Text(locationString + dateString),
          trailing: distance,
          dense: true,
          leading: AccessoryIcon(
            icon: accessory.icon,
            color: accessory.color,
          ),
        );
      },
    );
  }
}
