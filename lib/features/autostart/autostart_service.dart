import 'dart:io';

class AutostartService {
  static const _filename = 'speak_one.desktop';

  File _file() {
    final home = Platform.environment['HOME'] ?? '';
    return File('$home/.config/autostart/$_filename');
  }

  String _execPath() =>
      Platform.environment['APPIMAGE'] ?? Platform.resolvedExecutable;

  Future<bool> isEnabled() => _file().exists();

  Future<void> enable() async {
    final f = _file();
    await f.parent.create(recursive: true);
    await f.writeAsString(_desktop(_execPath()));
  }

  Future<void> disable() async {
    final f = _file();
    if (await f.exists()) await f.delete();
  }

  String _desktop(String exec) => '[Desktop Entry]\n'
      'Type=Application\n'
      'Name=Speak One\n'
      'Exec=$exec\n'
      'Icon=speak_one_idle\n'
      'Comment=Read selected text aloud with AI explanation\n'
      'Categories=Utility;Accessibility;\n'
      'StartupNotify=false\n'
      'X-GNOME-Autostart-enabled=true\n';
}
