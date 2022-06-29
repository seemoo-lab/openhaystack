import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/src/utils.dart' as pc_utils;
import 'package:openhaystack_mobile/findMy/models.dart';

import 'package:cryptography/cryptography.dart' as nice_crypto;

class DecryptReports {
  /// Decrypts a given [FindMyReport] with the given private key.
  static Future<FindMyLocationReport> decryptReport(
      FindMyReport report, Uint8List key) async {
    final curveDomainParam = ECCurve_secp224r1();

    final payloadData = report.payload;
    final ephemeralKeyBytes = payloadData.sublist(5, 62);
    final encData = payloadData.sublist(62, 72);
    final tag = payloadData.sublist(72, payloadData.length);

    _decodeTimeAndConfidence(payloadData, report);

    final privateKey =
        ECPrivateKey(pc_utils.decodeBigIntWithSign(1, key), curveDomainParam);

    final decodePoint = curveDomainParam.curve.decodePoint(ephemeralKeyBytes);
    final ephemeralPublicKey = ECPublicKey(decodePoint, curveDomainParam);

    final Uint8List sharedKeyBytes = _ecdh(ephemeralPublicKey, privateKey);
    final Uint8List derivedKey = _kdf(sharedKeyBytes, ephemeralKeyBytes);

    final decryptedPayload = await _decryptPayload(encData, derivedKey, tag);
    final locationReport = _decodePayload(decryptedPayload, report);

    return locationReport;
  }

  /// Decodes the unencrypted timestamp and confidence
  static void _decodeTimeAndConfidence(
      Uint8List payloadData, FindMyReport report) {
    final seenTimeStamp =
        payloadData.sublist(0, 4).buffer.asByteData().getInt32(0, Endian.big);
    final timestamp = DateTime(2001).add(Duration(seconds: seenTimeStamp));
    final confidence = payloadData.elementAt(4);
    report.timestamp = timestamp;
    report.confidence = confidence;
  }

  /// Performs an Elliptic Curve Diffie-Hellman with the given keys.
  /// Returns the derived raw key data.
  static Uint8List _ecdh(
      ECPublicKey ephemeralPublicKey, ECPrivateKey privateKey) {
    final sharedKey = ephemeralPublicKey.Q! * privateKey.d;
    final sharedKeyBytes =
        pc_utils.encodeBigIntAsUnsigned(sharedKey!.x!.toBigInteger()!);
    print("Shared Key (shared secret): ${base64Encode(sharedKeyBytes)}");

    return sharedKeyBytes;
  }

  /// Decodes the raw decrypted payload and constructs and returns
  /// the resulting [FindMyLocationReport].
  static FindMyLocationReport _decodePayload(
      Uint8List payload, FindMyReport report) {
    final latitude = payload.buffer.asByteData(0, 4).getUint32(0, Endian.big);
    final longitude = payload.buffer.asByteData(4, 4).getUint32(0, Endian.big);
    final accuracy = payload.buffer.asByteData(8, 1).getUint8(0);

    final latitudeDec = latitude / 10000000.0;
    final longitudeDec = longitude / 10000000.0;

    return FindMyLocationReport(latitudeDec, longitudeDec, accuracy,
        report.datePublished, report.timestamp, report.confidence);
  }

  /// Decrypts the given cipher text with the key data using an AES-GCM block cipher.
  /// Returns the decrypted raw data.
  static Future<Uint8List> _decryptPayload(
      Uint8List cipherText, Uint8List symmetricKey, Uint8List tag) async {
    final decryptionKey = symmetricKey.sublist(0, 16);
    final iv = symmetricKey.sublist(16, symmetricKey.length);
    if (kIsWeb) {
      nice_crypto.SecretKey secretKey =
          new nice_crypto.SecretKey(decryptionKey);

      nice_crypto.SecretBox secretBox = new nice_crypto.SecretBox(cipherText,
          nonce: iv, mac: nice_crypto.Mac(tag));

      List<int> decrypted = await nice_crypto.AesGcm.with128bits()
          .decrypt(secretBox, secretKey: secretKey);

      return Uint8List.fromList(decrypted);
    }

    final aesGcm = GCMBlockCipher(AESEngine())
      ..init(
          false,
          AEADParameters(
              KeyParameter(decryptionKey), tag.lengthInBytes * 8, iv, tag));

    final plainText = Uint8List(cipherText.length);
    var offset = 0;
    while (offset < cipherText.length) {
      offset += aesGcm.processBlock(cipherText, offset, plainText, offset);
    }

    assert(offset == cipherText.length);
    return plainText;
  }

  /// ANSI X.963 key derivation to calculate the actual (symmetric) advertisement
  /// key and returns the raw key data.
  static Uint8List _kdf(Uint8List secret, Uint8List ephemeralKey) {
    var shaDigest = SHA256Digest();
    shaDigest.update(secret, 0, secret.length);

    var counter = 1;
    var counterData = ByteData(4)..setUint32(0, counter);
    var counterDataBytes = counterData.buffer.asUint8List();
    shaDigest.update(counterDataBytes, 0, counterDataBytes.lengthInBytes);

    shaDigest.update(ephemeralKey, 0, ephemeralKey.lengthInBytes);

    Uint8List out = Uint8List(shaDigest.digestSize);
    shaDigest.doFinal(out, 0);

    print("Derived key: ${base64Encode(out)}");
    return out;
  }
}
