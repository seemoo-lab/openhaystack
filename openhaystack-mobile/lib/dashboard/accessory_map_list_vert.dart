import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:provider/provider.dart';
import 'package:openhaystack_mobile/accessory/accessory_list.dart';
import 'package:openhaystack_mobile/accessory/accessory_registry.dart';
import 'package:openhaystack_mobile/location/location_model.dart';
import 'package:openhaystack_mobile/map/map.dart';
import 'package:latlong2/latlong.dart';

class AccessoryMapListVertical extends StatefulWidget {
  final AsyncCallback loadLocationUpdates;

  /// Displays a map view and the accessory list in a vertical alignment.
  const AccessoryMapListVertical({
    Key? key,
    required this.loadLocationUpdates,
  }) : super(key: key);

  @override
  State<AccessoryMapListVertical> createState() => _AccessoryMapListVerticalState();
}

class _AccessoryMapListVerticalState extends State<AccessoryMapListVertical> {
  final MapController _mapController = MapController();

  void _centerPoint(LatLng point) {
    _mapController.fitBounds(
      LatLngBounds(point),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer2<AccessoryRegistry, LocationModel>(
      builder: (BuildContext context, AccessoryRegistry accessoryRegistry, LocationModel locationModel, Widget? child) {
        return Column(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: AccessoryMap(
                mapController: _mapController,
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: AccessoryList(
                loadLocationUpdates: widget.loadLocationUpdates,
                centerOnPoint: _centerPoint,
              ),
            ),
          ],
        );
      },
    );
  }
}
