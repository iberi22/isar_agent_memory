import '../models/memory_node.dart';

/// Builder for medical-specific RAG prompts.
class MedicalPromptBuilder {
  /// Default medical safety disclaimer in Spanish.
  static const String spanishDisclaimer =
      'AVISO MÉDICO: Esta respuesta es generada por una IA y tiene fines informativos únicamente. '
      'No sustituye el consejo, diagnóstico o tratamiento médico profesional. '
      'Siempre busque el consejo de su médico u otro proveedor de salud calificado.';

  /// Constructs a RAG prompt with the given query and context nodes.
  String buildRagPrompt({
    required String query,
    required List<MemoryNode> contextNodes,
    String language = 'es',
  }) {
    final contextBuffer = StringBuffer();
    for (var i = 0; i < contextNodes.length; i++) {
      contextBuffer.writeln('[${i + 1}] ${contextNodes[i].content}');
    }

    if (language == 'es') {
      return '''Utiliza la siguiente información de contexto para responder a la pregunta médica de forma precisa.
Si la información no es suficiente, indícalo.

CONTEXTO:
${contextBuffer.toString()}

PREGUNTA: $query

RESPUESTA (incluye citas numéricas como [1] si corresponde):''';
    } else {
      return '''Use the following context to answer the medical question accurately.
If the information is not sufficient, please state it.

CONTEXT:
${contextBuffer.toString()}

QUESTION: $query

RESPONSE (include numeric citations like [1] if applicable):''';
    }
  }

  /// Builds a prompt for query decomposition.
  String buildDecompositionPrompt(String query) {
    return '''Divide la siguiente consulta médica compleja en sub-preguntas más simples que puedan ser buscadas de forma independiente.
Responde solo con la lista de preguntas, una por línea.

CONSULTA: $query

SUB-PREGUNTAS:''';
  }

  /// Wraps a response with the medical disclaimer.
  String wrapWithDisclaimer(String response, {String language = 'es'}) {
    final disclaimer = language == 'es'
        ? spanishDisclaimer
        : 'MEDICAL DISCLAIMER: This response is AI-generated and for informational purposes only. '
            'It is not a substitute for professional medical advice, diagnosis, or treatment.';

    return '$response\n\n---\n$disclaimer';
  }
}
