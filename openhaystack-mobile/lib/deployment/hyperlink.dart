import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Hyperlink extends StatelessWidget {
  /// The target url to open.
  String target;
  /// The display text of the hyperlink. Default is [target].
  String _text;

  /// Displays a hyperlink that can be opened by a tap.
  Hyperlink({
    Key? key,
    required this.target,
    text,
  }) : _text = text ?? target, super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Text(_text,
        style: const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
      onTap: () {
        launch(target);
      },
    );
  }
}
