import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'text_selection_event.dart';

// ---------------------------------------------------------------------------
// Opaque C types
// ---------------------------------------------------------------------------
final class XcbConnection extends Opaque {}
final class XcbGenericEvent extends Struct {
  @Uint8()
  external int responseType;
  @Uint8()
  external int pad0;
  @Uint16()
  external int sequence;
  @Uint32()
  external int pad;
  @Uint32()
  external int fullSequence;
}

// XcbInternAtomReply
final class XcbInternAtomReply extends Struct {
  @Uint8()
  external int responseType;
  @Uint8()
  external int pad0;
  @Uint16()
  external int sequence;
  @Uint32()
  external int length;
  @Uint32()
  external int atom;
}

// XcbGetPropertyReply
final class XcbGetPropertyReply extends Struct {
  @Uint8()
  external int responseType;
  @Uint8()
  external int format;
  @Uint16()
  external int sequence;
  @Uint32()
  external int length;
  @Uint32()
  external int type;
  @Uint32()
  external int bytesAfter;
  @Uint32()
  external int valueLen;
}

// xcb_query_extension_reply_t
final class XcbQueryExtensionReply extends Struct {
  @Uint8()
  external int responseType;
  @Uint8()
  external int pad0;
  @Uint16()
  external int sequence;
  @Uint32()
  external int length;
  @Uint8()
  external int present;
  @Uint8()
  external int majorOpcode;
  @Uint8()
  external int firstEvent;
  @Uint8()
  external int firstError;
}

// XFixes SelectionNotify event (event code = xfixesFirstEvent + 0)
final class XcbXfixesSelectionNotifyEvent extends Struct {
  @Uint8()
  external int responseType;
  @Uint8()
  external int subtype;
  @Uint16()
  external int sequence;
  @Uint32()
  external int window;
  @Uint32()
  external int owner;
  @Uint32()
  external int selection;
  @Uint32()
  external int timestamp;
  @Uint32()
  external int selectionTimestamp;
}

// ---------------------------------------------------------------------------
// Native typedefs — xcb
// ---------------------------------------------------------------------------
typedef _XcbConnectNative = Pointer<XcbConnection> Function(
    Pointer<Utf8>, Pointer<Int32>);
typedef _XcbConnect = Pointer<XcbConnection> Function(
    Pointer<Utf8>, Pointer<Int32>);

typedef _XcbDisconnectNative = Void Function(Pointer<XcbConnection>);
typedef _XcbDisconnect = void Function(Pointer<XcbConnection>);

typedef _XcbGenerateIdNative = Uint32 Function(Pointer<XcbConnection>);
typedef _XcbGenerateId = int Function(Pointer<XcbConnection>);

typedef _XcbGetSetupNative = Pointer<Void> Function(Pointer<XcbConnection>);
typedef _XcbGetSetup = Pointer<Void> Function(Pointer<XcbConnection>);

typedef _XcbSetupRootsIteratorNative = _XcbScreenIterator Function(Pointer<Void>);

final class _XcbScreenIterator extends Struct {
  external Pointer<_XcbScreen> data;
  @Int32()
  external int rem;
  @Int32()
  external int index;
}

final class _XcbScreen extends Struct {
  @Uint32()
  external int root;
  // other fields omitted
  @Uint32()
  external int defaultColormap;
  @Uint32()
  external int whitePixel;
  @Uint32()
  external int blackPixel;
  @Uint32()
  external int currentInputMasks;
  @Uint16()
  external int widthInPixels;
  @Uint16()
  external int heightInPixels;
  @Uint16()
  external int widthInMillimeters;
  @Uint16()
  external int heightInMillimeters;
  @Uint16()
  external int minInstalledMaps;
  @Uint16()
  external int maxInstalledMaps;
  @Uint32()
  external int rootVisual;
  @Uint8()
  external int backingStores;
  @Uint8()
  external int saveUnders;
  @Uint8()
  external int rootDepth;
  @Uint8()
  external int allowedDepthsLen;
}

typedef _XcbInternAtomNative = Uint32 Function(
    Pointer<XcbConnection>, Uint8, Uint16, Pointer<Utf8>);
typedef _XcbInternAtom = int Function(
    Pointer<XcbConnection>, int, int, Pointer<Utf8>);

