import 'package:cryptography/cryptography.dart';

class EncryptionService {
  // Change explicit Algorithm type to specific AesGcm or dynamic if base class is different/private
  final AesGcm _algorithm = AesGcm.with256bits();
  SecretKey? _secretKey;

  bool get isInitialized => _secretKey != null;

  /// Initializes the service with a raw 32-byte key or generates one if not provided.
  Future<void> initialize({List<int>? rawKey}) async {
    if (rawKey != null) {
      if (rawKey.length != 32) {
        throw ArgumentError('Key must be 32 bytes long');
      }
      _secretKey = await _algorithm.newSecretKeyFromBytes(rawKey);
    } else {
      _secretKey = await _algorithm.newSecretKey();
    }
  }

  /// Encrypts a string using AES-256-GCM.
  /// Returns a concatenation of nonce + ciphertext + mac for storage.
  Future<List<int>> encrypt(String plainText) async {
    if (_secretKey == null) throw StateError('EncryptionService not initialized');

    final secretBox = await _algorithm.encrypt(
      plainText.codeUnits,
      secretKey: _secretKey!,
    );

    return secretBox.concatenation();
  }

  /// Decrypts a byte list (nonce + ciphertext + mac) back to string.
  Future<String> decrypt(List<int> data) async {
    if (_secretKey == null) throw StateError('EncryptionService not initialized');

    // AES-GCM in cryptography package:
    // Nonce: 12 bytes (default for AesGcm)
    // MAC: 16 bytes (default)
    final secretBox = SecretBox.fromConcatenation(
      data,
      nonceLength: 12,
      macLength: 16,
    );

    final clearTextBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: _secretKey!,
    );

    return String.fromCharCodes(clearTextBytes);
  }
}
