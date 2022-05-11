import 'package:flutter/material.dart';

class DeploymentDetails extends StatefulWidget {
  /// The steps required to deploy on this target.
  List<Step> steps;
  /// The name of the deployment target.
  String title;

  /// Describes a generic step-by-step deployment for a special hardware target.
  /// 
  /// The actual steps depend on the target platform and are provided in [steps].
  DeploymentDetails({
    Key? key,
    required this.title,
    required this.steps,
  }) : super(key: key);

  @override
  _DeploymentDetailsState createState() => _DeploymentDetailsState();
}

class _DeploymentDetailsState extends State<DeploymentDetails> {
  /// The index of the currently displayed step.
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    var stepCount = widget.steps.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Stepper(
          currentStep: _index,
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            String continueText = _index < stepCount - 1 ? 'CONTINUE' : 'FINISH';
            return Row(
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1))),
                  onPressed: details.onStepContinue,
                  child: Text(continueText),
                ),
                if (_index > 0) TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('BACK'),
                ),
              ],
            );
          },
          onStepCancel: () {
            // Back button clicked
            if (_index == 0) {
              // Cancel deployment and return
              Navigator.pop(context);
            }
            else if (_index > 0) {
              setState(() {
                _index -= 1;
              });
            }
          },
          onStepContinue: () {
            // Continue button clicked
            if (_index == stepCount - 1) {
              // TODO: Mark accessory as deployed
              // Deployment finished
              Navigator.pop(context);
              Navigator.pop(context);
            } else { 
              setState(() {
                _index += 1;
              });
            }
          },
          onStepTapped: (int index) {
            setState(() {
              _index = index;
            });
          },
          steps: widget.steps,
        ),
      ),
    );
  }
}
