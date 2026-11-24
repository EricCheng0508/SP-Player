/// Result of an AI sentence explanation (grammar breakdown + key phrases).
library;

class LineExplanation {
  const LineExplanation({required this.text});

  factory LineExplanation.fromJson(Map<String, dynamic> json) =>
      LineExplanation(text: json['text'] as String? ?? '');

  final String text;

  Map<String, dynamic> toJson() => {'text': text};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LineExplanation && text == other.text;

  @override
  int get hashCode => text.hashCode;
}
