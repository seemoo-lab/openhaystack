import 'package:flutter/material.dart';
import 'package:openhaystack_mobile/deployment/code_block.dart';
import 'package:openhaystack_mobile/deployment/deployment_details.dart';
import 'package:openhaystack_mobile/deployment/hyperlink.dart';

class DeploymentInstructionsLinux extends StatelessWidget {
  String advertisementKey;

  /// Displays a deployment guide for the generic Linux HCI platform.
  DeploymentInstructionsLinux({
    Key? key,
    this.advertisementKey = '<ADVERTISEMENT_KEY>',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DeploymentDetails(
      title: 'Linux HCI Deployment',
      steps: [
        const Step(
          title: Text('Requirements'),
          content: Text('Install the hcitool software on a Bluetooth '
            'Low Energy Linux device, for example a Raspberry Pi. '
            'Additionally Pyhton 3 needs to be installed.'),
        ),
        Step(
          title: const Text('Download'),
          content: Column(
            children: [
              const Text('Next download the python script that '
                'configures the HCI tool to send out BLE advertisements.'),
              Hyperlink(target: 'https://raw.githubusercontent.com/seemoo-lab/openhaystack/main/Firmware/Linux_HCI/HCI.py'),
              CodeBlock(text: 'curl -o HCI.py https://raw.githubusercontent.com/seemoo-lab/openhaystack/main/Firmware/Linux_HCI/HCI.py'),
            ],
          ),
        ),
        Step(
          title: const Text('Usage'),
          content: Column(
            children: [
              const Text('To start the BLE advertisements run the script.'),
              CodeBlock(text: 'sudo python3 HCI.py --key $advertisementKey'),
            ],
          ),
        ),
      ],
    );
  }
}
