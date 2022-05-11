import 'package:flutter/material.dart';

class DaysSelectionSlider extends StatefulWidget {

  /// The number of days currently selected.
  double numberOfDays;
  /// A callback listening for value changes.
  ValueChanged<double> onChanged;

  /// Display a slider that allows to define how many days to go back
  /// (range 1 to 7).
  DaysSelectionSlider({
    Key? key,
    required this.numberOfDays,
    required this.onChanged,
  }) : super(key: key);

  @override
  _DaysSelectionSliderState createState() => _DaysSelectionSliderState();
}

class _DaysSelectionSliderState extends State<DaysSelectionSlider> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          const Center(
            child: Text(
              'How many days back?',
              style: TextStyle(fontSize: 20),
            ),
          ),
          Row(
            children: [
              const Text('1', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: widget.numberOfDays,
                  min: 1,
                  max: 7,
                  label: '${widget.numberOfDays.round()}',
                  divisions: 6,
                  onChanged: widget.onChanged,
                ),
              ),
              const Text('7', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

}
