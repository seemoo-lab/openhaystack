import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openhaystack_mobile/accessory/accessory_model.dart';
import 'package:openhaystack_mobile/accessory/accessory_registry.dart';
import 'package:openhaystack_mobile/findMy/find_my_controller.dart';
import 'package:openhaystack_mobile/item_management/accessory_color_input.dart';
import 'package:openhaystack_mobile/item_management/accessory_icon_input.dart';
import 'package:openhaystack_mobile/item_management/accessory_name_input.dart';
import 'package:openhaystack_mobile/deployment/deployment_instructions.dart';

class AccessoryGeneration extends StatefulWidget {

  /// Displays a page to create a new accessory.
  /// 
  /// The parameters of the new accessory can be input in text fields.
  const AccessoryGeneration({ Key? key }) : super(key: key);

  @override
  _AccessoryGenerationState createState() => _AccessoryGenerationState();
}

class _AccessoryGenerationState extends State<AccessoryGeneration> {

  /// Stores the properties of the new accessory.
  Accessory newAccessory = Accessory(
    id: '',
    name: '',
    hashedPublicKey: '',
    datePublished: DateTime.now(),
  );

  /// Stores the advertisement key of the newly created accessory.
  String? advertisementKey;

  final _formKey = GlobalKey<FormState>();

  /// Creates a new accessory with a new key pair.
  Future<bool> createAccessory(BuildContext context) async {
    if (_formKey.currentState != null) {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        var keyPair = await FindMyController.generateKeyPair();
        advertisementKey = keyPair.getBase64AdvertisementKey();
        newAccessory.hashedPublicKey = keyPair.hashedPublicKey;
        AccessoryRegistry accessoryRegistry = Provider.of<AccessoryRegistry>(context, listen: false);
        accessoryRegistry.addAccessory(newAccessory);
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create new Accessory'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
              const ListTile(
                title: Text('A secure key pair will be generated for you automatically.'),
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
                title: OutlinedButton(
                  child: const Text('Create only'),
                  onPressed: () async {
                    var created = await createAccessory(context);
                    if (created) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              ListTile(
                title: ElevatedButton(
                  child: const Text('Create and Deploy'),
                  onPressed: () async {
                    var created = await createAccessory(context);
                    if (created) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => DeploymentInstructions(
                          advertisementKey: advertisementKey ?? '<ADVERTISEMENT_KEY>',
                        )),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
