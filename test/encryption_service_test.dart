import 'package:test/test.dart';
import 'package:isar_agent_memory/src/sync/encryption_service.dart';

void main() {
  group('EncryptionService', () {
    late EncryptionService service;

    setUp(() {
      service = EncryptionService();
    });

    test('should initialize with a random key if none provided', () async {
      await service.initialize();
      expect(service.isInitialized, isTrue);
    });

    test('should initialize with a specific key', () async {
      final key = List<int>.filled(32, 1); // 32-byte key
      await service.initialize(rawKey: key);
      expect(service.isInitialized, isTrue);
    });

    test('should throw if key length is invalid', () async {
      final key = List<int>.filled(16, 1);
      expect(() => service.initialize(rawKey: key), throwsArgumentError);
    });

    test('should encrypt and decrypt successfully', () async {
      await service.initialize();
      const plainText = 'Hello, World!';

      final encrypted = await service.encrypt(plainText);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(plainText.codeUnits)));

      final decrypted = await service.decrypt(encrypted);
      expect(decrypted, equals(plainText));
    });

    test(
        'should produce different ciphertexts for same plaintext (due to nonce)',
        () async {
      await service.initialize();
      const plainText = 'Secret Data';

      final enc1 = await service.encrypt(plainText);
      final enc2 = await service.encrypt(plainText);

      expect(enc1, isNot(equals(enc2)));

      expect(await service.decrypt(enc1), equals(plainText));
      expect(await service.decrypt(enc2), equals(plainText));
    });
  });
}
