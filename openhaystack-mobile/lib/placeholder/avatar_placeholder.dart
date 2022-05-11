import 'package:flutter/material.dart';

class AvatarPlaceholder extends StatelessWidget {
  final double size;

  /// Displays a placeholder for the actual avatar, occupying the same layout space.
  const AvatarPlaceholder({
    Key? key,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 3 / 2,
      height: size * 3 / 2,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 200, 200, 200),
        shape: BoxShape.circle,
      ),
    );
  }
}
