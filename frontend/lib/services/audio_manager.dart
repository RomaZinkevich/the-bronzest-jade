import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:guess_who/constants/assets/audio_assets.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  AudioManager._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final Random _random = Random();

  String? _currentMusicPath;

  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = 0.5;
  double _sfxVolume = 0.7;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  Future<void> init() async {
    await initializeMusicPlayer();
    await intializeSfxPlayer();
  }

  Future<void> initializeMusicPlayer() async {
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
  }

  Future<void> intializeSfxPlayer() async {
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    await _sfxPlayer.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
  }

  Future<void> playBackgroundMusic(
    String assetPath, {
    Duration fadeDuration = const Duration(seconds: 2),
  }) async {
    if (!_musicEnabled) return;

    if (_currentMusicPath == assetPath) return;
    _currentMusicPath = assetPath;

    try {
      if (_musicPlayer.state == PlayerState.playing) {
        await _fadeVolume(
          _musicPlayer,
          _musicPlayer.volume,
          0,
          const Duration(milliseconds: 800),
        );
      }

      await _musicPlayer.stop();
      await _musicPlayer.setVolume(0);
      await _musicPlayer.play(AssetSource(assetPath));

      await _fadeVolume(_musicPlayer, 0, _musicVolume, fadeDuration);
    } catch (e) {
      debugPrint("Error playing background music: $e");
    }
  }

  Future<void> stopBackgroundMusic({
    Duration fadeDuration = const Duration(seconds: 2),
  }) async {
    try {
      await _fadeVolume(_musicPlayer, _musicPlayer.volume, 0, fadeDuration);
      await _musicPlayer.stop();
      _currentMusicPath = null;
    } catch (e) {
      debugPrint('Error stopping background music: $e');
    }
  }

  Future<void> _fadeVolume(
    AudioPlayer player,
    double fromVolume,
    double toVolume,
    Duration duration,
  ) async {
    const steps = 50;
    final stepDuration = duration.inMilliseconds ~/ steps;
    final volumeSteps = (toVolume - fromVolume) / steps;

    for (var i = 0; i < steps; i++) {
      final newVolume = fromVolume + (volumeSteps * i);
      await player.setVolume(newVolume.clamp(0.0, 1.0));
      await Future.delayed(Duration(milliseconds: stepDuration));
    }
  }

  Future<void> playSfx(String assetPath, {bool randomizedPitch = false}) async {
    if (!_sfxEnabled) return;

    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_sfxVolume);

      if (randomizedPitch) {
        final pitch = 0.8 + (_random.nextDouble() * 0.3);
        _sfxPlayer.setPlaybackRate(pitch);
      } else {
        _sfxPlayer.setPlaybackRate(1.0);
      }

      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint("Error playing sound effect: $e");
    }
  }

  Future<void> playSfxVariation(String basePath, int variations) async {
    final variation = _random.nextInt(variations) + 1;
    final path = basePath.replaceAll('.mp3', '$variation.mp3');
    await playSfx(path);
  }

  Future<void> playButtonClick() =>
      playSfx(AudioAssets.buttonClick, randomizedPitch: true);
  Future<void> playButtonClickVariation() =>
      playSfxVariation(AudioAssets.buttonClickVariation, 3);

  Future<void> playGameStart() => playSfx(AudioAssets.gameStartSfx);

  Future<void> playPopupSfx() => playSfx(AudioAssets.popUpSfx);

  Future<void> playAlertSfx() => playSfx(AudioAssets.alertSfx);

  Future<void> wrongAnswerSfx() => playSfx(AudioAssets.wrongAnswerSfx);

  Future<void> playGameWon() => playSfx(AudioAssets.gameWonSfx);
  Future<void> playGameOver() => playSfx(AudioAssets.gameOverSfx);

  Future<void> playGameLost() => playSfx(AudioAssets.wrongAnswerSfx);

  Future<void> playCardFlip() => playSfx("sounds/card_flip.mp3");
  Future<void> playCorrectGuess() => playSfx("sounds/correct.mp3");
  Future<void> playWrongGuess() => playSfx("sounds/wrong.mp3");
  Future<void> playQuestionAsked() => playSfx("sounds/question.mp3");

  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;

    if (!_musicEnabled) {
      await _musicPlayer.stop();
      await _musicPlayer.release();
    } else {
      if (_currentMusicPath != null) {
        await initializeMusicPlayer();
        await playBackgroundMusic(_currentMusicPath!);
      }
    }
  }

  Future<void> toggleSfx() async {
    _sfxEnabled = !_sfxEnabled;
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_musicVolume);
  }

  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
