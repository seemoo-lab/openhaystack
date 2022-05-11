import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openhaystack_mobile/accessory/accessory_dto.dart';
import 'package:openhaystack_mobile/accessory/accessory_icon_model.dart';
import 'package:openhaystack_mobile/accessory/accessory_model.dart';
import 'package:openhaystack_mobile/accessory/accessory_registry.dart';
import 'package:openhaystack_mobile/findMy/find_my_controller.dart';
import 'package:openhaystack_mobile/item_management/loading_spinner.dart';

class ItemFileImport extends StatefulWidget {
  /// The path to the file to import from.
  final String filePath;

  /// Lets the user select which accessories to import from a file.
  /// 
  /// Displays the accessories contained in the import file.
  /// The user can then select the accessories to import.
  const ItemFileImport({
    Key? key,
    required this.filePath,
  }) : super(key: key);

  @override
  _ItemFileImportState createState() => _ItemFileImportState();
}

class _ItemFileImportState extends State<ItemFileImport> {
  /// The accessory information stored in the file
  List<AccessoryDTO>? accessories;
  /// Stores which accessories are selected.
  List<bool>? selected;
  /// Stores which accessory details are expanded
  List<bool>? expanded;

  /// Flag if the passed file can not be imported.
  bool hasError = false;
  /// Stores the reason for the error condition.
  String? errorText;

  @override
  void initState() {
    super.initState();

    _initStateAsync(widget.filePath);
  }

  void _initStateAsync(String filePath) async {
    var isValidPath = await _validateFilePath(filePath);

    if (!isValidPath) {
      setState(() {
        hasError = true;
        errorText = 'Invalid file path. Please select another file.';
      });
      
      return;
    }

    // Parse the JSON file and read all contained accessories
    try {
      var accessoryDTOs = await _parseAccessories(filePath);

      setState(() {
        accessories = accessoryDTOs;
        selected = accessoryDTOs.map((_) => true).toList();
        expanded = accessoryDTOs.map((_) => false).toList();
      });
    } catch (e) {
      setState(() {
        hasError = true;
        errorText = 'Could not parse JSON file. Please check if the file is formatted correctly.';
      });
    }
  }

  /// Validate that the file path is a valid path and the file exists.
  Future<bool> _validateFilePath(String filePath) async {
    if (filePath.isEmpty) {
      return false;
    }
    File file = File(filePath);
    var fileExists = await file.exists();

    return fileExists;
  }

  /// Parse the JSON encoded accessories from the file stored at [filePath].
  Future<List<AccessoryDTO>> _parseAccessories(String filePath) async {
    File file = File(filePath);
    String encodedContent = await file.readAsString();

    List<dynamic> content = jsonDecode(encodedContent);
    var accessoryDTOs = content
      .map((json) => AccessoryDTO.fromJson(json))
      .toList();

    return accessoryDTOs;
  }

  /// Import the selected accessories.
  Future<void> _importSelectedAccessories() async {
    if (accessories == null) {
      return; // File not parsed. Do nothing.
    }

    var registry = Provider.of<AccessoryRegistry>(context, listen: false);

    for (var i = 0; i < accessories!.length; i++) {
      var accessoryDTO = accessories![i];
      var shouldImport = selected?[i] ?? false;

      if (shouldImport) {
        await _importAccessory(registry, accessoryDTO);
      }
    }

    var nrOfImports = selected?.fold<int>(0, 
      (previousValue, element) => element ? previousValue + 1 : previousValue) ?? 0;
    if (nrOfImports > 0) {
      var snackbar = SnackBar(
        content: Text('Successfully imported ${nrOfImports.toString()} accessories.'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    }
  }

  /// Import a specific [accessory] by converting the DTO to the internal representation.
  Future<void> _importAccessory(AccessoryRegistry registry, AccessoryDTO accessoryDTO) async {
    Color color = Colors.grey;
    if (accessoryDTO.colorSpaceName == 'kCGColorSpaceSRGB' && accessoryDTO.colorComponents.length == 4) {
      var colors = accessoryDTO.colorComponents;
      int red = (colors[0] * 255).round();
      int green = (colors[1] * 255).round();
      int blue = (colors[2] * 255).round();
      double opacity = colors[3];
      color = Color.fromRGBO(red, green, blue, opacity);
    }

    String icon = 'mappin';
    if (AccessoryIconModel.icons.contains(accessoryDTO.icon)) {
      icon = accessoryDTO.icon;
    }

    var keyPair = await FindMyController.importKeyPair(accessoryDTO.privateKey);

    Accessory newAccessory = Accessory(
      datePublished: DateTime.now(),
      hashedPublicKey: keyPair.hashedPublicKey,
      id: accessoryDTO.id.toString(),
      name: accessoryDTO.name,
      color: color,
      icon: icon,
      isActive: accessoryDTO.isActive,
      isDeployed: accessoryDTO.isDeployed,
      lastLocation: null,
      lastDerivationTimestamp: accessoryDTO.lastDerivationTimestamp,
      symmetricKey: accessoryDTO.symmetricKey,
      updateInterval: accessoryDTO.updateInterval,
      usesDerivation: accessoryDTO.usesDerivation,
      oldestRelevantSymmetricKey: accessoryDTO.oldestRelevantSymmetricKey,
    );

    registry.addAccessory(newAccessory);
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return _buildScaffold(Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'An error occured.',
              style: Theme.of(context).textTheme.headline5,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(errorText ?? 'An unknown error occured. Please try again.'),
            ),
          ],
        ),
      ));
    }

    if (accessories == null) {
      return _buildScaffold(const LoadingSpinner());
    }

    return _buildScaffold(
      SingleChildScrollView(
        child: ExpansionPanelList(
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              expanded?[index] = !isExpanded;
            });
          },
          children: accessories?.asMap().map((idx, accessory) => MapEntry(idx, ExpansionPanel(
            headerBuilder: (BuildContext context, bool isExpanded)
                => ListTile(
                  leading: Checkbox(
                    value: selected?[idx] ?? false,
                    onChanged: (newState) {
                      if (newState != null) {
                        setState(() {
                          selected?[idx] = newState;
                        });
                      }
                    }),
                  title: Text(accessory.name),
                ),
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  children: [
                    _buildProperty('ID', accessory.id.toString()),
                    _buildProperty('Name', accessory.name),
                    _buildProperty('Color', accessory.colorComponents.toString()),
                    _buildProperty('Icon', accessory.icon),
                    _buildProperty('privateKey', accessory.privateKey.replaceRange(
                      4,
                      accessory.privateKey.length - 4,
                      '*'*(accessory.privateKey.length - 8),
                    )),
                    _buildProperty('isActive', accessory.isActive.toString()),
                    _buildProperty('isDeployed', accessory.isDeployed.toString()),
                    _buildProperty('usesDerivation', accessory.usesDerivation.toString()),
                  ],
                ),
              ),
              isExpanded: expanded?[idx] ?? false,
          ))).values.toList() ?? [],
        ),
      ),
    );
  }

  /// Display a key-value property.
  Widget _buildProperty(String key, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$key: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Flexible(child: Text(value)),
      ],
    );
  }

  /// Surround the [body] widget with a [Scaffold] widget.
  Widget _buildScaffold(Widget body) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Accessories'),
        actions: [
          TextButton(
            onPressed: () {
              if (accessories != null) {
                _importSelectedAccessories();
                Navigator.pop(context);
              }
            },
            child: Text(
              'Import',
              style: TextStyle(
                color: accessories == null ? Colors.grey : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}
