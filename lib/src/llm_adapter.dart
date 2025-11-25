/// Abstract interface for a generic Large Language Model (LLM).
///
/// This class defines the contract for generating text content based on a given prompt.
abstract class LLMAdapter {
  /// Generates content based on the given [prompt].
  ///
  /// Returns a [Future] that completes with the generated [String].
  Future<String> generate(String prompt);
}
