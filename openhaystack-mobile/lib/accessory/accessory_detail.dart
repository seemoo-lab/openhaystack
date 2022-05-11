import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openhaystack_mobile/accessory/accessory_color_selector.dart';
import 'package:openhaystack_mobile/accessory/accessory_icon.dart';
import 'package:openhaystack_mobile/accessory/accessory_icon_selector.dart';
import 'package:openhaystack_mobile/accessory/accessory_model.dart';
import 'package:openhaystack_mobile/accessory/accessory_registry.dart';
import 'package:openhaystack_mobile/item_management/accessory_name_input.dart';

class AccessoryDetail extends StatefulWidget {
  Accessory accessory;

  /// A page displaying the editable information of a specific [accessory].
  /// 
  /// This shows the editable information of a specific [accessory] and
  /// allows the user to edit them.
  AccessoryDetail({
    Key? key,
    required this.accessory,
  }) : super(key: key);

  @override
  _AccessoryDetailState createState() => _AccessoryDetailState();
}

class _AccessoryDetailState extends State<AccessoryDetail> {
  // An accessory storing the changed values.
  late Accessory newAccessory;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // Initialize changed accessory with existing accessory properties.
    newAccessory = widget.accessory.clone();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accessory.name),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: AccessoryIcon(
                        size: 100,
                        icon: newAccessory.icon,
                        color: newAccessory.color,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 200, 200, 200),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () async {
                              // Show icon selection
                              String? selectedIcon = await AccessoryIconSelector
                                .showIconSelection(context, newAccessory.rawIcon, newAccessory.color);
                              if (selectedIcon != null) {
                                setState(() {
                                  newAccessory.setIcon(selectedIcon);
                                });

                                // Show color selection only when icon is selected
                                Color? selectedColor = await AccessoryColorSelector
                                  .showColorSelection(context, newAccessory.color);
                                if (selectedColor != null) {
                                  setState(() {
                                    newAccessory.color = selectedColor;
                                  });
                                }
                              }
                            },
                            icon: const Icon(Icons.edit),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AccessoryNameInput(
                initialValue: newAccessory.name,
                onChanged: (value) {
                  setState(() {
                    newAccessory.name = value;
                  });
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
                title: OutlinedButton(
                  child: const Text('Save'),
                  onPressed: _formKey.currentState == null || !_formKey.currentState!.validate()
                    ? null : () {
                    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                      // Update accessory with changed values
                      var accessoryRegistry = Provider.of<AccessoryRegistry>(context, listen: false);
                      accessoryRegistry.editAccessory(widget.accessory, newAccessory);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Changes saved!'),
                        ),
                      );
                    }
                  },
                ),
              ),
              ListTile(
                title: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        return Theme.of(context).errorColor;
                      },
                    ),
                  ),
                  child: const Text('Delete Accessory', style: TextStyle(color: Colors.white),),
                  onPressed: () {
                    // Delete accessory
                    var accessoryRegistry = Provider.of<AccessoryRegistry>(context, listen: false);
                    accessoryRegistry.removeAccessory(widget.accessory);
                    Navigator.pop(context);
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
