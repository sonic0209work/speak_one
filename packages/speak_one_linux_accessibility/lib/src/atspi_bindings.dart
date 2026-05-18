import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'text_selection_event.dart';

// ---------------------------------------------------------------------------
// Opaque C types
// ---------------------------------------------------------------------------
final class AtspiAccessible extends Opaque {}
final class AtspiEventListener extends Opaque {}
final class AtspiText extends Opaque {}
final class GError extends Opaque {}
final class GMainContext extends Opaque {}

// ---------------------------------------------------------------------------
// AtspiEvent — only the fields we read (offsets on LP64)
// type    : Pointer<Utf8>  @ offset 0
// source  : Pointer<AtspiAccessible> @ offset 8
// ---------------------------------------------------------------------------
final class AtspiEvent extends Struct {
  external Pointer<Utf8> type;
  external Pointer<AtspiAccessible> source;
  // remaining fields omitted — we never read them
  @Int64()
  external int _pad0;
  @Int64()
  external int _pad1;
  @Int64()
  external int _pad2;
  @Int64()
  external int _pad3;
}

// ---------------------------------------------------------------------------
// AtspiRange (returned by atspi_text_get_selection)
// ---------------------------------------------------------------------------
final class AtspiRange extends Struct {
  @Int32()
  external int startOffset;
  @Int32()
  external int endOffset;
}

// ---------------------------------------------------------------------------
// AtspiRect (returned by atspi_text_get_range_extents)
// ---------------------------------------------------------------------------
final class AtspiRect extends Struct {
  @Int32()
  external int x;
  @Int32()
  external int y;
  @Int32()
  external int width;
  @Int32()
  external int height;
}

// ---------------------------------------------------------------------------
// Callback typedefs
// ---------------------------------------------------------------------------
typedef _AtspiEventCbNative = Void Function(
    Pointer<AtspiEvent> event, Pointer<Void> userData);
typedef _AtspiEventCb = void Function(
    Pointer<AtspiEvent> event, Pointer<Void> userData);

typedef _DestroyNotifyNative = Void Function(Pointer<Void> data);
typedef _DestroyNotify = void Function(Pointer<Void> data);

// ---------------------------------------------------------------------------
// Native function typedefs — atspi
// ---------------------------------------------------------------------------
typedef _AtspiInitNative = Int32 Function();
typedef _AtspiInit = int Function();

typedef _AtspiEventListenerNewNative = Pointer<AtspiEventListener> Function(
    Pointer<NativeFunction<_AtspiEventCbNative>>,
    Pointer<Void>,
    Pointer<NativeFunction<_DestroyNotifyNative>>);
typedef _AtspiEventListenerNew = Pointer<AtspiEventListener> Function(
    Pointer<NativeFunction<_AtspiEventCbNative>>,
    Pointer<Void>,
    Pointer<NativeFunction<_DestroyNotifyNative>>);

typedef _AtspiEventListenerRegisterNative = Bool Function(
    Pointer<AtspiEventListener>, Pointer<Utf8>, Pointer<Pointer<GError>>);
typedef _AtspiEventListenerRegister = bool Function(
    Pointer<AtspiEventListener>, Pointer<Utf8>, Pointer<Pointer<GError>>);

typedef _AtspiAccessibleGetTextIfaceNative = Pointer<AtspiText> Function(
    Pointer<AtspiAccessible>);
typedef _AtspiAccessibleGetTextIface = Pointer<AtspiText> Function(
    Pointer<AtspiAccessible>);

typedef _AtspiTextGetSelectionNative = Pointer<AtspiRange> Function(
    Pointer<AtspiText>, Int32, Pointer<Pointer<GError>>);
typedef _AtspiTextGetSelection = Pointer<AtspiRange> Function(
    Pointer<AtspiText>, int, Pointer<Pointer<GError>>);

typedef _AtspiTextGetTextNative = Pointer<Utf8> Function(
    Pointer<AtspiText>, Int32, Int32, Pointer<Pointer<GError>>);
