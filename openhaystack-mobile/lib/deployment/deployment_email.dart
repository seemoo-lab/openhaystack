class DeploymentEmail {
  static const _mailtoLink =
      'mailto:?subject=Open%20Haystack%20Deplyoment%20Instructions&body=';

  static const _welcomeMessage = 'OpenHaystack Deployment Guide\n\n'
      'This is the deployment guide for your recently created OpenHaystack accessory. '
      'The next step is to deploy the generated cryptographic key to a compatible '
      'Bluetooth device.\n\n';

  static const _finishedMessage =
      '\n\nThe device now sends out Bluetooth advertisements. '
      'It can take up to an hour for the location updates to appear in the app.\n';

  static String getMicrobitDeploymentEmail(String advertisementKey) {
    String mailContent = 'nRF51822 Deployment:\n\n'
        'Requirements\n'
        'To build the firmware the GNU Arm Embedded Toolchain is required.\n\n'
        'Download\n'
        'Download the firmware source code from GitHub and navigate to the '
        'given folder.\n'
        'https://github.com/seemoo-lab/openhaystack\n'
        'git clone https://github.com/seemoo-lab/openhaystack.git && '
        'cd openhaystack/Firmware/Microbit_v1\n\n'
        'Build\n'
        'Replace the public_key in main.c (initially '
        'OFFLINEFINEINGPUBLICKEYHERE!) with the actual advertisement key. '
        'Then execute make to create the firmware. You can export your '
        'advertisement key directly from the OpenHaystack app.\n'
        'static char public_key[28] = $advertisementKey;\n'
        'make\n\n'
        'Firmware Deployment\n'
        'If the firmware is built successfully it can be deployed to the '
        'microcontroller with the following command. (Please fill in the '
        'volume of your microcontroller) \n'
        'make install  DEPLOY_PATH=/Volumes/MICROBIT';

    return _mailtoLink +
        Uri.encodeComponent(_welcomeMessage) +
        Uri.encodeComponent(mailContent) +
        Uri.encodeComponent(_finishedMessage);
  }

  static String getESP32DeploymentEmail(String advertisementKey) {
    String mailContent = 'Espressif ESP32 Deployment: \n\n'
        'Requirements\n'
        'To build the firmware for the ESP32 Espressif\'s IoT Development '
        'Framework (ESP-IDF) is required. Additionally Python 3 and the venv '
        'module need to be installed.\n\n'
        'Download\n'
        'Download the firmware source code from GitHub and navigate to the '
        'given folder.\n'
        'https://github.com/seemoo-lab/openhaystack\n'
        'git clone https://github.com/seemoo-lab/openhaystack.git '
        '&& cd openhaystack/Firmware/ESP32\n\n'
        'Build\n'
        'Execute the ESP-IDF build command to create the ESP32 firmware.\n'
        'idf.py build\n\n'
        'Firmware Deployment\n'
        'If the firmware is built successfully it can be flashed onto the '
        'ESP32. This action is performed by the flash_esp32.sh script that '
        'is provided with the advertisement key of the newly created accessory.\n'
        'Please fill in the serial port of your microcontroller.\n'
        'You can export your advertisement key directly from the '
        'OpenHaystack app.\n'
        './flash_esp32.sh -p /dev/yourSerialPort $advertisementKey';

    return _mailtoLink +
        Uri.encodeComponent(_welcomeMessage) +
        Uri.encodeComponent(mailContent) +
        Uri.encodeComponent(_finishedMessage);
  }

  static String getLinuxHCIDeploymentEmail(String advertisementKey) {
    String mailContent = 'Linux HCI Deployment:\n\n'
        'Requirements\n'
        'Install the hcitool software on a Bluetooth Low Energy Linux device, '
        'for example a Raspberry Pi. Additionally Pyhton 3 needs to be '
        'installed.\n\n'
        'Download\n'
        'Next download the python script that configures the HCI tool to '
        'send out BLE advertisements.\n'
        'https://raw.githubusercontent.com/seemoo-lab/openhaystack/main/Firmware/Linux_HCI/HCI.py\n'
        'curl -o HCI.py https://raw.githubusercontent.com/seemoo-lab/openhaystack/main/Firmware/Linux_HCI/HCI.py\n\n'
        'Usage\n'
        'To start the BLE advertisements run the script.\n'
        'You can export your advertisement key directly from the '
        'OpenHaystack app.\n'
        'sudo python3 HCI.py --key $advertisementKey';

    return _mailtoLink +
        Uri.encodeComponent(_welcomeMessage) +
        Uri.encodeComponent(mailContent) +
        Uri.encodeComponent(_finishedMessage);
  }
}
