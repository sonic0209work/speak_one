final class SelectionRect {
  const SelectionRect(this.left, this.top, this.width, this.height);
  const SelectionRect.zero() : this(0, 0, 0, 0);

  final double left;
  final double top;
  final double width;
  final double height;

  @override
  String toString() => 'Rect(${left.toInt()}, ${top.toInt()}, ${width.toInt()}x${height.toInt()})';
}

final class TextSelectionEvent {
  const TextSelectionEvent({
    required this.text,
    required this.bounds,
    this.cursorX,
    this.cursorY,
    required this.timestamp,
  });

  final String text;
  final SelectionRect bounds;
  /// Mouse cursor X coordinate at the moment selection completed (screen coords).
  /// Null if not available (e.g. Wayland without pointer query support).
  final double? cursorX;
  /// Mouse cursor Y coordinate at the moment selection completed (screen coords).
  final double? cursorY;
  final DateTime timestamp;

  factory TextSelectionEvent.fromJson(Map<String, dynamic> json) {
    return TextSelectionEvent(
      text: json['text'] as String,
      bounds: SelectionRect(
        (json['left'] as num).toDouble(),
        (json['top'] as num).toDouble(),
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      cursorX: (json['cursorX'] as num?)?.toDouble(),
      cursorY: (json['cursorY'] as num?)?.toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'left': bounds.left,
        'top': bounds.top,
        'width': bounds.width,
        'height': bounds.height,
        if (cursorX != null) 'cursorX': cursorX,
        if (cursorY != null) 'cursorY': cursorY,
        'timestamp': timestamp.toUtc().toIso8601String(),
      };

  @override
  String toString() =>
      'TextSelectionEvent(text: "$text", bounds: $bounds, cursor: ($cursorX, $cursorY))';
}