typedef _AtspiTextGetText = Pointer<Utf8> Function(
    Pointer<AtspiText>, int, int, Pointer<Pointer<GError>>);

typedef _AtspiTextGetRangeExtentsNative = Void Function(
    Pointer<AtspiText>, Int32, Int32, Int32, Pointer<AtspiRect>, Pointer<Pointer<GError>>);
typedef _AtspiTextGetRangeExtents = void Function(
    Pointer<AtspiText>, int, int, int, Pointer<AtspiRect>, Pointer<Pointer<GError>>);

typedef _AtspiTextGetNSelectionsNative = Int32 Function(
    Pointer<AtspiText>, Pointer<Pointer<GError>>);
typedef _AtspiTextGetNSelections = int Function(
    Pointer<AtspiText>, Pointer<Pointer<GError>>);

// ---------------------------------------------------------------------------
// Native function typedefs — glib
// ---------------------------------------------------------------------------
typedef _GMainContextIterationNative = Bool Function(Pointer<GMainContext>, Bool);
typedef _GMainContextIteration = bool Function(Pointer<GMainContext>, bool);

typedef _GFreeNative = Void Function(Pointer<Void>);
typedef _GFree = void Function(Pointer<Void>);

// ---------------------------------------------------------------------------
// Isolate entry point message
// ---------------------------------------------------------------------------
class _IsolateSetup {
  const _IsolateSetup(this.sendPort);
  final SendPort sendPort;
}

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Spawns an isolate that listens for AT-SPI2 text-selection events via
/// libatspi-2.0.so, returning a broadcast [Stream] of [TextSelectionEvent].
///
/// Throws [UnsupportedError] if libatspi-2.0 cannot be loaded.
Stream<TextSelectionEvent> listenAtspi() {
  final controller = StreamController<TextSelectionEvent>.broadcast();
  final receivePort = ReceivePort();

  receivePort.listen((message) {
    if (message is TextSelectionEvent) {
      controller.add(message);
    } else if (message is String && message.startsWith('ERROR:')) {
      controller.addError(Exception(message.substring(6)));
    }
  });

  Isolate.spawn(_atspiIsolate, _IsolateSetup(receivePort.sendPort))
      .catchError((Object e) {
    controller.addError(e);
    controller.close();
    return Isolate.current;
  });

  return controller.stream;
}

