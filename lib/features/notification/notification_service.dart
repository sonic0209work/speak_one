import 'dart:io';

class NotificationService {
  Future<void> playDing() async {
    await Process.run('paplay', [
      '/usr/share/sounds/freedesktop/stereo/complete.oga',
    ]);
  }

  Future<void> showMessage(String title, String body) async {
    await Process.run('notify-send', [
      '-a', 'Speak One',
      '-t', '5000',
      '-i', 'dialog-information',
      title,
      body,
    ]);
  }

  Future<void> show(String original, String translation) async {
    final summary = original.length > 60
        ? '${original.substring(0, 60)}…'
        : original;
    await Process.run('notify-send', [
      '-a', 'Speak One',
      '-t', '4000',
      '-i', 'audio-volume-high',
      summary,
      translation,
    ]);
  }
}
