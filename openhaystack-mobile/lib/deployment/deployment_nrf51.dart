import 'package:flutter/material.dart';
import 'package:openhaystack_mobile/deployment/code_block.dart';
import 'package:openhaystack_mobile/deployment/deployment_details.dart';
import 'package:openhaystack_mobile/deployment/hyperlink.dart';

class DeploymentInstructionsNRF51 extends StatelessWidget {
  String advertisementKey;

  /// Displays a deployment guide for the NRF51 platform.
  DeploymentInstructionsNRF51({
    Key? key,
    this.advertisementKey = '<ADVERTISEMENT_KEY>',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DeploymentDetails(
      title: 'nRF51822 Deployment',
      steps: [
        const Step(
          title: Text('Requirements'),
          content: Text('To build the firmware the GNU Arm Embedded '
            'Toolchain is required.'),
        ),
        Step(
          title: const Text('Download'),
          content: Column(
            children: [
              const Text('Download the firmware source code from GitHub '
                'and navigate to the given folder.'),
              Hyperlink(target: 'https://github.com/seemoo-lab/openhaystack'),
              CodeBlock(text: 'git clone https://github.com/seemoo-lab/openhaystack.git && cd openhaystack/Firmware/Microbit_v1'),
            ],
          ),
        ),
        Step(
          title: const Text('Build'),
          content: Column(
            children: [
              const Text('Replace the public_key in main.c (initially '
                'OFFLINEFINEINGPUBLICKEYHERE!) with the actual '
                'advertisement key. Then execute make to create the '
                'firmware.'),
              CodeBlock(text: 'static char public_key[28] = "$advertisementKey";'),
              CodeBlock(text: 'make'),
            ],
          ),
        ),
        Step(
          title: const Text('Firmware Deployment'),
          content: Column(
            children: [
              const Text('If the firmware is built successfully it can '
                'be deployed to the microcontroller with the following '
                'command.'),
              const Text(
                'Please fill in the volume of your microcontroller.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              CodeBlock(text: 'make install  DEPLOY_PATH=/Volumes/MICROBIT'),
            ],
          ),
        ),
      ],
    );
  }
}
