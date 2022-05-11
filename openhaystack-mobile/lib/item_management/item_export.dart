import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:openhaystack_mobile/accessory/accessory_dto.dart';
import 'package:openhaystack_mobile/accessory/accessory_model.dart';
import 'package:openhaystack_mobile/accessory/accessory_registry.dart';
import 'package:share_plus/share_plus.dart';

class ItemExportMenu extends StatelessWidget {
  /// The accessory to export from
  Accessory accessory;

  /// Displays a bottom sheet with export options.
  /// 
  /// The accessory can be exported to a JSON file or the 
  /// key parameters can be exported separately.
  ItemExportMenu({
    Key? key,
    required this.accessory,
  }) : super(key: key);

  /// Shows the export options for the [accessory].
  void showKeyExportSheet(BuildContext context, Accessory accessory) {
    showModalBottomSheet(context: context, builder: (BuildContext context) {
      return SafeArea(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [
            ListTile(
              trailing: IconButton(
                onPressed: () {
                  _showKeyExplanationAlert(context);
                },
                icon: const Icon(Icons.info),
              ),
            ),
            ListTile(
              title: const Text('Export All Accessories (JSON)'),
              onTap: () async {
                var accessories = Provider.of<AccessoryRegistry>(context, listen: false).accessories;
                await _exportAccessoriesAsJSON(accessories);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Export Accessory (JSON)'),
              onTap: () async {
                await _exportAccessoriesAsJSON([accessory]);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Export Hashed Advertisement Key (Base64)'),
              onTap: () async {
                var advertisementKey = await accessory.getHashedAdvertisementKey();
                Share.share(advertisementKey);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Export Advertisement Key (Base64)'),
              onTap: () async {
                var advertisementKey = await accessory.getAdvertisementKey();
                Share.share(advertisementKey);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Export Private Key (Base64)'),
              onTap: () async {
                var privateKey = await accessory.getPrivateKey();
                Share.share(privateKey);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    });
  }

  /// Export the serialized [accessories] as a JSON file.
  /// 
  /// The OpenHaystack export format is used for interoperability with
  /// the desktop app.
  Future<void> _exportAccessoriesAsJSON(List<Accessory> accessories) async {
    // Create temporary directory to store export file
    Directory tempDir = await getTemporaryDirectory();
    String path = tempDir.path;
    // Convert accessories to export format
    List<AccessoryDTO> exportAccessories = [];
    for (Accessory accessory in accessories) {
      String privateKey = await accessory.getPrivateKey();
      exportAccessories.add(AccessoryDTO(
        id: int.tryParse(accessory.id) ?? 0,
        colorComponents: [
          accessory.color.red / 255,
          accessory.color.green / 255,
          accessory.color.blue / 255,
          accessory.color.opacity,
        ],
        name: accessory.name,
        lastDerivationTimestamp: accessory.lastDerivationTimestamp,
        symmetricKey: accessory.symmetricKey,
        updateInterval: accessory.updateInterval,
        privateKey: privateKey,
        icon: accessory.rawIcon,
        isDeployed: accessory.isDeployed,
        colorSpaceName: 'kCGColorSpaceSRGB',
        usesDerivation: accessory.usesDerivation,
        oldestRelevantSymmetricKey: accessory.oldestRelevantSymmetricKey,
        isActive: accessory.isActive,
      ));
    }
    // Create file and write accessories as json
    const filename = 'accessories.json';
    File file = File('$path/$filename');
    JsonEncoder encoder = const JsonEncoder.withIndent('  '); // format output
    String encodedAccessories = encoder.convert(exportAccessories);
    await file.writeAsString(encodedAccessories);
    // Share export file over os share dialog
    Share.shareFiles(
      [file.path],
      mimeTypes: ['application/json'],
      subject: filename,
    );
  }

  /// Show an explanation how the different key types are used.
  Future<void> _showKeyExplanationAlert(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Key Overview'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Private Key:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Secret key used for location report decryption.'),
                Text('Advertisement Key:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Shortened public key sent out over Bluetooth.'),
                Text('Hashed Advertisement Key:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Used to retrieve location reports from the server'),
                Text('Accessory:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('A file containing all information about the accessory.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showKeyExportSheet(context, accessory);
      },
      icon: const Icon(Icons.open_in_new),
    );
  }
}
