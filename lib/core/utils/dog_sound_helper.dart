import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class DogSoundHelper {
  static final AudioPlayer _player = AudioPlayer();
  static Uint8List? _cachedBarkWav;
  static Uint8List? _cachedHappyBarkWav;
  static Uint8List? _cachedAlertBarkWav;
  static bool _isAudioInitialized = false;

  static void _init() {
    if (_isAudioInitialized) return;
    _isAudioInitialized = true;
    _cachedBarkWav = _generateDogBarkWav(isDouble: true, baseFreq: 330, peakFreq: 750);
    _cachedHappyBarkWav = _generateDogBarkWav(isDouble: true, baseFreq: 380, peakFreq: 880);
    _cachedAlertBarkWav = _generateDogBarkWav(isDouble: false, baseFreq: 260, peakFreq: 620, volume: 1.0);
  }

  /// เล่นเสียงเห่าแบบสนุกสนาน (โฮ่ง! โฮ่ง!)
  static Future<void> playBark() async {
    _init();
    HapticFeedback.mediumImpact();
    try {
      if (_cachedBarkWav != null) {
        await _player.stop();
        await _player.play(BytesSource(_cachedBarkWav!));
      }
    } catch (_) {
      // Fallback to system sound and haptics if audio device unavailable
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// เล่นเสียงเห่าดีใจเมื่อบันทึกสำเร็จหรือได้รับรางวัล
  static Future<void> playHappyBark() async {
    _init();
    HapticFeedback.heavyImpact();
    try {
      if (_cachedHappyBarkWav != null) {
        await _player.stop();
        await _player.play(BytesSource(_cachedHappyBarkWav!));
      }
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// เล่นเสียงเห่าเตือนเมื่อใช้งบเกินหรือเตือนใจ
  static Future<void> playAlertBark() async {
    _init();
    HapticFeedback.vibrate();
    try {
      if (_cachedAlertBarkWav != null) {
        await _player.stop();
        await _player.play(BytesSource(_cachedAlertBarkWav!));
      }
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Synthesizer for natural dog bark PCM 16-bit WAV
  static Uint8List _generateDogBarkWav({
    int sampleRate = 44100,
    bool isDouble = true,
    double baseFreq = 330,
    double peakFreq = 750,
    double volume = 0.9,
  }) {
    final List<double> samples = [];

    void addWoof({
      required double bFreq,
      required double pFreq,
      double durationSec = 0.22,
      double vol = 0.85,
    }) {
      final totalSamples = (durationSec * sampleRate).toInt();
      final random = Random(1234);
      double phase = 0;

      for (int i = 0; i < totalSamples; i++) {
        final progress = i / totalSamples;

        // Frequency contour: quick steep rise (25ms) then natural resonant slide down
        double freq;
        if (progress < 0.22) {
          freq = bFreq + (pFreq - bFreq) * (progress / 0.22);
        } else {
          freq = pFreq - (pFreq - (bFreq * 0.75)) * ((progress - 0.22) / 0.78);
        }

        // Amplitude Envelope: attack + fast punch body + exponential decay
        double env;
        if (progress < 0.08) {
          env = progress / 0.08;
        } else {
          env = exp(-4.6 * (progress - 0.08));
        }

        phase += 2 * pi * freq / sampleRate;

        // Rich canine formant harmonics
        double val = sin(phase) * 0.52
                   + sin(phase * 2.0) * 0.28
                   + sin(phase * 3.0) * 0.14
                   + sin(phase * 0.5) * 0.16 // chest resonance
                   + (random.nextDouble() * 2 - 1) * 0.07 * (1.0 - progress); // breath

        val = (val * env * vol).clamp(-1.0, 1.0);
        // Soft tube saturation
        val = 1.4 * val - 0.4 * val * val * val;

        samples.add(val.clamp(-1.0, 1.0));
      }
    }

    // Bark 1
    addWoof(bFreq: baseFreq, pFreq: peakFreq, durationSec: 0.19, vol: volume * 0.85);

    if (isDouble) {
      // Pause
      final pauseSamples = (0.06 * sampleRate).toInt();
      for (int i = 0; i < pauseSamples; i++) {
        samples.add(0.0);
      }
      // Bark 2 (slightly higher energy)
      addWoof(bFreq: baseFreq * 1.08, pFreq: peakFreq * 1.12, durationSec: 0.23, vol: volume);
    }

    return _encodeWav(samples, sampleRate: sampleRate);
  }

  static Uint8List _encodeWav(List<double> samples, {int sampleRate = 44100}) {
    final numSamples = samples.length;
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    const blockAlign = numChannels * (bitsPerSample ~/ 8);
    final subChunk2Size = numSamples * numChannels * (bitsPerSample ~/ 8);
    final chunkSize = 36 + subChunk2Size;

    final byteData = ByteData(44 + subChunk2Size);

    // RIFF header
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, chunkSize, Endian.little);
    byteData.setUint8(8, 0x57);  // 'W'
    byteData.setUint8(9, 0x41);  // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // 'fmt ' chunk
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6D); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // PCM subchunk size
    byteData.setUint16(20, 1, Endian.little);  // PCM format
    byteData.setUint16(22, numChannels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, byteRate, Endian.little);
    byteData.setUint16(32, blockAlign, Endian.little);
    byteData.setUint16(34, bitsPerSample, Endian.little);

    // 'data' chunk
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, subChunk2Size, Endian.little);

    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final s = (samples[i] * 32767.0).toInt().clamp(-32768, 32767);
      byteData.setInt16(offset, s, Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }
}
