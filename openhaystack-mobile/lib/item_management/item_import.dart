import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openhaystack_mobile/accessory/accessory_model.dart';
import 'package:openhaystack_mobile/accessory/accessory_registry.dart';
import 'package:openhaystack_mobile/findMy/find_my_controller.dart';
import 'package:openhaystack_mobile/item_management/accessory_color_input.dart';
import 'package:openhaystack_mobile/item_management/accessory_icon_input.dart';
import 'package:openhaystack_mobile/item_management/accessory_id_input.dart';
import 'package:openhaystack_mobile/item_management/accessory_name_input.dart';
import 'package:openhaystack_mobile/item_management/accessory_pk_input.dart';

class AccessoryImport extends StatefulWidget {

  /// Displays an input form to manually import an accessory.
  const AccessoryImport({Key? key}) : super(key: key);

  @override
  State<AccessoryImport> createState() => _AccessoryImportState();
}

class _AccessoryImportState extends State<AccessoryImport> {

  /// Stores the properties of the accessory to import.
  Accessory newAccessory = Accessory(
    id: '',
    name: '',
    hashedPublicKey: '',
    datePublished: DateTime.now(),
  );
  String privateKey = '';

  final _formKey = GlobalKey<FormState>();

  /// Imports the private key to the key store.
  Future<void> importKey(BuildContext context) async {
    if (_formKey.currentState != null) {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
        try {
          var keyPair = await FindMyController.importKeyPair(privateKey);
          newAccessory.hashedPublicKey = keyPair.hashedPublicKey;
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Key import failed. Check if private key is correct.'),
            ),
          );
        }
        var keyPair = await FindMyController.importKeyPair(privateKey);
        newAccessory.hashedPublicKey = keyPair.hashedPublicKey;
        AccessoryRegistry accessoryRegistry = Provider.of<AccessoryRegistry>(context, listen: false);
        accessoryRegistry.addAccessory(newAccessory);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Accessory'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const ListTile(
                title: Text('Please enter the accessory parameters. They can be found in the exported accessory file.'),
              ),
              AccessoryIdInput(
                changeListener: (id) => setState(() {
                  newAccessory.id = id!;
                }),
              ),
              AccessoryNameInput(
                onSaved: (name) => setState(() {
                  newAccessory.name = name!;
                }),
              ),
              AccessoryIconInput(
                initialIcon: newAccessory.icon,
                iconString: newAccessory.rawIcon,
                color: newAccessory.color,
                changeListener: (String? selectedIcon) {
                  if (selectedIcon != null) {
                    setState(() {
                      newAccessory.setIcon(selectedIcon);
                    });
                  }
                },
              ),
              AccessoryColorInput(
                color: newAccessory.color,
                changeListener: (Color? selectedColor) {
                  if (selectedColor != null) {
                    setState(() {
                      newAccessory.color = selectedColor;
                    });
                  }
                },
              ),
              AccessoryPrivateKeyInput(
                changeListener: (String? privateKeyVal) async {
                  if (privateKeyVal != null) {
                    setState(() {
                      privateKey = privateKeyVal;
                    });
                  }
                },
              ),
              SwitchListTile(
                value: newAccessory.isActive,
                title: const Text('Is Active'),
                onChanged: (checked) {
                  setState(() {
                    newAccessory.isActive = checked;
                  });
                },
              ),
              SwitchListTile(
                value: newAccessory.isDeployed,
                title: const Text('Is Deployed'),
                onChanged: (checked) {
                  setState(() {
                    newAccessory.isDeployed = checked;
                  });
                },
              ),
              ListTile(
                title: ElevatedButton(
                  child: const Text('Import'),
                  onPressed: () => importKey(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
