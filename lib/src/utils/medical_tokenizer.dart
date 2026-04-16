/// A utility for pre-processing medical text, specifically expanding abbreviations.
/// Supports both Spanish and English medical terms.
class MedicalTokenizer {
  /// Map of medical abbreviations to their full forms.
  /// Keys are lowercase for case-insensitive matching.
  static const Map<String, String> _abbreviations = {
    // Spanish
    'ta': 'tensión arterial',
    'fc': 'frecuencia cardíaca',
    'spo2': 'saturación de oxígeno',
    'fr': 'frecuencia respiratoria',
    'tª': 'temperatura',
    'hta': 'hipertensión arterial',
    'dm': 'diabetes mellitus',
    'ecg': 'electrocardiograma',
    'rx': 'radiografía',
    'tac': 'tomografía axial computarizada',
    'rmn': 'resonancia magnética nuclear',
    'scq': 'superficie corporal quemada',
    'avd': 'actividades de la vida diaria',
    'ev': 'vía endovenosa',
    'im': 'vía intramuscular',
    'sc': 'vía subcutánea',
    'sl': 'vía sublingual',

    // English
    'bp': 'blood pressure',
    'hr': 'heart rate',
    'rr': 'respiratory rate',
    'temp': 'temperature',
    'htn': 'hypertension',
    'ekg': 'electrocardiogram',
    'ct': 'computed tomography',
    'mri': 'magnetic resonance imaging',
    'iv': 'intravenous',
    'icu': 'intensive care unit',
    'er': 'emergency room',
    'prn': 'pro re nata (as needed)',
    'bid': 'twice a day',
    'tid': 'three times a day',
    'qid': 'four times a day',
  };

  /// Expands abbreviations in the given [text].
  ///
  /// This handles both Spanish and English abbreviations defined in [_abbreviations].
  /// It performs case-insensitive matching but attempts to preserve the context.
  String expandAbbreviations(String text) {
    if (text.isEmpty) return text;

    String expandedText = text;

    // Sort keys by length descending to avoid partial matches (e.g., 'ta' in 'tac')
    final sortedKeys = _abbreviations.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in sortedKeys) {
      // Use regex with word boundaries to avoid matching inside words
      // e.g. "TA" should match but "taza" should not.
      // We handle Tª specifically as it has a special character.
      final escapedKey = RegExp.escape(key);
      final regex = RegExp('\\b$escapedKey\\b', caseSensitive: false);

      // Special case for Tª since \b might not work as expected with ª
      if (key == 'tª') {
        expandedText = expandedText.replaceAll(
            RegExp(r'Tª', caseSensitive: false), _abbreviations[key]!);
      } else {
        expandedText = expandedText.replaceAllMapped(regex, (match) {
          return _abbreviations[key]!;
        });
      }
    }

    return expandedText;
  }
}
