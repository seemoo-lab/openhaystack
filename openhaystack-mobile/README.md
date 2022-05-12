# OpenHaystack Mobile
Porting OpenHaystack to Mobile

# About OpenHaystack
OpenHaystack is a project that allows location tracking of Bluetooth Low Energy (BLE) devices over Apples Find My Network.

# Development
This project is written in [Dart](https://dart.dev/), using the cross platform development framework [Flutter](https://flutter.dev/). This allows the creation of apps for all major platforms using a single code base.

## Requisites
To develop and build the project the following tools are needed and should be installed.

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Xcode](https://developer.apple.com/xcode/) (for iOS)
- [Android SDK / Studio](https://developer.android.com/studio/) (for Android)
- (optional) IDE Plugin (e.g. for [VS Code](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter))

To check the installation run `flutter doctor`. Before continuing review all displayed errors.


## Getting Started
First the necessary dependencies need to be installed. The IDE plugin may take care of this automatically.
```bash
$ flutter pub get
```

Then set the location proxy server URL in [reports_fetcher.dart](lib/findMy/reports_fetcher.dart) (replace `https://add-your-proxy-server-here/getLocationReports` with your custom URL).

To run the debug version of the app start a supported emulator and run
```bash
$ flutter run
```

When the app is running a new key pair can be created / imported in the app.

## Project Structure
The project follows the default structure for flutter applications. The `android`, `ios` and `web` folders contain native projects for the specified platform. Native code can be added here for example to access special APIs.

The business logic and UI can be found in the `lib` folder. This folder is furthermore separated into modules containing code regarding a common aspect.
The business logic for accessing and decrypting the location reports is separated in the `findMy` folder for easier reuse.

## Building
This project currently supports iOS and Android targets.
If you are building the project for the first time, you need to run
```bash
$ flutter pub run flutter_launcher_icons:main 
```
to create the icons and then, to create a distributable application package run
```bash
$ flutter build [ios|apk|web]
```
The resulting build artifacts can be found in the `build` folder. To deploy the artifacts to a device consult the platform specific documentation.
