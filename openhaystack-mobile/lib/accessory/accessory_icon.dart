import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AccessoryIcon extends StatelessWidget {
  /// The icon to display.
  final IconData icon;
  /// The color of the surrounding ring.
  final Color color;
  /// The size of the icon.
  final double size;

  /// Displays the icon in a colored ring.
  /// 
  /// The default size can be adjusted by setting the [size] parameter.
  const AccessoryIcon({
    Key? key,
    this.icon = Icons.help,
    this.color = Colors.grey,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(width: size / 6, color: color),
      ),
      child: Padding(
        padding: EdgeInsets.all(size / 12),
        child: Icon(
          icon,
          size: size,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
