import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:isar_agent_memory/src/multi_modal_adapter.dart';

void main() {
  group('RemoteMultiModalAdapter tests', () {
    const apiUrl = 'https://api.openai.com/v1/embeddings';
    const apiKey = 'test_key_123';

    test('embedText with OpenAI format (success)', () async {
      final mockResponse = {
        'data': [
          {
            'embedding': [0.1, 0.2, 0.3, 0.4]
          }
        ]
      };

      final client = MockClient((request) async {
        expect(request.url.toString(), equals(apiUrl));
        expect(request.headers['Authorization'], equals('Bearer $apiKey'));
        expect(request.headers['Content-Type'], equals('application/json'));

        final body = jsonDecode(request.body);
        expect(body['model'], equals('text-embedding-3-small'));
        expect(body['input'], equals('Hello, world!'));

        return http.Response(jsonEncode(mockResponse), 200);
      });

      final adapter = RemoteMultiModalAdapter(
        apiUrl: apiUrl,
        apiKey: apiKey,
        client: client,
        dimensions: 4,
      );

      final result = await adapter.embedText('Hello, world!');
      expect(result, equals([0.1, 0.2, 0.3, 0.4]));
      expect(adapter.dimensions, equals(4));
      adapter.dispose();
    });

    test('embedText with Gemini format (success)', () async {
      final mockResponse = {
        'embedding': {
          'values': [0.5, 0.6, 0.7, 0.8]
        }
      };

      final client = MockClient((request) async {
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final adapter = RemoteMultiModalAdapter(
        apiUrl: apiUrl,
        apiKey: apiKey,
        client: client,
        dimensions: 4,
      );

      final result = await adapter.embedText('Hello, Gemini!');
      expect(result, equals([0.5, 0.6, 0.7, 0.8]));
      adapter.dispose();
    });

    test('embedImage with PNG MIME type detection', () async {
      // PNG Magic Bytes: 0x89, 0x50, 0x4E, 0x47
      final pngBytes =
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x00, 0x01, 0x02]);
      final expectedBase64 = base64Encode(pngBytes);
      final expectedDataUrl = 'data:image/png;base64,$expectedBase64';

      final mockResponse = {
        'data': [
          {
            'embedding': [1.0, 2.0, 3.0, 4.0]
          }
        ]
      };

      final client = MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(body['input'], equals(expectedDataUrl));
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final adapter = RemoteMultiModalAdapter(
        apiUrl: apiUrl,
        apiKey: apiKey,
        client: client,
        dimensions: 4,
      );

      final result = await adapter.embedImage(pngBytes);
      expect(result, equals([1.0, 2.0, 3.0, 4.0]));
      adapter.dispose();
    });

    test('embedImage with JPEG MIME type detection', () async {
      // JPEG Magic Bytes: 0xFF, 0xD8
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0x00, 0x01, 0x02]);
      final expectedBase64 = base64Encode(jpegBytes);
      final expectedDataUrl = 'data:image/jpeg;base64,$expectedBase64';

      final mockResponse = {
        'data': [
          {
            'embedding': [1.1, 2.1, 3.1, 4.1]
          }
        ]
      };

      final client = MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(body['input'], equals(expectedDataUrl));
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final adapter = RemoteMultiModalAdapter(
        apiUrl: apiUrl,
        apiKey: apiKey,
        client: client,
        dimensions: 4,
      );

      final result = await adapter.embedImage(jpegBytes);
      expect(result, equals([1.1, 2.1, 3.1, 4.1]));
      adapter.dispose();
    });

    test('embedImage with unrecognized MIME fallback (default png)', () async {
      // Arbitrary non-matching bytes
      final unknownBytes = Uint8List.fromList([0x00, 0x11, 0x22, 0x33]);
      final expectedBase64 = base64Encode(unknownBytes);
      final expectedDataUrl = 'data:image/png;base64,$expectedBase64';

      final mockResponse = {
        'data': [
          {
            'embedding': [2.2, 3.3, 4.4, 5.5]
          }
        ]
      };

      final client = MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(body['input'], equals(expectedDataUrl));
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final adapter = RemoteMultiModalAdapter(
        apiUrl: apiUrl,
        apiKey: apiKey,
        client: client,
        dimensions: 4,
      );

      final result = await adapter.embedImage(unknownBytes);
      expect(result, equals([2.2, 3.3, 4.4, 5.5]));
      adapter.dispose();
    });

    test('HTTP non-200 error handling', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final adapter = RemoteMultiModalAdapter(
        apiUrl: apiUrl,
        apiKey: apiKey,
        client: client,
        dimensions: 4,
      );

      expect(
        () => adapter.embedText('error test'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
                'Remote embedding API returned HTTP 500: Internal Server Error'),
          ),
        ),
      );
      adapter.dispose();
    });

    test('Unexpected JSON response format error handling', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'unknown_key': 'some_value'}), 200);
      });

      final adapter = RemoteMultiModalAdapter(
        apiUrl: apiUrl,
        apiKey: apiKey,
        client: client,
        dimensions: 4,
      );

      expect(
        () => adapter.embedText('format error test'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Unexpected embedding API response format'),
          ),
        ),
      );
      adapter.dispose();
    });
  });
}