typedef _XcbInternAtomReplyNative = Pointer<XcbInternAtomReply> Function(
    Pointer<XcbConnection>, Uint32, Pointer<Void>);
typedef _XcbInternAtomReply = Pointer<XcbInternAtomReply> Function(
    Pointer<XcbConnection>, int, Pointer<Void>);

typedef _XcbCreateWindowNative = Uint32 Function(
    Pointer<XcbConnection>, Uint8, Uint32, Uint32,
    Int16, Int16, Uint16, Uint16, Uint16, Uint16, Uint32, Uint32, Pointer<Void>);
typedef _XcbCreateWindow = int Function(
    Pointer<XcbConnection>, int, int, int,
    int, int, int, int, int, int, int, int, Pointer<Void>);

typedef _XcbFlushNative = Int32 Function(Pointer<XcbConnection>);
typedef _XcbFlush = int Function(Pointer<XcbConnection>);

typedef _XcbWaitForEventNative = Pointer<XcbGenericEvent> Function(
    Pointer<XcbConnection>);
typedef _XcbWaitForEvent = Pointer<XcbGenericEvent> Function(
    Pointer<XcbConnection>);

typedef _XcbGetPropertyNative = Uint32 Function(
    Pointer<XcbConnection>, Uint8, Uint32, Uint32, Uint32, Uint32, Uint32);
typedef _XcbGetProperty = int Function(
    Pointer<XcbConnection>, int, int, int, int, int, int);

typedef _XcbGetPropertyReplyFn = Pointer<XcbGetPropertyReply> Function(
    Pointer<XcbConnection>, int, Pointer<Void>);

typedef _XcbGetPropertyValueNative = Pointer<Void> Function(
    Pointer<XcbGetPropertyReply>);
typedef _XcbGetPropertyValue = Pointer<Void> Function(
    Pointer<XcbGetPropertyReply>);

typedef _XcbGetPropertyValueLengthNative = Int32 Function(
    Pointer<XcbGetPropertyReply>);
typedef _XcbGetPropertyValueLength = int Function(
    Pointer<XcbGetPropertyReply>);

typedef _XcbConvertSelectionNative = Uint32 Function(
    Pointer<XcbConnection>, Uint32, Uint32, Uint32, Uint32, Uint32);
typedef _XcbConvertSelection = int Function(
    Pointer<XcbConnection>, int, int, int, int, int);

typedef _XcbQueryExtensionNative = Uint32 Function(
    Pointer<XcbConnection>, Uint16, Pointer<Utf8>);
typedef _XcbQueryExtension = int Function(
    Pointer<XcbConnection>, int, Pointer<Utf8>);

typedef _XcbQueryExtensionReplyNative = Pointer<XcbQueryExtensionReply> Function(
    Pointer<XcbConnection>, Uint32, Pointer<Void>);
typedef _XcbQueryExtensionReplyFn = Pointer<XcbQueryExtensionReply> Function(
    Pointer<XcbConnection>, int, Pointer<Void>);

// XFixes
typedef _XcbXfixesQueryVersionNative = Uint32 Function(
    Pointer<XcbConnection>, Uint32, Uint32);
typedef _XcbXfixesQueryVersion = int Function(
    Pointer<XcbConnection>, int, int);

typedef _XcbXfixesSelectSelectionInputNative = Uint32 Function(
    Pointer<XcbConnection>, Uint32, Uint32, Uint32);
typedef _XcbXfixesSelectSelectionInput = int Function(
    Pointer<XcbConnection>, int, int, int);

