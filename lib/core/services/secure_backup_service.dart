import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'backup_service.dart';
import '../database/app_database.dart';

class SecureBackupService {
  SecureBackupService(this.database);

  final AppDatabase database;

  Future<File> exportEncryptedBackup(String password) async {
    if (password.length < 6) {
      throw Exception('كلمة المرور يجب أن تكون 6 أحرف أو أكثر');
    }

    final plainFile = await BackupService(database).exportBackup();
    final plainText = await plainFile.readAsString(encoding: utf8);

    final salt = _randomSalt();
    final encrypted = _xorText(
      plainText,
      _keyFromPassword(password, salt),
    );

    final payload = {
      'app': 'hisabati',
      'type': 'encrypted_backup',
      'version': 1,
      'created_at': DateTime.now().toIso8601String(),
      'salt': base64Encode(salt),
      'payload': base64Encode(encrypted),
    };

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/hisabati_secure_backup_${DateTime.now().millisecondsSinceEpoch}.hbak');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload), encoding: utf8);

    try {
      await plainFile.delete();
    } catch (_) {}

    return file;
  }

  Future<File> decryptToTemporaryJson({
    required File encryptedFile,
    required String password,
  }) async {
    if (password.length < 6) {
      throw Exception('كلمة المرور غير صحيحة');
    }

    final content = await encryptedFile.readAsString(encoding: utf8);
    final decoded = jsonDecode(content);

    if (decoded is! Map || decoded['type'] != 'encrypted_backup') {
      throw Exception('هذا الملف ليس نسخة مشفرة من حساباتي');
    }

    final salt = base64Decode(decoded['salt'].toString());
    final payload = base64Decode(decoded['payload'].toString());

    final plainBytes = _xorBytes(
      payload,
      _keyFromPassword(password, salt),
    );

    final plainText = utf8.decode(plainBytes);

    final plainDecoded = jsonDecode(plainText);
    if (plainDecoded is! Map || plainDecoded['app'] != 'hisabati') {
      throw Exception('كلمة المرور غير صحيحة أو الملف تالف');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/hisabati_decrypted_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(plainText, encoding: utf8);
    return file;
  }

  Future<void> restoreEncryptedBackup({
    required File encryptedFile,
    required String password,
  }) async {
    final jsonFile = await decryptToTemporaryJson(
      encryptedFile: encryptedFile,
      password: password,
    );

    await BackupService(database).restoreBackup(jsonFile);

    try {
      await jsonFile.delete();
    } catch (_) {}
  }

  List<int> _randomSalt() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(256));
  }

  List<int> _keyFromPassword(String password, List<int> salt) {
    final input = utf8.encode(password) + salt;
    var digest = sha256.convert(input).bytes;

    for (var i = 0; i < 1000; i++) {
      digest = sha256.convert(digest + input).bytes;
    }

    return digest;
  }

  List<int> _xorText(String text, List<int> key) {
    return _xorBytes(utf8.encode(text), key);
  }

  List<int> _xorBytes(List<int> input, List<int> key) {
    final output = <int>[];

    for (var i = 0; i < input.length; i++) {
      output.add(input[i] ^ key[i % key.length]);
    }

    return output;
  }
}