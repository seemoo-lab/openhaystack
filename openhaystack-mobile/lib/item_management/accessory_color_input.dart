import 'package:flutter/material.dart';
import 'package:openhaystack_mobile/accessory/accessory_color_selector.dart';

class AccessoryColorInput extends StatelessWidget {
  /// The inititial color value
  Color color;
  /// Callback called when the color is changed. Parameter is null
  /// if color did not change
  ValueChanged<Color?> changeListener;

  /// Displays a color selection input that previews the current selection.
  AccessoryColorInput({
    Key? key,
    required this.color,
    required this.changeListener,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          const Text('Color: '),
          Icon(
            Icons.circle,
            color: color,
          ),
          const Spacer(),
          OutlinedButton(
            child: const Text('Change'),
            onPressed: () async {
              Color? selectedColor = await AccessoryColorSelector
                .showColorSelection(context, color);
              changeListener(selectedColor);
            },
          ),
        ],
      ),
    );
  }
}
