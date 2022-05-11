import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:openhaystack_mobile/item_management/item_creation.dart';
import 'package:openhaystack_mobile/item_management/item_file_import.dart';
import 'package:openhaystack_mobile/item_management/item_import.dart';

class NewKeyAction extends StatelessWidget {
  /// If the action button is small.
  final bool mini;

  /// Displays a floating button used to access the accessory creation menu.
  /// 
  /// A new accessory can be created or an existing one imported manually.
  const NewKeyAction({
    Key? key,
    this.mini = false,
  }) : super(key: key);

  /// Display a bottom sheet with creation options.
  void showCreationSheet(BuildContext context) {
    showModalBottomSheet(context: context, builder: (BuildContext context) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Import Accessory'),
              leading: const Icon(Icons.import_export),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AccessoryImport()),
                );
              },
            ),
            ListTile(
              title: const Text('Import from JSON File'),
              leading: const Icon(Icons.description),
              onTap: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  allowMultiple: false,
                  type: FileType.custom,
                  allowedExtensions: ['json'],
                  dialogTitle: 'Select accessory configuration',
                );

                if (result != null && result.paths.isNotEmpty) {
                  // File selected, dialog not canceled
                  String? filePath = result.paths[0];

                  if (filePath != null) {
                    Navigator.pushReplacement(context, MaterialPageRoute(
                      builder: (context) => ItemFileImport(filePath: filePath),
                    ));
                  }
                }
              },
            ),
            ListTile(
              title: const Text('Create new Accessory'),
              leading: const Icon(Icons.add_box),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AccessoryGeneration()),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: mini,
      onPressed: () {
        showCreationSheet(context);
      },
      tooltip: 'Create',
      child: const Icon(Icons.add),
    );
  }
}
