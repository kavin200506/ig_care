import 'dart:async';
import 'package:flutter/material.dart';

class PatientVoiceDemo extends StatefulWidget {
  const PatientVoiceDemo({super.key});

  @override
  State<PatientVoiceDemo> createState() => _PatientVoiceDemoState();
}

class _PatientVoiceDemoState extends State<PatientVoiceDemo> {
  // 1) Demo transcript: adjust as needed for your showcase
  // Keep it natural so regex extraction looks realistic.
  static const String _demoTranscript = '''
My name is Blue and my age is 25. My gender is male. 
My phone number is 8610866523. 
My address is 43/L, Coimbatore, Tamil Nadu.
I have fever and cough since 2 days.
My blood group is B positive. 
My Aadhaar number is 1234 5678 9012.
  ''';

  // 2) Typing simulation state
  String _typed = '';
  int _cursor = 0;
  Timer? _timer;
  bool _isTyping = false;

  // 3) Form controllers
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  final _bloodGroupCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();

  // 4) Helpers
  void _startTyping() {
    if (_isTyping) return;
    setState(() {
      _typed = '';
      _cursor = 0;
      _isTyping = true;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 28), (t) {
      if (_cursor >= _demoTranscript.length) {
        t.cancel();
        setState(() => _isTyping = false);
        return;
      }
      setState(() {
        _typed += _demoTranscript[_cursor];
        _cursor++;
      });
    });
  }

  void _stopTyping() {
    _timer?.cancel();
    setState(() => _isTyping = false);
  }

  void _clearTyping() {
    _stopTyping();
    setState(() {
      _typed = '';
      _cursor = 0;
    });
  }

  void _resetForm() {
    _stopTyping();
    _typed = '';
    _cursor = 0;
    _nameCtrl.clear();
    _ageCtrl.clear();
    _genderCtrl.clear();
    _phoneCtrl.clear();
    _addressCtrl.clear();
    _symptomsCtrl.clear();
    _bloodGroupCtrl.clear();
    _aadhaarCtrl.clear();
    setState(() {});
  }

