import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AccessoryColorSelector extends StatelessWidget {

  /// This shows a color selector.
  /// 
  /// The color can be selected via a color field or by inputing explicit
  /// RGB values.
  const AccessoryColorSelector({ Key? key }) : super(key: key);

  /// Displays the color selector with the [initialColor] preselected.
  /// 
  /// The selected color is returned if the user selects the save option.
  /// Otherwise the selection is discarded with a null return value.
  static Future<Color?> showColorSelection(BuildContext context, Color initialColor) async {
    Color currentColor = initialColor;
    return await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              hexInputBar: true,
              pickerColor: currentColor,
              onColorChanged: (Color newColor) {
                currentColor = newColor;
              },
            )
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.pop(context, currentColor);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }

}
