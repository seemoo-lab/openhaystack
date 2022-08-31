import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:openhaystack_mobile/accessory/accessory_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:openhaystack_mobile/history/days_selection_slider.dart';
import 'package:openhaystack_mobile/history/location_popup.dart';

class AccessoryHistory extends StatefulWidget {
  Accessory accessory;

  /// Shows previous locations of a specific [accessory] on a map.
  /// The locations are connected by a chronological line.
  /// The number of days to go back can be adjusted with a slider.
  AccessoryHistory({
    Key? key,
    required this.accessory,
  }) : super(key: key);

  @override
  _AccessoryHistoryState createState() => _AccessoryHistoryState();
}

class _AccessoryHistoryState extends State<AccessoryHistory> {

  final MapController _mapController = MapController();
  final ScrollController _scrollController = new ScrollController();

  bool showPopup = false;
  Pair<LatLng, DateTime>? popupEntry;

  double numberOfDays = 7;
  int scrolledMarker = -1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        var old = scrolledMarker;
        scrolledMarker = _scrollController.offset.toInt() ~/ 24;
        if (old != scrolledMarker) {
          _mapController.move(widget.accessory.locationHistory.elementAt(scrolledMarker).a, _mapController.zoom);
        }
      });
    });
    _mapController.onReady
      .then((_) {
        var historicLocations = widget.accessory.locationHistory
          .map((entry) => entry.a).toList();
        var bounds = LatLngBounds.fromPoints(historicLocations);
        _mapController.fitBounds(bounds);
      });
  }

  List<Marker> buildMarkers() {
    List<Marker> toRet = [];
    var length = widget.accessory.locationHistory.length;
    for (int i=1; i< length-1; i++) {
      toRet.add(buildMarker(i));
    }
    if (length > 0) {
      toRet.add(buildMarker(0));
    }
    if (length > 1) {
      toRet.add(buildMarker(length-1));
    }
    return toRet;
  }

  Marker buildMarker(int index) {
    var entry = widget.accessory.locationHistory.elementAt(index);
    return Marker(
      point: entry.a,

      builder: (ctx) => GestureDetector(
        onTap: () {
          setState(() {
            showPopup = true;
            popupEntry = entry;
          });
        },
        child: Icon(
          Icons.circle,
          size: (widget.accessory.locationHistory.first == entry || widget.accessory.locationHistory.last == entry) ? 20: 10,
          color: (() {
            if (widget.accessory.locationHistory.first == entry) {
              return Colors.amber;
            }
            if (widget.accessory.locationHistory.last == entry) {
              return Colors.green;
            }
            if (index == scrolledMarker) {
              return Colors.pink;
            }
            if (entry == popupEntry) {
              return Colors.red;
            }
            return Theme.of(context).indicatorColor;
          })().withOpacity(0.9),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    // Filter for the locations after the specified cutoff date (now - number of days)
    var now = DateTime.now();
    List<Pair<LatLng, DateTime>> locationHistory = widget.accessory.locationHistory
      .where(
        (element) => element.b.isAfter(
          now.subtract(Duration(days: numberOfDays.round())),
        ),
      ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accessory.name),
      ),
      body: SafeArea(
        child: Scrollbar(
          child: Column(
            children: <Widget>[
              Flexible(
                flex: 3,
                fit: FlexFit.tight,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: LatLng(49.874739, 8.656280),
                    zoom: 13.0,
                    maxZoom: 18.25,
                    interactiveFlags:
                      InteractiveFlag.pinchZoom | InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom | InteractiveFlag.flingAnimation |
                      InteractiveFlag.pinchMove,
                    onTap: (_, __) {
                      setState(() {
                        showPopup = false;
                        popupEntry = null;
                      });
                    },
                  ),
                  layers: [
                    TileLayerOptions(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      tileBuilder: (context, child, tile) {
                        var isDark = (Theme.of(context).brightness == Brightness.dark);
                        return isDark ? ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            -1, 0, 0, 0, 255,
                            0, -1, 0, 0, 255,
                            0, 0, -1, 0, 255,
                            0, 0, 0, 1, 0,
                          ]),
                          child: child,
                        ) : child;
                      },
                      // urlTemplate: "https://mt0.google.com/vt/lyrs=m@221097413&x={x}&y={y}&z={z}",
                      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                      attributionBuilder: (_) {
                        return const Text("© OpenStreetMap contributors");
                      },
                    ),
                    // The line connecting the locations chronologically
                    PolylineLayerOptions(
                      polylines: [
                        Polyline(
                          points: locationHistory.map((entry) => entry.a).toList(),
                          strokeWidth: 4,
                          color: Theme.of(context).colorScheme.primaryVariant,
                          isDotted: true
                        ),
                      ],
                    ),
                    // The markers for the historic locaitons
                    MarkerLayerOptions(
                      markers: buildMarkers(),
                    ),
                    // Displays the tooltip if active
                    MarkerLayerOptions(
                      markers: [
                        if (showPopup) LocationPopup(
                          location: popupEntry!.a,
                          time: popupEntry!.b,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: DaysSelectionSlider(
                  numberOfDays: numberOfDays,
                  onChanged: (double newValue) {
                    setState(() {
                      numberOfDays = newValue;
                    });
                  },
                ),
              ),
              Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8.0),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(top:12),
                      controller: _scrollController,
                      scrollDirection: Axis.vertical,
                      children: locationHistory.map((l) => SizedBox(height: 24, child: Text(l.b.toString()))).toList(),
                    ),
                  ),
                )
              )
            ],
          ),
        ),
      ),
    );
  }
}
