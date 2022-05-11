import 'package:flutter/material.dart';

class AccessoryIdInput extends StatelessWidget {
  ValueChanged<String?> changeListener;

  /// Displays an input field with validation for an accessory ID.
  AccessoryIdInput({
    Key? key,
    required this.changeListener,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: TextFormField(
        decoration: const InputDecoration(
          labelText: 'ID',
        ),
        validator: (value) {
          if (value == null) {
            return 'ID must be provided.';
          }
          int? parsed = int.tryParse(value);
          if (parsed == null) {
            return 'ID must be an integer value.';
          }
          return null;
        },
        onSaved: changeListener,
      ),
    );
  }
}
