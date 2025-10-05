// voice_extractor.dart
// Shared voice extraction utility for patient registration features

library voice_extractor;

Map<String, String> extractPatientFeatures(String text) {
  final Map<String, String> extracted = {};
  final lowerText = text.toLowerCase();

  // Stop words to filter out
  final stopWords = {
    'is', 'was', 'or', 'the', 'a', 'an', 'and', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by',
    'name', 'age', 'phone', 'address', 'condition', 'gender', 'priority', 'category', 'male', 'female',
    'low', 'medium', 'high', 'critical', 'pregnant', 'child', 'number'
  };

  String cleanValue(String value) {
    final words = value.toLowerCase().split(RegExp(r'\s+')).where((word) => word.isNotEmpty && !stopWords.contains(word)).toList();
    return words.join(' ').trim();
  }

  // General patient
  final nameRegex = RegExp(r'\bname\s+(?:is\s+)?([a-zA-Z\s]+?)(?:\s+(age|phone|address|condition|gender|priority|category|$))', caseSensitive: false);
  final nameMatch = nameRegex.firstMatch(text);
  if (nameMatch != null) {
    final value = cleanValue(nameMatch.group(1) ?? '');
    if (value.isNotEmpty) extracted['name'] = value;
  }

  final ageRegex = RegExp(r'\bage\s+(?:is\s+)?(\d+)(?:\s+(year|old)?)?\b', caseSensitive: false);
  final ageMatch = ageRegex.firstMatch(text);
  if (ageMatch != null) extracted['age'] = ageMatch.group(1) ?? '';

  final phoneRegex = RegExp(r'\bphone\s+(?:number\s+)?(?:is\s+)?(\d{10,})(?:\s|$)', caseSensitive: false);
  final phoneMatch = phoneRegex.firstMatch(text);
  if (phoneMatch != null) extracted['phone'] = phoneMatch.group(1) ?? '';

  final addressRegex = RegExp(r'\baddress\s+(?:is\s+)?([a-zA-Z0-9\s,.-]+?)(?:\s+(age|phone|condition|name|$))', caseSensitive: false);
  final addressMatch = addressRegex.firstMatch(text);
  if (addressMatch != null) {
    final value = cleanValue(addressMatch.group(1) ?? '');
    if (value.isNotEmpty) extracted['address'] = value;
  }

  final conditionRegex = RegExp(r'\bcondition\s+(?:is\s+)?([a-zA-Z\s]+?)(?:\s+(priority|category|name|$))', caseSensitive: false);
  final conditionMatch = conditionRegex.firstMatch(text);
  if (conditionMatch != null) {
    final value = cleanValue(conditionMatch.group(1) ?? '');
    if (value.isNotEmpty) extracted['condition'] = value;
  }

  if (lowerText.contains('male')) extracted['gender'] = 'Male';
  else if (lowerText.contains('female')) extracted['gender'] = 'Female';
  else if (lowerText.contains('other')) extracted['gender'] = 'Other';

  if (lowerText.contains('low')) extracted['priority'] = 'Low';
  else if (lowerText.contains('medium')) extracted['priority'] = 'Medium';
  else if (lowerText.contains('high')) extracted['priority'] = 'High';
  else if (lowerText.contains('critical')) extracted['priority'] = 'Critical';

  if (lowerText.contains('pregnant')) extracted['category'] = 'pregnant_women';
  else if (lowerText.contains('child')) extracted['category'] = 'child_health';

  final aadhaarRegex = RegExp(r'\baadhaar\s+(?:number\s+)?(?:is\s+)?(\d{12})(?:\s|$)', caseSensitive: false);
  final aadhaarMatch = aadhaarRegex.firstMatch(text);
  if (aadhaarMatch != null) extracted['aadhaar'] = aadhaarMatch.group(1) ?? '';

  final abhaRegex = RegExp(r'\babha\s+(?:id\s+)?(?:is\s+)?([a-zA-Z0-9]+)(?:\s|$)', caseSensitive: false);
  final abhaMatch = abhaRegex.firstMatch(text);
  if (abhaMatch != null) extracted['abhaId'] = abhaMatch.group(1) ?? '';

  return extracted;
}
