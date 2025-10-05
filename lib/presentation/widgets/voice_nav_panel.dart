import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/voice_service_singleton.dart';
import '../../utils/colors.dart';

class VoiceNavPanel extends StatefulWidget {
  final ValueChanged<String> onExecute;
  final bool autoStart;
  const VoiceNavPanel({super.key, required this.onExecute, this.autoStart = false});

  @override
  State<VoiceNavPanel> createState() => _VoiceNavPanelState();
}

class _VoiceNavPanelState extends State<VoiceNavPanel> {
  bool _isListening = false;
  String _text = '';

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  Future<void> _start() async {
    setState(() => _isListening = true);
    await voiceService.init();
    await voiceService.startListening(
      onResult: (t) => setState(() => _text = t),
      onError: (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice error: $e')),
        );
        setState(() => _isListening = false);
      },
      localeId: 'en_IN',
    );
  }

  Future<void> _stop() async {
    await voiceService.stopListening();
    if (mounted) setState(() => _isListening = false);
  }

  void _execute() {
    final cmd = _text.trim();
    if (cmd.isNotEmpty) {
      widget.onExecute(cmd);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Executed: $cmd')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.terminal, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Voice Navigation', style: GoogleFonts.robotoMono(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isListening ? _stop : _start,
                  icon: Icon(_isListening ? Icons.stop : Icons.mic, size: 16),
                  label: Text(_isListening ? 'Stop' : 'Start'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _text.isEmpty ? null : _execute,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Execute'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 60, maxHeight: 120),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _text.isEmpty ? 'Listening...' : _text,
                  style: GoogleFonts.robotoMono(color: Colors.green, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
