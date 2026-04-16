import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Helper for AES-256 encryption and decryption.
class EncryptionUtils {
  static final _algorithm = AesGcm.with256bits();

  /// Encrypts [plainText] using a [passphrase].
  ///
  /// Returns a base64 encoded string containing the nonce and ciphertext.
  static Future<String> encrypt(String plainText, String passphrase) async {
    final secretKey = await _deriveKey(passphrase);
    final nonce = _algorithm.newNonce();

    final secretBox = await _algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: secretKey,
      nonce: nonce,
    );

    final combined = Uint8List(secretBox.nonce.length + secretBox.cipherText.length + secretBox.mac.bytes.length);
    combined.setRange(0, secretBox.nonce.length, secretBox.nonce);
    combined.setRange(secretBox.nonce.length, secretBox.nonce.length + secretBox.mac.bytes.length, secretBox.mac.bytes);
    combined.setRange(secretBox.nonce.length + secretBox.mac.bytes.length, combined.length, secretBox.cipherText);

    return base64.encode(combined);
  }

  /// Decrypts [encryptedText] using a [passphrase].
  static Future<String> decrypt(String encryptedText, String passphrase) async {
    final secretKey = await _deriveKey(passphrase);
    final combined = base64.decode(encryptedText);

    // Nonce is 12 bytes for AesGcm
    const nonceLength = 12;
    // MAC is 16 bytes for AesGcm
    const macLength = 16;

    final nonce = combined.sublist(0, nonceLength);
    final mac = Mac(combined.sublist(nonceLength, nonceLength + macLength));
    final cipherText = combined.sublist(nonceLength + macLength);

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final clearText = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(clearText);
  }

  /// Derives a 256-bit key from a passphrase.
  static Future<SecretKey> _deriveKey(String passphrase) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 1000,
      bits: 256,
    );

    // In a real app, we should use a salt. For simplicity, we use a fixed salt here.
    final salt = utf8.encode('isar_agent_memory_salt');

    return await pbkdf2.deriveKeyFromPassword(
      password: passphrase,
      nonce: salt,
    );
  }

  /// Generates a hash of the passphrase for verification.
  static Future<String> hashPassphrase(String passphrase) async {
    final message = utf8.encode(passphrase);
    final hash = await Sha256().hash(message);
    return base64.encode(hash.bytes);
  }
}
