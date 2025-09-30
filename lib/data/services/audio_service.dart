import 'package:audioplayers/audioplayers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playSuccess() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource(AppConstants.successSoundPath));
      Logger.audio('Success sound playing');
    } catch (e) {
      Logger.error('Success sound error: $e', tag: 'AUDIO');
    }
  }

  static Future<void> playFailed() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource(AppConstants.failedSoundPath));
      Logger.audio('Failed sound playing');
    } catch (e) {
      Logger.error('Failed sound error: $e', tag: 'AUDIO');
    }
  }

  static Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}