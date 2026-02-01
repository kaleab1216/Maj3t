class Translation {
  final String key; // Original text key
  final String translatedText;
  final String languageCode;

  Translation({
    required this.key,
    required this.translatedText,
    required this.languageCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'translatedText': translatedText,
      'languageCode': languageCode,
    };
  }

  factory Translation.fromMap(Map<String, dynamic> map) {
    return Translation(
      key: map['key'] ?? '',
      translatedText: map['translatedText'] ?? '',
      languageCode: map['languageCode'] ?? 'en',
    );
  }
}