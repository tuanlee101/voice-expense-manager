class VoiceCommand {
  final String rawText;
  final String? intent; // add_expense, query_expense, set_budget, etc.
  final double confidence;
  final Map<String, dynamic> entities; // amount, category, date, note, etc.

  VoiceCommand({
    required this.rawText,
    this.intent,
    this.confidence = 0.0,
    this.entities = const {},
  });

  bool get hasIntent => intent != null && confidence >= 0.6;

  bool get isHighConfidence => confidence >= 0.7;

  bool get isAmbiguous => confidence > 0 && confidence < 0.6;

  T? get<T>(String key) => entities[key] as T?;

  @override
  String toString() =>
      'VoiceCommand(text: "$rawText", intent: $intent, conf: ${(confidence * 100).toStringAsFixed(0)}%)';
}
