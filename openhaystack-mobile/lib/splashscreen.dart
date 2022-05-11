import 'package:flutter/material.dart';

class Splashscreen extends StatelessWidget {

  /// Display a fullscreen splashscreen to cover loading times.
  const Splashscreen({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    Orientation orientation = MediaQuery.of(context).orientation;

    var maxScreen = orientation == Orientation.portrait ? screenSize.width : screenSize.height;
    var maxSize = maxScreen * 0.4;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxSize, maxHeight: maxSize),
          // TODO: Update app icon accordingly (https://docs.flutter.dev/development/ui/assets-and-images#platform-assets)
          child: const Image(
            width: 1800,
            image: AssetImage('assets/OpenHaystackIcon.png')),
        ),
      ),
    );
  }
}
