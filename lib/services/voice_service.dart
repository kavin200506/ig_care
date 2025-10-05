import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  // Speech-to-text instance
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechInitialized = false;
  bool _isListening = false;
  String _lastWords = '';

  // Optional: Text-to-speech instance
  final FlutterTts _tts = FlutterTts();

  // Initialization
  Future<void> init() async {
    if (!_speechInitialized) {
      _speechInitialized = await _speech.initialize();
    }
  }

  // Request microphone permission if required
  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  // Start listening with a callback for recognized text
  Future<void> startListening({
    required Function(String command) onResult,
    Function(String? error)? onError,
    String localeId = 'en_IN',
  }) async {
    bool micOk = await _ensureMicPermission();
    if (!micOk) {
      if (onError != null) onError("Microphone permission denied.");
      return;
    }

    if (!_speechInitialized) await init();
    if (!_speech.isAvailable) {
      if (onError != null) onError("Speech recognition not available.");
      return;
    }

    _isListening = true;
    _speech.listen(
      localeId: localeId,
      onResult: (result) {
        // Stream partial and final results for real-time UI updates
        _lastWords = result.recognizedWords;
        onResult(_lastWords);
      },
      listenFor: const Duration(seconds: 20),
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  // Stop listening
  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  // Cancel recognition
  Future<void> cancelListening() async {
    _isListening = false;
    await _speech.cancel();
  }

  bool get isListening => _isListening;

  // Optional: Speak feedback text to user
  Future speak(String text) async {
    await _tts.speak(text);
  }

  // Optionally: Stop speech
  Future stopSpeaking() async {
    await _tts.stop();
  }
}
