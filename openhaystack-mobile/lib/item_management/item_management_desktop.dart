import 'package:flutter/material.dart';
import 'package:openhaystack_mobile/item_management/item_management.dart';
import 'package:openhaystack_mobile/item_management/new_item_action.dart';

class ItemManagementDesktop extends StatefulWidget {

  /// Displays this preferences page with information about the app.
  const ItemManagementDesktop({ Key? key }) : super(key: key);

  @override
  _ItemManagementDesktopState createState() => _ItemManagementDesktopState();
}

class _ItemManagementDesktopState extends State<ItemManagementDesktop> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Management'),
      ),
      body: const KeyManagement(),
      floatingActionButton: const NewKeyAction(),
    );
  }
}
