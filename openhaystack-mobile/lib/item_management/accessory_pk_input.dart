import 'dart:convert';

import 'package:flutter/material.dart';

class AccessoryPrivateKeyInput extends StatelessWidget {
  ValueChanged<String?> changeListener;

  /// Displays an input field with validation for a Base64 encoded accessory private key.
  AccessoryPrivateKeyInput({
    Key? key,
    required this.changeListener,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: TextFormField(
        decoration: const InputDecoration(
          hintText: 'SGVsbG8gV29ybGQhCg==',
          labelText: 'Private Key (Base64)',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Private key must be provided.';
          }
          try {
            var removeEscaping = value
              .replaceAll('\\', '').replaceAll('\n', '');
            base64Decode(removeEscaping);
          } catch (e) {
            return 'Value must be valid base64 key.';
          }
          return null;
        },
        onSaved: (newValue) =>
          changeListener(newValue?.replaceAll('\\', '').replaceAll('\n', '')),
      ),
    );
  }
}
