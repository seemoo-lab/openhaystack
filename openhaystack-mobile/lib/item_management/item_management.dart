import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openhaystack_mobile/accessory/accessory_detail.dart';
import 'package:openhaystack_mobile/accessory/accessory_icon.dart';
import 'package:openhaystack_mobile/accessory/no_accessories.dart';
import 'package:openhaystack_mobile/item_management/item_export.dart';
import 'package:openhaystack_mobile/accessory/accessory_registry.dart';
import 'package:intl/intl.dart';

class KeyManagement extends StatelessWidget {

  /// Displays a list of all accessories.
  /// 
  /// Each accessory can be exported and is linked to a detail page.
  const KeyManagement({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessoryRegistry>(
      builder: (context, accessoryRegistry, child) {
        var accessories = accessoryRegistry.accessories;

        if (accessories.isEmpty) {
          return const NoAccessoriesPlaceholder();
        }

        return Scrollbar(
          child: ListView(
            children: accessories.map((accessory) {
              String lastSeen = accessory.datePublished != null
                ? DateFormat('dd.MM.yyyy kk:mm').format(accessory.datePublished!)
                : 'Unknown';
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AccessoryDetail(
                      accessory: accessory,
                    )),
                  );
                },
                dense: true,
                title: Text(accessory.name),
                subtitle: Text('Last seen: ' + lastSeen),
                leading: AccessoryIcon(
                  icon: accessory.icon,
                  color: accessory.color,
                ),
                trailing: ItemExportMenu(accessory: accessory),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
