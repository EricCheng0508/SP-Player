/// Starts background helper processes without a console window.
///
/// Why this exists: the bundled helpers (`sp-asr-server.exe`, `llama-server`)
/// are console-subsystem binaries. A Flutter Windows app has no console, so
/// every child a console app is handed gets a brand new console window of its
/// own — the black box that flashes on screen.
///
/// `dart:io` almost fixes this for us: `runtime/bin/process_win.cc` adds
/// `CREATE_NO_WINDOW` for attached modes. But `ProcessStartMode.detached`
/// takes a different branch and sets `DETACHED_PROCESS` *only* — so a detached
/// console child allocates its own console, window included. Long-lived
/// services therefore either sit there as a stray black window, or (when the
/// spawn fails straight away, e.g. the port is taken) flash it for a second.
///
/// `CREATE_NO_WINDOW` is the only flag that suppresses the window at creation,
/// and dart:io never sets it on the detached path, so we call `CreateProcessW`
/// ourselves.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// The process is a console application running without a console window.
const int _createNoWindow = 0x08000000;

/// Inherit the parent's environment block as UTF-16.
const int _createUnicodeEnvironment = 0x00000400;

final class _StartupInfoW extends Struct {
  @Uint32()
  external int cb;

  external Pointer<Utf16> lpReserved;
  external Pointer<Utf16> lpDesktop;
  external Pointer<Utf16> lpTitle;

  @Uint32()
  external int dwX;
  @Uint32()
  external int dwY;
  @Uint32()
  external int dwXSize;
  @Uint32()
  external int dwYSize;
  @Uint32()
  external int dwXCountChars;
  @Uint32()
  external int dwYCountChars;
  @Uint32()
  external int dwFillAttribute;
  @Uint32()
  external int dwFlags;

  @Uint16()
  external int wShowWindow;
  @Uint16()
  external int cbReserved2;

  external Pointer<Uint8> lpReserved2;
  external Pointer<Void> hStdInput;
  external Pointer<Void> hStdOutput;
  external Pointer<Void> hStdError;
}

final class _ProcessInformation extends Struct {
  external Pointer<Void> hProcess;
  external Pointer<Void> hThread;
  @Uint32()
  external int dwProcessId;
  @Uint32()
  external int dwThreadId;
}

typedef _CreateProcessWNative =
    Int32 Function(
      Pointer<Utf16> lpApplicationName,
      Pointer<Utf16> lpCommandLine,
      Pointer<Void> lpProcessAttributes,
      Pointer<Void> lpThreadAttributes,
      Int32 bInheritHandles,
      Uint32 dwCreationFlags,
      Pointer<Void> lpEnvironment,
      Pointer<Utf16> lpCurrentDirectory,
      Pointer<_StartupInfoW> lpStartupInfo,
      Pointer<_ProcessInformation> lpProcessInformation,
    );

typedef _CreateProcessWDart =
    int Function(
      Pointer<Utf16> lpApplicationName,
      Pointer<Utf16> lpCommandLine,
      Pointer<Void> lpProcessAttributes,
      Pointer<Void> lpThreadAttributes,
      int bInheritHandles,
      int dwCreationFlags,
      Pointer<Void> lpEnvironment,
      Pointer<Utf16> lpCurrentDirectory,
      Pointer<_StartupInfoW> lpStartupInfo,
      Pointer<_ProcessInformation> lpProcessInformation,
    );

typedef _CloseHandleNative = Int32 Function(Pointer<Void> hObject);
typedef _CloseHandleDart = int Function(Pointer<Void> hObject);

_CreateProcessWDart? _createProcess;
_CloseHandleDart? _closeHandle;

void _ensureBindings() {
  if (_createProcess != null) return;
  final kernel32 = DynamicLibrary.open('kernel32.dll');
  _createProcess = kernel32
      .lookupFunction<_CreateProcessWNative, _CreateProcessWDart>(
        'CreateProcessW',
      );
  _closeHandle = kernel32.lookupFunction<_CloseHandleNative, _CloseHandleDart>(
    'CloseHandle',
  );
}

/// Quotes one argument the way `CommandLineToArgvW` parses it back.
String _quote(String arg) {
  if (arg.isEmpty) return '""';
  final needsQuotes =
      arg.contains(' ') || arg.contains('\t') || arg.contains('"');
  if (!needsQuotes) return arg;

  final buffer = StringBuffer('"');
  var backslashes = 0;
  for (final unit in arg.codeUnits) {
    if (unit == 0x5C) {
      backslashes++;
      continue;
    }
    if (unit == 0x22) {
      // Backslashes before a quote need doubling, plus one to escape it.
      buffer.write(r'\' * (backslashes * 2 + 1));
      buffer.writeCharCode(unit);
      backslashes = 0;
      continue;
    }
    buffer.write(r'\' * backslashes);
    buffer.writeCharCode(unit);
    backslashes = 0;
  }
  // Trailing backslashes would escape the closing quote.
  buffer.write(r'\' * (backslashes * 2));
  buffer.write('"');
  return buffer.toString();
}

/// Starts [executable] fully detached and with no console window.
///
/// The child outlives this process: no stdio is inherited, no window is shown.
/// Returns true when Windows accepted the spawn — a helper that dies moments
/// later (port already bound, missing model) still reports true here, exactly
/// like `Process.start` would. Callers that care must probe the port.
Future<bool> spawnHidden(
  String executable,
  List<String> args, {
  String? workingDirectory,
}) async {
  if (!Platform.isWindows) {
    // Everywhere else a detached child is already windowless.
    await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      mode: ProcessStartMode.detached,
    );
    return true;
  }

  try {
    _ensureBindings();
    final commandLine = [_quote(executable), ...args.map(_quote)].join(' ');

    final cmdPtr = commandLine.toNativeUtf16();
    final cwdPtr = workingDirectory?.toNativeUtf16();
    final startupInfo = calloc<_StartupInfoW>();
    final processInfo = calloc<_ProcessInformation>();
    try {
      assert(
        sizeOf<_StartupInfoW>() == 104,
        'STARTUPINFOW is 104 bytes on x64',
      );
      startupInfo.ref.cb = sizeOf<_StartupInfoW>();

      final created = _createProcess!(
        // Null application name, like dart:io: Windows then parses the quoted
        // executable out of the command line and searches PATH for bare names.
        // Passing the name separately would skip that search entirely.
        nullptr,
        cmdPtr,
        nullptr,
        nullptr,
        0, // do not inherit handles
        _createNoWindow | _createUnicodeEnvironment,
        nullptr, // inherit environment
        cwdPtr ?? nullptr,
        startupInfo,
        processInfo,
      );
      if (created == 0) return false;

      _closeHandle!(processInfo.ref.hProcess);
      _closeHandle!(processInfo.ref.hThread);
      return true;
    } finally {
      calloc.free(startupInfo);
      calloc.free(processInfo);
      calloc.free(cmdPtr);
      if (cwdPtr != null) calloc.free(cwdPtr);
    }
  } on Object {
    return false;
  }
}
