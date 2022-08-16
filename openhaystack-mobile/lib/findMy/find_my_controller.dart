import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';
import 'package:pointycastle/src/utils.dart' as pc_utils;
import 'package:openhaystack_mobile/findMy/decrypt_reports.dart';
import 'package:openhaystack_mobile/findMy/models.dart';
import 'package:openhaystack_mobile/findMy/reports_fetcher.dart';

class FindMyController {
  static const _storage = FlutterSecureStorage();
  static final ECCurve_secp224r1 _curveParams = ECCurve_secp224r1();
  static HashMap _keyCache = HashMap();

  /// Starts a new [Isolate], fetches and decrypts all location reports
  /// for the given [FindMyKeyPair].
  /// Returns a list of [FindMyLocationReport]'s.
  static Future<List<FindMyLocationReport>> computeResults(
      FindMyKeyPair keyPair) async {
    await _loadPrivateKey(keyPair);
    return compute(_getListedReportResults, keyPair);
  }

  /// Fetches and decrypts the location reports for the given
  /// [FindMyKeyPair] from apples FindMy Network.
  /// Returns a list of [FindMyLocationReport].
  static Future<List<FindMyLocationReport>> _getListedReportResults(
      FindMyKeyPair keyPair) async {
    List<FindMyLocationReport> results = <FindMyLocationReport>[];
    final jsonResults = await ReportsFetcher.fetchLocationReports(
        keyPair.getHashedAdvertisementKey());
    for (var result in jsonResults) {
      try {
        results.add(
            await _decryptResult(result, keyPair, keyPair.privateKeyBase64!));
      } catch (e) {
        print(e);
      }
    }
    return results;
  }

  /// Loads the private key from the local cache or secure storage and adds it
  /// to the given [FindMyKeyPair].
  static Future<void> _loadPrivateKey(FindMyKeyPair keyPair) async {
    String? privateKey;
    if (!_keyCache.containsKey(keyPair.hashedPublicKey)) {
      privateKey = await _storage.read(key: keyPair.hashedPublicKey);
      final newKey =
          _keyCache.putIfAbsent(keyPair.hashedPublicKey, () => privateKey);
      assert(newKey == privateKey);
    } else {
      privateKey = _keyCache[keyPair.hashedPublicKey];
    }
    keyPair.privateKeyBase64 = privateKey!;
  }

  /// Derives an [ECPublicKey] from a given [ECPrivateKey] on the given curve.
  static ECPublicKey _derivePublicKey(ECPrivateKey privateKey) {
    final pk = _curveParams.G * privateKey.d;
    final publicKey = ECPublicKey(pk, _curveParams);
    print("Point Data: ${base64Encode(publicKey.Q!.getEncoded(false))}");

    return publicKey;
  }

  /// Decrypts the encrypted reports with the given [FindMyKeyPair] and private key.
  /// Returns the decrypted report as a [FindMyLocationReport].
  static Future<FindMyLocationReport> _decryptResult(
      dynamic result, FindMyKeyPair keyPair, String privateKey) async {
    assert(result["id"]! == keyPair.getHashedAdvertisementKey(),
        "Returned FindMyReport hashed key != requested hashed key");

    final unixTimestampInMillis = result["datePublished"];
    final datePublished =
        DateTime.fromMillisecondsSinceEpoch(unixTimestampInMillis);
    FindMyReport report = FindMyReport(
        datePublished,
        base64Decode(result["payload"]),
        keyPair.getHashedAdvertisementKey(),
        result["statusCode"]);

    FindMyLocationReport decryptedReport =
        await DecryptReports.decryptReport(report, base64Decode(privateKey));

    return decryptedReport;
  }

  /// Returns the to the base64 encoded given hashed public key
  /// corresponding [FindMyKeyPair] from the local [FlutterSecureStorage].
  static Future<FindMyKeyPair> getKeyPair(String base64HashedPublicKey) async {
    final privateKeyBase64 = await _storage.read(key: base64HashedPublicKey);

    ECPrivateKey privateKey = ECPrivateKey(
        pc_utils.decodeBigIntWithSign(1, base64Decode(privateKeyBase64!)),
        _curveParams);
    ECPublicKey publicKey = _derivePublicKey(privateKey);

    return FindMyKeyPair(
        publicKey, base64HashedPublicKey, privateKey, DateTime.now(), -1);
  }

  /// Imports a base64 encoded private key to the local [FlutterSecureStorage].
  /// Returns a [FindMyKeyPair] containing the corresponding [ECPublicKey].
  static Future<FindMyKeyPair> importKeyPair(String privateKeyBase64) async {
    final privateKeyBytes = base64Decode(privateKeyBase64);
    final ECPrivateKey privateKey = ECPrivateKey(
        pc_utils.decodeBigIntWithSign(1, privateKeyBytes), _curveParams);
    final ECPublicKey publicKey = _derivePublicKey(privateKey);
    final hashedPublicKey = getHashedPublicKey(publicKey: publicKey);
    final keyPair = FindMyKeyPair(
        publicKey, hashedPublicKey, privateKey, DateTime.now(), -1);

    await _storage.write(
        key: hashedPublicKey, value: keyPair.getBase64PrivateKey());

    return keyPair;
  }

  /// Generates a [ECCurve_secp224r1] keypair.
  /// Returns the newly generated keypair as a [FindMyKeyPair] object.
  static Future<FindMyKeyPair> generateKeyPair() async {
    final ecCurve = ECCurve_secp224r1();
    final secureRandom = SecureRandom('Fortuna')
      ..seed(
          KeyParameter(Platform.instance.platformEntropySource().getBytes(32)));
    ECKeyGenerator keyGen = ECKeyGenerator()
      ..init(ParametersWithRandom(
          ECKeyGeneratorParameters(ecCurve), secureRandom));

    final newKeyPair = keyGen.generateKeyPair();
    final ECPublicKey publicKey = newKeyPair.publicKey as ECPublicKey;
    final ECPrivateKey privateKey = newKeyPair.privateKey as ECPrivateKey;
    final hashedKey = getHashedPublicKey(publicKey: publicKey);
    final keyPair =
        FindMyKeyPair(publicKey, hashedKey, privateKey, DateTime.now(), -1);
    await _storage.write(key: hashedKey, value: keyPair.getBase64PrivateKey());

    return keyPair;
  }

  /// Returns hashed, base64 encoded public key for given [publicKeyBytes]
  /// or for an [ECPublicKey] object [publicKey], if [publicKeyBytes] equals null.
  /// Returns the base64 encoded hashed public key as a [String].
  static String getHashedPublicKey(
      {Uint8List? publicKeyBytes, ECPublicKey? publicKey}) {
    var pkBytes = publicKeyBytes ?? publicKey!.Q!.getEncoded(false);
    final shaDigest = SHA256Digest();
    shaDigest.update(pkBytes, 0, pkBytes.lengthInBytes);
    Uint8List out = Uint8List(shaDigest.digestSize);
    shaDigest.doFinal(out, 0);
    return base64Encode(out);
  }
}