// ---------------------------------------------------------------------------
// Isolate body
// ---------------------------------------------------------------------------
void _atspiIsolate(_IsolateSetup setup) {
  final port = setup.sendPort;

  late final DynamicLibrary atspiLib;
  late final DynamicLibrary glibLib;

  try {
    atspiLib = DynamicLibrary.open('libatspi-2.0.so.0');
    glibLib = DynamicLibrary.open('libglib-2.0.so.0');
  } catch (e) {
    port.send('ERROR:Failed to load libatspi-2.0.so.0 or libglib-2.0.so.0: $e');
    return;
  }

  // Bind functions
  final atspiInit = atspiLib
      .lookupFunction<_AtspiInitNative, _AtspiInit>('atspi_init');
  final eventListenerNew = atspiLib.lookupFunction<
      _AtspiEventListenerNewNative,
      _AtspiEventListenerNew>('atspi_event_listener_new');
  final eventListenerRegister = atspiLib.lookupFunction<
      _AtspiEventListenerRegisterNative,
      _AtspiEventListenerRegister>('atspi_event_listener_register');
  final getTextIface = atspiLib.lookupFunction<
      _AtspiAccessibleGetTextIfaceNative,
      _AtspiAccessibleGetTextIface>('atspi_accessible_get_text_iface');
  final getNSelections = atspiLib.lookupFunction<
      _AtspiTextGetNSelectionsNative,
      _AtspiTextGetNSelections>('atspi_text_get_n_selections');
  final getSelection = atspiLib.lookupFunction<
      _AtspiTextGetSelectionNative,
      _AtspiTextGetSelection>('atspi_text_get_selection');
  final getText = atspiLib.lookupFunction<
      _AtspiTextGetTextNative,
      _AtspiTextGetText>('atspi_text_get_text');
  final getRangeExtents = atspiLib.lookupFunction<
      _AtspiTextGetRangeExtentsNative,
      _AtspiTextGetRangeExtents>('atspi_text_get_range_extents');
  final gMainContextIteration = glibLib.lookupFunction<
      _GMainContextIterationNative,
      _GMainContextIteration>('g_main_context_iteration');
  final gFree = glibLib
      .lookupFunction<_GFreeNative, _GFree>('g_free');

  atspiInit();

  // Callback: called by GLib when AT-SPI2 fires object:text-selection-changed
  void onEvent(Pointer<AtspiEvent> event, Pointer<Void> _) {
    final accessible = event.ref.source;
    if (accessible == nullptr) return;

    final textIface = getTextIface(accessible);
    if (textIface == nullptr) return;

    // Allocate a fresh errorPtr for each AT-SPI2 call.
    // AT-SPI2 asserts *error == NULL on entry; reusing a dirty pointer aborts the process.
    final ep1 = calloc<Pointer<GError>>();
    final nSel = getNSelections(textIface, ep1);
    calloc.free(ep1);
    if (nSel <= 0) return;

    final ep2 = calloc<Pointer<GError>>();
    final range = getSelection(textIface, 0, ep2);
    calloc.free(ep2);
    if (range == nullptr) return;

    final start = range.ref.startOffset;
    final end = range.ref.endOffset;
    gFree(range.cast()); // AtspiRange* is GLib-allocated; must use g_free, not calloc.free

    if (end <= start) return;

    final ep3 = calloc<Pointer<GError>>();
    final textPtr = getText(textIface, start, end, ep3);
    calloc.free(ep3);
    if (textPtr == nullptr) return;

    final text = textPtr.toDartString().trim();
    gFree(textPtr.cast());

    if (text.isEmpty) return;

    final rect = calloc<AtspiRect>();
    final ep4 = calloc<Pointer<GError>>();
    getRangeExtents(textIface, start, end, 0, rect, ep4);
    calloc.free(ep4);
    final bounds = SelectionRect(
      rect.ref.x.toDouble(),
      rect.ref.y.toDouble(),
      rect.ref.width.toDouble(),
      rect.ref.height.toDouble(),
    );
    // Approximate cursor as the trailing corner of the selection bounding box
    // (Wayland does not expose the raw pointer position via AT-SPI).
    final cursorX = bounds.width > 0 ? bounds.left + bounds.width : null;
    final cursorY = bounds.height > 0 ? bounds.top + bounds.height : null;
    calloc.free(rect);

    port.send(TextSelectionEvent(
      text: text,
      bounds: bounds,
      cursorX: cursorX,
      cursorY: cursorY,
      timestamp: DateTime.now().toUtc(),
    ));
  }

  // Register event listener
  final callback = NativeCallable<_AtspiEventCbNative>.isolateLocal(onEvent);

  final listener = eventListenerNew(callback.nativeFunction, nullptr, nullptr);
  if (listener == nullptr) {
    port.send('ERROR:atspi_event_listener_new returned null');
    callback.close();
    return;
  }

  final eventTypeStr = 'object:text-selection-changed'.toNativeUtf8();
  final regErrorPtr = calloc<Pointer<GError>>();
  final registered = eventListenerRegister(listener, eventTypeStr, regErrorPtr);
  calloc.free(eventTypeStr);
  calloc.free(regErrorPtr);
  if (!registered) {
    port.send('ERROR:atspi_event_listener_register failed — AT-SPI2 bus may not be available');
    callback.close();
    return;
  }

  // Pump GLib main context every 10 ms — processes AT-SPI2 events without
  // blocking the Dart isolate indefinitely.
  Timer.periodic(const Duration(milliseconds: 10), (_) {
    gMainContextIteration(nullptr, false);
  });
}
