import 'package:flutter/material.dart';

class AccessoryNameInput extends StatelessWidget {
  ValueChanged<String?>? onSaved;
  ValueChanged<String>? onChanged;
  /// The initial accessory name
  String? initialValue;

  /// Displays an input field with validation for an accessory name.
  AccessoryNameInput({
    Key? key,
    this.onSaved,
    this.initialValue,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: TextFormField(
        decoration: const InputDecoration(
          labelText: 'Name',
        ),
        validator: (value) {
          if (value == null) {
            return 'Name must be provided.';
          }
          if (value.isEmpty || value.length > 30) {
            return 'Name must be a non empty string of max length 30.';
          }
          return null;
        },
        onSaved: onSaved,
        onChanged: onChanged,
        initialValue: initialValue,
      ),
    );
  }
}
