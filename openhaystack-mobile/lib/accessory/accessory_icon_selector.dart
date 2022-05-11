import 'dart:math';

import 'package:flutter/material.dart';
import 'package:openhaystack_mobile/accessory/accessory_icon_model.dart';

typedef IconChangeListener = void Function(String? newValue);

class AccessoryIconSelector extends StatelessWidget {
  /// The existing icon used previously.
  final String icon;
  /// The existing color used previously.
  final Color color;
  /// A callback being called when the icon changes.
  final IconChangeListener iconChanged;

  /// This show an icon selector.
  /// 
  /// The icon can be selected from a list of available icons.
  /// The icons are handled by the cupertino icon names.
  const AccessoryIconSelector({
    Key? key,
    required this.icon,
    required this.color,
    required this.iconChanged,
  }) : super(key: key);

  /// Displays the icon selector with the [currentIcon] preselected in the [highlighColor].
  /// 
  /// The selected icon as a cupertino icon name is returned if the user selects an icon.
  /// Otherwise the selection is discarded and a null value is returned.
  static Future<String?> showIconSelection(BuildContext context, String currentIcon, Color highlighColor) async {
  return await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return LayoutBuilder(
        builder: (context, constraints) => Dialog(
          child: GridView.count(
            primary: false,
            padding: const EdgeInsets.all(20),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            crossAxisCount: min((constraints.maxWidth / 80).floor(), 8),
            semanticChildCount: AccessoryIconModel.icons.length,
            children: AccessoryIconModel.icons
              .map((value) => IconButton(
                icon: Icon(AccessoryIconModel.mapIcon(value)),
                color: value == currentIcon ? highlighColor : null,
                onPressed: () { Navigator.pop(context, value); },
              )).toList(),
          ),
        ),
      );
    }
  );
}

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 200, 200, 200),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () async {
          String? selectedIcon = await showIconSelection(context, icon, color);
          if (selectedIcon != null) {
            iconChanged(selectedIcon);
          }
        },
        icon: Icon(AccessoryIconModel.mapIcon(icon)),
      ),
    );
  }
}
