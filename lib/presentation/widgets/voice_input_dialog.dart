import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/voice_service_singleton.dart';
import '../../services/voice_extractor.dart';
import '../../utils/colors.dart';

class VoiceInputDialog extends StatefulWidget {
  const VoiceInputDialog({super.key});

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog> {
  String _realTimeText = '';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  Future<void> _startListening() async {
    setState(() => _isListening = true);
    await voiceService.init();
    voiceService.startListening(
      onResult: (command) {
        setState(() => _realTimeText = command);
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Voice error: $error')));
        setState(() => _isListening = false);
      },
      localeId: 'en_IN',
    );
  }

  Future<void> _stopListening() async {
    await voiceService.stopListening();
    setState(() => _isListening = false);
  }

  Map<String, String> _extractFeatures(String text) => extractPatientFeatures(text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      content: Container(
        height: 300,
        width: double.maxFinite,
        child: Column(
          children: [
            Text(
              'Voice Input Terminal',
              style: GoogleFonts.robotoMono(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.green, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _realTimeText.isEmpty ? 'Listening...' : _realTimeText,
                    style: GoogleFonts.robotoMono(
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isListening ? _stopListening : _startListening,
                    child: Text(_isListening ? 'Stop' : 'Start',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Map<String, String> features = _extractFeatures(_realTimeText);
                      Navigator.of(context).pop(features);
                    },
                    child: const Text('Extract',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
