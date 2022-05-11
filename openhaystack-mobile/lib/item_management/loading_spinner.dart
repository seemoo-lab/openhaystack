import 'package:flutter/material.dart';

class LoadingSpinner extends StatelessWidget {

  /// Displays a centered loading spinner.
  const LoadingSpinner({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Padding(
        padding: const EdgeInsets.only(top: 20),
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
          semanticsLabel: 'Loading. Please wait.',
        ),
      )],
    );
  }
}
