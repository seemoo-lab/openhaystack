import 'package:flutter/material.dart';

class TextPlaceholder extends StatefulWidget {
  final double maxWidth;
  final double? width;
  final double? height;
  final bool animated;

  /// Displays a placeholder for the actual text, occupying the same layout space.
  /// 
  /// An optional loading animation is provided.
  const TextPlaceholder({
    Key? key,
    this.maxWidth = double.infinity,
    this.width,
    this.height = 10,
    this.animated = true,
  }) : super(key: key);

  @override
  _TextPlaceholderState createState() => _TextPlaceholderState();
}

class _TextPlaceholderState extends State<TextPlaceholder> with SingleTickerProviderStateMixin{
  late Animation<double> animation;
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    animation = Tween<double>(begin: 0, end: 1).animate(controller)
      ..addListener(() {
        setState(() {}); // Trigger UI update with current value
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          controller.forward();
        }
      });

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        gradient: widget.animated ? LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0.0, animation.value, 1.0],
          colors: const [Color.fromARGB(255, 200, 200, 200), Color.fromARGB(255, 230, 230, 230), Color.fromARGB(255, 200, 200, 200)],
        ): null,
        color: widget.animated ? null : const Color.fromARGB(255, 200, 200, 200),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
    );
  }
}