// ---------------------------------------------------------------------------
// Isolate message
// ---------------------------------------------------------------------------
class _IsolateSetup {
  const _IsolateSetup(this.sendPort);
  final SendPort sendPort;
}

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Spawns an isolate that listens for X11 PRIMARY selection changes via
/// libxcb + libxcb-xfixes, returning a broadcast [Stream] of [TextSelectionEvent].
Stream<TextSelectionEvent> listenX11() {
  final controller = StreamController<TextSelectionEvent>.broadcast();
  final receivePort = ReceivePort();

  receivePort.listen((message) {
    if (message is TextSelectionEvent) {
      controller.add(message);
    } else if (message is String && message.startsWith('ERROR:')) {
      controller.addError(Exception(message.substring(6)));
    }
  });

  Isolate.spawn(_x11Isolate, _IsolateSetup(receivePort.sendPort))
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
void _x11Isolate(_IsolateSetup setup) {
  final port = setup.sendPort;

  late final DynamicLibrary xcbLib;
  late final DynamicLibrary xfixesLib;

  try {
    xcbLib = DynamicLibrary.open('libxcb.so.1');
    xfixesLib = DynamicLibrary.open('libxcb-xfixes.so.0');
  } catch (e) {
    port.send('ERROR:Failed to load libxcb: $e');
    return;
  }

  // Bind xcb functions
  final xcbConnect = xcbLib
      .lookupFunction<_XcbConnectNative, _XcbConnect>('xcb_connect');
  final xcbDisconnect = xcbLib
      .lookupFunction<_XcbDisconnectNative, _XcbDisconnect>('xcb_disconnect');
  final xcbGenerateId = xcbLib
      .lookupFunction<_XcbGenerateIdNative, _XcbGenerateId>('xcb_generate_id');
  final xcbFlush =
      xcbLib.lookupFunction<_XcbFlushNative, _XcbFlush>('xcb_flush');
  final xcbWaitForEvent = xcbLib.lookupFunction<_XcbWaitForEventNative,
      _XcbWaitForEvent>('xcb_wait_for_event');
  final xcbInternAtomCookie = xcbLib
      .lookupFunction<_XcbInternAtomNative, _XcbInternAtom>('xcb_intern_atom');
  final xcbInternAtomReplyFn = xcbLib.lookupFunction<
      _XcbInternAtomReplyNative,
      _XcbInternAtomReply>('xcb_intern_atom_reply');
  final xcbConvertSelection = xcbLib.lookupFunction<
      _XcbConvertSelectionNative,
      _XcbConvertSelection>('xcb_convert_selection');
  final xcbGetProperty = xcbLib
      .lookupFunction<_XcbGetPropertyNative, _XcbGetProperty>('xcb_get_property');
  final xcbGetPropertyReplyFn = xcbLib.lookupFunction<
      Pointer<XcbGetPropertyReply> Function(Pointer<XcbConnection>, Uint32, Pointer<Void>),
      _XcbGetPropertyReplyFn>('xcb_get_property_reply');
  final xcbGetPropertyValue = xcbLib.lookupFunction<
      _XcbGetPropertyValueNative,
      _XcbGetPropertyValue>('xcb_get_property_value');
  final xcbGetPropertyValueLength = xcbLib.lookupFunction<
      _XcbGetPropertyValueLengthNative,
      _XcbGetPropertyValueLength>('xcb_get_property_value_length');
  final xcbQueryExtension = xcbLib.lookupFunction<
      _XcbQueryExtensionNative,
      _XcbQueryExtension>('xcb_query_extension');
  final xcbQueryExtensionReplyFn = xcbLib.lookupFunction<
      _XcbQueryExtensionReplyNative,
      _XcbQueryExtensionReplyFn>('xcb_query_extension_reply');
  final xcbGetSetup =
      xcbLib.lookupFunction<_XcbGetSetupNative, _XcbGetSetup>('xcb_get_setup');
  final xcbSetupRootsIterator = xcbLib.lookupFunction<
      _XcbSetupRootsIteratorNative,
      _XcbSetupRootsIteratorNative>('xcb_setup_roots_iterator');
  final xcbCreateWindow = xcbLib.lookupFunction<
      _XcbCreateWindowNative,
      _XcbCreateWindow>('xcb_create_window');

  // Bind xfixes functions
  final xfixesQueryVersion = xfixesLib.lookupFunction<
      _XcbXfixesQueryVersionNative,
      _XcbXfixesQueryVersion>('xcb_xfixes_query_version');
  final xfixesSelectSelectionInput = xfixesLib.lookupFunction<
      _XcbXfixesSelectSelectionInputNative,
      _XcbXfixesSelectSelectionInput>('xcb_xfixes_select_selection_input');

  final screenNumPtr = calloc<Int32>();
  final conn = xcbConnect(nullptr, screenNumPtr);
  calloc.free(screenNumPtr);

  if (conn == nullptr) {
    port.send('ERROR:xcb_connect failed');
    return;
  }

  // Resolve XFixes first_event — varies by system based on extension load order
  final xfixesNamePtr = 'XFIXES'.toNativeUtf8();
  final extCookie = xcbQueryExtension(conn, 6, xfixesNamePtr);
  calloc.free(xfixesNamePtr);
  final extReply = xcbQueryExtensionReplyFn(conn, extCookie, nullptr);
  if (extReply == nullptr || extReply.ref.present == 0) {
    port.send('ERROR:XFixes extension not available on this X11 server');
    xcbDisconnect(conn);
    return;
  }
  final xfixesFirstEvent = extReply.ref.firstEvent;
  calloc.free(extReply);

  // Initialize XFixes (required before xcb_xfixes_select_selection_input)
  xfixesQueryVersion(conn, 5, 0);
  xcbFlush(conn);

  // Intern atoms
  int internAtom(String name) {
    final namePtr = name.toNativeUtf8();
    final cookie = xcbInternAtomCookie(conn, 0, name.length, namePtr);
    calloc.free(namePtr);
    final reply = xcbInternAtomReplyFn(conn, cookie, nullptr);
    if (reply == nullptr) return 0;
    final atom = reply.ref.atom;
    calloc.free(reply);
    return atom;
  }

  final primaryAtom = internAtom('PRIMARY');
  final utf8StringAtom = internAtom('UTF8_STRING');
  final targetPropertyAtom = internAtom('SPEAK_ONE_SELECTION');

  if (primaryAtom == 0 || utf8StringAtom == 0) {
    port.send('ERROR:Failed to intern required X11 atoms');
    xcbDisconnect(conn);
    return;
  }

  // Create a helper INPUT_ONLY window to receive SelectionNotify events
  final winId = xcbGenerateId(conn);
  final xcbSetup = xcbGetSetup(conn);
  final iter = xcbSetupRootsIterator(xcbSetup);
  final rootWindow = iter.data.ref.root;
  // XCB_WINDOW_CLASS_INPUT_ONLY = 2; depth 0 = CopyFromParent
  xcbCreateWindow(conn, 0, winId, rootWindow, 0, 0, 1, 1, 0, 2, 0, 0, nullptr);

  // Subscribe to PRIMARY selection changes via XFixes
  // XCB_XFIXES_SELECTION_EVENT_MASK_SET_SELECTION_OWNER = 1
  xfixesSelectSelectionInput(conn, winId, primaryAtom, 1);
  xcbFlush(conn);

  // Event loop — xcb_wait_for_event is blocking; this is fine in a Dart Isolate
  while (true) {
    final event = xcbWaitForEvent(conn);
    if (event == nullptr) break; // connection error

    final eventType = event.ref.responseType & 0x7F;

    // XCB_XFIXES_SELECTION_NOTIFY = xfixesFirstEvent + 0
    if (eventType == xfixesFirstEvent) {
      final selEvent = event.cast<XcbXfixesSelectionNotifyEvent>();
      if (selEvent.ref.selection == primaryAtom) {
        // Request the selection content converted to UTF8_STRING
        // XCB_CURRENT_TIME = 0
        xcbConvertSelection(
            conn, winId, primaryAtom, utf8StringAtom, targetPropertyAtom, 0);
        xcbFlush(conn);
      }
    } else if (eventType == 31) {
      // XCB_SELECTION_NOTIFY = 31
      // Read the converted selection from our window's property
      final cookie = xcbGetProperty(
          conn, 1 /* delete */, winId, targetPropertyAtom, 0 /* AnyPropertyType */, 0, 65536);
      final reply = xcbGetPropertyReplyFn(conn, cookie, nullptr);
      if (reply != nullptr) {
        final len = xcbGetPropertyValueLength(reply);
        if (len > 0) {
          final valuePtr = xcbGetPropertyValue(reply).cast<Utf8>();
          final text = valuePtr.toDartString(length: len).trim();
          if (text.isNotEmpty) {
            port.send(TextSelectionEvent(
              text: text,
              bounds: const SelectionRect.zero(), // X11 gives no bounding box
              timestamp: DateTime.now().toUtc(),
            ));
          }
        }
        calloc.free(reply);
      }
    }

    calloc.free(event);
  }

  xcbDisconnect(conn);
}
