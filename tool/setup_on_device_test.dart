import 'dart:io';
import 'package:http/http.dart' as http;

/// Downloads a small quantized BERT model and vocab for testing purposes.
/// Model: all-MiniLM-L6-v2 (INT8 quantized)
/// Source: Hugging Face (xenova/all-MiniLM-L6-v2 or similar reliable source)
///
/// Note: We use a specific commit/file to ensure stability.
void main() async {
  final targetDir = Directory('test_resources');
  if (!await targetDir.exists()) {
    await targetDir.create();
  }

  // URLs for a small ONNX model (quantized) and vocab
  // Using a reliable source (e.g. from optimum-js or similar exports)
  // For this example, we'll try to use a direct link to a hosted file if possible,
  // or instruct the user. Since I cannot guarantee a permanent direct link without a proper CDN,
  // I will use a standard HF Hub URL format.

  // Example: Xenova/all-MiniLM-L6-v2
  // model_quantized.onnx (~23MB)
  // vocab.txt

  final modelUrl =
      'https://huggingface.co/Xenova/all-MiniLM-L6-v2/resolve/main/onnx/model_quantized.onnx';
  final vocabUrl =
      'https://huggingface.co/Xenova/all-MiniLM-L6-v2/resolve/main/vocab.txt';

  print('Downloading test resources to ${targetDir.path}...');

  await _downloadFile(vocabUrl, '${targetDir.path}/vocab.txt');
  await _downloadFile(modelUrl, '${targetDir.path}/model.onnx');

  print('Download complete. You can now run the on-device tests.');
}

Future<void> _downloadFile(String url, String savePath) async {
  final file = File(savePath);
  if (await file.exists()) {
    print('File already exists: $savePath (skipping)');
    return;
  }

  print('Downloading $url...');
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      print('Saved to $savePath');
    } else {
      print('Failed to download $url (Status: ${response.statusCode})');
    }
  } catch (e) {
    print('Error downloading $url: $e');
  }
}