  // 5) Extraction logic (regex over the transcript)
  void _extractAndFill() {
    final text = _typed.trim().isEmpty ? _demoTranscript : _typed;

    final name = _matchFirst(
      text,
      RegExp(r'(?:my\s+name\s+is|name\s+is)\s+([A-Za-z][A-Za-z\s\-\.]+)', caseSensitive: false),
    );

    final age = _matchFirst(
      text,
      RegExp(r'(?:my\s+age\s+is|age\s+is|aged)\s+(\d{1,3})', caseSensitive: false),
    );

    final gender = _matchFirst(
      text,
      RegExp(r'(?:my\s+gender\s+is|gender\s+is|i\s+am)\s+(male|female|other)', caseSensitive: false),
    );

    final phone = _matchFirst(
      text,
      RegExp(r'(?:phone(?:\s+number)?\s*(?:is)?|mobile(?:\s+number)?\s*(?:is)?)\s*(\d{10})', caseSensitive: false),
    );

    final address = _matchFirst(
      text,
      RegExp(r'(?:my\s+address\s+is|address\s+is|address)\s+(.+?)(?:\.|$)', caseSensitive: false),
    );

    final symptoms = _matchFirst(
      text,
      RegExp(r'(?:symptoms\s*(?:are|:)|i\s+have|i\s+am\s+feeling)\s*([^\.]+)', caseSensitive: false),
    );

    final bloodGroup = _normalizeBloodGroup(
      _matchFirst(
        text,
        RegExp(
          r'(?:blood\s*(?:group|type)\s*(?:is)?\s*)(A|B|AB|O)\s*([+-]|positive|negative)?',
          caseSensitive: false,
        ),
      ),
    );

    final aadhaar = _formatAadhaar(
      _matchFirst(
        text,
        RegExp(r'\b(\d{4}\s?\d{4}\s?\d{4})\b'),
      ),
    );

    // Fill the form
    _nameCtrl.text = _titleCase(name ?? 'Blue');
    _ageCtrl.text = (age ?? '25');
    _genderCtrl.text = _titleCase(gender ?? 'Male');
    _phoneCtrl.text = phone ?? '8610866523';
    _addressCtrl.text = address ?? '43/L, Coimbatore, Tamil Nadu';
    _symptomsCtrl.text = symptoms ?? 'Fever and cough since 2 days';
    _bloodGroupCtrl.text = bloodGroup ?? 'B+';
    _aadhaarCtrl.text = aadhaar ?? '1234 5678 9012';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Details extracted and filled')),
    );
    setState(() {});
  }

  // 6) Small utilities
  String? _matchFirst(String text, RegExp re) {
    final m = re.firstMatch(text);
    if (m == null) return null;
    // Find the first non-null capturing group
    for (var i = 1; i <= m.groupCount; i++) {
      final g = m.group(i)?.trim();
      if (g != null && g.isNotEmpty) return g;
    }
    return null;
  }

  String _titleCase(String s) {
    return s
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
        .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1).toLowerCase() : ''))
        .join(' ');
  }

  String? _normalizeBloodGroup(String? input) {
    if (input == null) return null;
    // Normalize common forms like "B positive" -> "B+"
    final t = input.toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (t == 'APOSITIVE' || t == 'A+') return 'A+';
    if (t == 'ANEGATIVE' || t == 'A-') return 'A-';
    if (t == 'BPOSITIVE' || t == 'B+') return 'B+';
    if (t == 'BNEGATIVE' || t == 'B-') return 'B-';
    if (t == 'OPOSITIVE' || t == 'O+') return 'O+';
    if (t == 'ONEGATIVE' || t == 'O-') return 'O-';
    if (t == 'ABPOSITIVE' || t == 'AB+') return 'AB+';
    if (t == 'ABNEGATIVE' || t == 'AB-') return 'AB-';
    // Fallback if only group was captured
    if (t == 'A') return 'A';
    if (t == 'B') return 'B';
    if (t == 'O') return 'O';
    if (t == 'AB') return 'AB';
    return input;
  }

  String? _formatAadhaar(String? digits) {
    if (digits == null) return null;
    final only = digits.replaceAll(RegExp(r'\s+'), '');
    if (only.length == 12) {
      return '${only.substring(0, 4)} ${only.substring(4, 8)} ${only.substring(8, 12)}';
    }
    return digits;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _genderCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _symptomsCtrl.dispose();
    _bloodGroupCtrl.dispose();
    _aadhaarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Registration (Voice Prototype)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Voice transcript box with typing effect
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voice Transcript', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  constraints: const BoxConstraints(minHeight: 100),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _typed.isEmpty ? 'Tap Start to simulate voice typing…' : _typed,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _startTyping,
                      icon: const Icon(Icons.mic),
                      label: const Text('Start'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _isTyping ? _stopTyping : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _clearTyping,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _extractAndFill,
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Extract & Fill'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Registration form
          Text('Patient Details', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),

          _LabeledField(controller: _nameCtrl, label: 'Full Name', icon: Icons.person),
          _GridTwo(
            left: _LabeledField(controller: _ageCtrl, label: 'Age', icon: Icons.cake),
            right: _LabeledField(controller: _genderCtrl, label: 'Gender', icon: Icons.wc),
          ),
          _LabeledField(controller: _phoneCtrl, label: 'Phone', icon: Icons.phone),
          _LabeledField(controller: _addressCtrl, label: 'Address', icon: Icons.home),
          _LabeledField(
            controller: _symptomsCtrl,
            label: 'Symptoms',
            icon: Icons.sick,
            maxLines: 2,
          ),
          _GridTwo(
            left: _LabeledField(controller: _bloodGroupCtrl, label: 'Blood Group', icon: Icons.bloodtype),
            right: _LabeledField(controller: _aadhaarCtrl, label: 'Aadhaar', icon: Icons.badge),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Form'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  // For prototype, just show success
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Form submitted (prototype)')),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Submit (Demo)'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _TipCard(),
        ],
      ),
    );
  }
}

// Small UI helpers
class _LabeledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const _LabeledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        style: theme.textTheme.bodyLarge,
      ),
    );
  }
}

class _GridTwo extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _GridTwo({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb, color: Colors.amber),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Prototype mode: The voice is simulated with a static sentence and typing effect. '
              'Tap “Start” to see it type, then “Extract & Fill” to auto-populate the form.',
            ),
          ),
        ],
      ),
    );
  }
}
