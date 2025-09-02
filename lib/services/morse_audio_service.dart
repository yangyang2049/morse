import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class MorseAudioService {
  static final MorseAudioService _instance = MorseAudioService._internal();
  factory MorseAudioService() => _instance;
  MorseAudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  // 摩斯电码播放参数
  static const int _dotDuration = 200; // 点的持续时间（毫秒）
  static const int _dashDuration = 600; // 划的持续时间（毫秒）
  static const int _pauseDuration = 200; // 点划之间的间隔
  static const int _letterPauseDuration = 600; // 字母之间的间隔
  static const int _wordPauseDuration = 1400; // 单词之间的间隔

  bool get isPlaying => _isPlaying;

  /// 播放摩斯电码
  Future<void> playMorseCode(String morseCode) async {
    if (_isPlaying) {
      await stop();
    }

    _isPlaying = true;

    try {
      // 将摩斯电码字符串转换为播放序列
      final playSequence = _parseMorseCode(morseCode);

      for (final element in playSequence) {
        if (!_isPlaying) break; // 如果停止播放，退出循环

        switch (element.type) {
          case MorseElementType.dot:
            await _playTone(_dotDuration);
            break;
          case MorseElementType.dash:
            await _playTone(_dashDuration);
            break;
          case MorseElementType.pause:
            await _pause(element.duration);
            break;
        }
      }
    } catch (e) {
      // 播放摩斯电码时出错，静默处理
    } finally {
      _isPlaying = false;
    }
  }

  /// 停止播放
  Future<void> stop() async {
    _isPlaying = false;
    await _audioPlayer.stop();
  }

  /// 播放音调
  Future<void> _playTone(int duration) async {
    try {
      // 使用系统声音和震动来模拟摩斯电码
      SystemSound.play(SystemSoundType.click);

      // 根据持续时间提供不同的震动反馈
      if (duration == _dotDuration) {
        Vibration.vibrate(duration: 50); // 点：短震动
      } else {
        Vibration.vibrate(duration: 100); // 划：长震动
      }

      await Future.delayed(Duration(milliseconds: duration));
      await Future.delayed(Duration(milliseconds: _pauseDuration));
    } catch (e) {
      // 如果震动不可用，仅使用延时
      await Future.delayed(Duration(milliseconds: duration + _pauseDuration));
    }
  }

  /// 暂停
  Future<void> _pause(int duration) async {
    await Future.delayed(Duration(milliseconds: duration));
  }

  /// 解析摩斯电码字符串为播放序列
  List<MorseElement> _parseMorseCode(String morseCode) {
    final List<MorseElement> sequence = [];

    // 清理输入：替换中文点为英文点
    final cleanCode = morseCode.replaceAll('·', '.');

    for (int i = 0; i < cleanCode.length; i++) {
      final char = cleanCode[i];

      switch (char) {
        case '.':
          sequence.add(MorseElement(MorseElementType.dot, _dotDuration));
          break;
        case '-':
          sequence.add(MorseElement(MorseElementType.dash, _dashDuration));
          break;
        case ' ':
          // 字母间隔
          sequence
              .add(MorseElement(MorseElementType.pause, _letterPauseDuration));
          break;
        case '/':
          // 单词间隔
          sequence
              .add(MorseElement(MorseElementType.pause, _wordPauseDuration));
          break;
      }
    }

    return sequence;
  }

  /// 释放资源
  void dispose() {
    _audioPlayer.dispose();
  }
}

/// 摩斯电码元素类型
enum MorseElementType {
  dot, // 点
  dash, // 划
  pause, // 暂停
}

/// 摩斯电码播放元素
class MorseElement {
  final MorseElementType type;
  final int duration;

  MorseElement(this.type, this.duration);
}
