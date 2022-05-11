import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:openhaystack_mobile/deployment/deployment_email.dart';
import 'package:openhaystack_mobile/deployment/deployment_esp32.dart';
import 'package:openhaystack_mobile/deployment/deployment_linux_hci.dart';
import 'package:openhaystack_mobile/deployment/deployment_nrf51.dart';
import 'package:openhaystack_mobile/deployment/hyperlink.dart';
import 'package:url_launcher/url_launcher.dart';

class DeploymentInstructions extends StatefulWidget {
  String advertisementKey;

  /// Displays deployment instructions for an already created accessory.
  ///
  /// Provides general information about the created accessory and deployment.
  /// Deployment guides for special hardware can be accessed separately.
  ///
  /// The deployment instructions are customized with the [advertisementKey].
  DeploymentInstructions({
    Key? key,
    this.advertisementKey = '<ADVERTISEMENT_KEY>',
  }) : super(key: key);

  @override
  _DeploymentInstructionsState createState() => _DeploymentInstructionsState();
}

class _DeploymentInstructionsState extends State<DeploymentInstructions> {
  final List<bool> _expanded = [false, false, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Deploy'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              ListTile(
                title: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Congratulations, you successfully created '
                            'your accessory!\nThe next step is to deploy the generated '
                            'key to a Bluetooth device. OpenHaystack currently '
                            'supports three different deployment targets:\n'
                            'Nordic nRF51, Espressif ESP32 and the generic Linux HCI '
                            'platform.\nAdditional information about the deployment '
                            'can be found on ',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                        ),
                      ),
                      TextSpan(
                        text: 'GitHub',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontSize: 18,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            launch(
                                'https://github.com/seemoo-lab/openhaystack/');
                          },
                      ),
                      const TextSpan(
                        text: '.',
                        style: TextStyle(color: Colors.black, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              ExpansionPanelList(
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _expanded[index] = !isExpanded;
                  });
                },
                children: [
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return const ListTile(
                        title: Text('Nordic vRF51'),
                      );
                    },
                    body: Column(
                      children: <Widget>[
                        const ListTile(
                          title: Text(
                              'For this firmware you need a nFR51822 platform '
                              'microcontroller. The provided firmware will send out '
                              'the created key so it can be found by Apple\'s Find My '
                              'network.'),
                        ),
                        ListTile(
                          title: Hyperlink(
                            text: 'See deployment guide on GitHub',
                            target:
                                'https://github.com/seemoo-lab/openhaystack/tree/main/Firmware/Microbit_v1',
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton(
                              child: const Text('Send per mail'),
                              onPressed: () async {
                                await launch(
                                    DeploymentEmail.getMicrobitDeploymentEmail(
                                        widget.advertisementKey));
                              },
                            ),
                            ElevatedButton(
                              child: const Text('Continue'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          DeploymentInstructionsNRF51(
                                            advertisementKey:
                                                widget.advertisementKey,
                                          )),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    isExpanded: _expanded[0],
                  ),
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return const ListTile(
                        title: Text('Espressif ESP32'),
                      );
                    },
                    body: Column(
                      children: <Widget>[
                        const ListTile(
                          title: Text(
                              'For this firmware you need an ESP32 platform '
                              'microcontroller. The provided firmware will send out '
                              'the created key so it can be found by Apple\'s Find My '
                              'network.'),
                        ),
                        ListTile(
                          title: Hyperlink(
                            text: 'See deployment guide on GitHub',
                            target:
                                'https://github.com/seemoo-lab/openhaystack/tree/main/Firmware/ESP32',
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton(
                              child: const Text('Send per mail'),
                              onPressed: () async {
                                await launch(
                                    DeploymentEmail.getESP32DeploymentEmail(
                                        widget.advertisementKey));
                              },
                            ),
                            ElevatedButton(
                              child: const Text('Continue'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          DeploymentInstructionsESP32(
                                            advertisementKey:
                                                widget.advertisementKey,
                                          )),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    isExpanded: _expanded[1],
                  ),
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return const ListTile(
                        title: Text('Linux HCI'),
                      );
                    },
                    body: Column(
                      children: <Widget>[
                        const ListTile(
                          title: Text(
                              'This method only requires a Bluetooth enabled '
                              'Linux device. Using the hcitool and a provided script '
                              'the devices advertises the created key so it can be '
                              'found by Apple\'s Find My network.'),
                        ),
                        ListTile(
                          title: Hyperlink(
                            text: 'See deployment guide on GitHub',
                            target:
                                'https://github.com/seemoo-lab/openhaystack/tree/main/Firmware/Linux_HCI',
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton(
                              child: const Text('Send per mail'),
                              onPressed: () async {
                                await launch(
                                    DeploymentEmail.getLinuxHCIDeploymentEmail(
                                        widget.advertisementKey));
                              },
                            ),
                            ElevatedButton(
                              child: const Text('Continue'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          DeploymentInstructionsLinux(
                                            advertisementKey:
                                                widget.advertisementKey,
                                          )),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    isExpanded: _expanded[2],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
