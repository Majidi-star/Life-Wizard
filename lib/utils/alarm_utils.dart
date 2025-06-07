import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AlarmUtils {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isPlaying = false;

  /// Plays the alarm sound from assets
  static Future<void> playAlarm() async {
    if (_isPlaying) return;
    _isPlaying = true;
    try {
      await _audioPlayer.play(AssetSource('lib/assets/alarm.mp3'));
    } catch (e) {
      // ignore: avoid_print
      print('Error playing alarm: $e');
    } finally {
      _isPlaying = false;
    }
  }

  /// Speaks the given message using TTS
  static Future<void> speak(String message) async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.9);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(message);
    } catch (e) {
      // ignore: avoid_print
      print('Error with TTS: $e');
    }
  }

  /// Plays alarm and speaks the message
  static Future<void> playAlarmAndSpeak(String message) async {
    await playAlarm();
    await speak(message);
  }
}
