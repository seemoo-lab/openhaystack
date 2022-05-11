import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/src/utils.dart' as pc_utils;
import 'package:openhaystack_mobile/findMy/find_my_controller.dart';

/// Represents a decrypted FindMyReport.
class FindMyLocationReport {
  double latitude;
  double longitude;
  int accuracy;
  DateTime published;
  DateTime? timestamp;
  int? confidence;

  FindMyLocationReport(this.latitude, this.longitude, this.accuracy,
      this.published, this.timestamp, this.confidence);

  Location get location => Location(latitude, longitude);
}

class Location {
  double latitude;
  double longitude;

  Location(this.latitude, this.longitude);
}

/// FindMy report returned by the FindMy Network
class FindMyReport {
  DateTime datePublished;
  Uint8List payload;
  String id;
  int statusCode;

  int? confidence;
  DateTime? timestamp;

  FindMyReport(this.datePublished, this.payload, this.id, this.statusCode);

  FindMyReport.completeInit(this.datePublished, this.payload, this.id, this.statusCode,
  this.confidence, this.timestamp);

}

class FindMyKeyPair {
  final ECPublicKey _publicKey;
  final ECPrivateKey _privateKey;
  final String hashedPublicKey;
  String? privateKeyBase64;

  /// Time when this key was used to send BLE advertisements
  DateTime startTime;
  /// Duration from start time how long the key was used to send BLE advertisements
  double duration;

  FindMyKeyPair(this._publicKey, this.hashedPublicKey, this._privateKey, this.startTime,
      this.duration);

  String getBase64PublicKey() {
    return base64Encode(_publicKey.Q!.getEncoded(false));
  }
  
  String getBase64PrivateKey() {
    return base64Encode(pc_utils.encodeBigIntAsUnsigned(_privateKey.d!));
  }

  String getBase64AdvertisementKey() {
    return base64Encode(_getAdvertisementKey());
  }

  Uint8List _getAdvertisementKey() {
    var pkBytes = _publicKey.Q!.getEncoded(true);
    //Drop first byte to get the 28byte version
    var key = pkBytes.sublist(1, pkBytes.length);
    return key;
  }

  String getHashedAdvertisementKey() {
    var key = _getAdvertisementKey();
    return FindMyController.getHashedPublicKey(publicKeyBytes: key);
  }
}
