/// Managed local components (local ASR runtime/model, local MT runtime/model).
///
/// Mirrors Transub Player's component model: the app can install, probe and
/// remove each piece itself — no BAT files, no manual Python setup. URLs use
/// GitHub Releases for app-owned runtime packs and Hugging Face for models,
/// with automatic hf-mirror.com switching for mainland China.
library;

/// The four installable components.
enum ComponentKind {
  /// OpenAI-compatible local transcription service (faster-whisper, frozen exe).
  asrRuntime,

  /// faster-whisper `large-v3-turbo` CTranslate2 model files.
  asrModel,

  /// llama.cpp `llama-server` (Vulkan) runtime for local translation.
  mtRuntime,

  /// TranslateGemma 4B Q4 GGUF — translation-specialized local model.
  mtModel,
}

/// One downloadable file of a [ComponentSpec].
final class ComponentFile {
  const ComponentFile({
    required this.remotePath,
    required this.relativePath,
    required this.minBytes,
  });

  /// Path on the remote host (Hugging Face repo path or release asset name).
  final String remotePath;

  /// Destination relative to the component's install dir.
  final String relativePath;

  /// Lower bound for "download looks complete" validation.
  final int minBytes;
}

final class ComponentSpec {
  const ComponentSpec({
    required this.kind,
    required this.displayName,
    required this.installDirName,
    required this.host,
    required this.files,
    this.archiveEntry,
    this.extract = false,
    required this.sizeHint,
    this.optional = false,
  });

  final ComponentKind kind;

  /// Display name, e.g. `识别运行时`.
  final String displayName;

  /// Directory under the components root.
  final String installDirName;

  /// Download host, e.g. `https://huggingface.co` (mirror-swappable) or a
  /// fixed GitHub Releases base.
  final String host;

  final List<ComponentFile> files;

  /// For archives: the entry to verify after extraction (exe name).
  final String? archiveEntry;

  final bool extract;

  /// Human size hint for the wizard, e.g. `约 3.2 GB`.
  final String sizeHint;

  /// Optional components can be skipped at install time (download later in
  /// Settings) — e.g. the local translation model.
  final bool optional;
}

/// GitHub Release that hosts SP Player's own runtime packs (the frozen ASR
/// service). Update the tag when publishing a new pack build.
const kComponentsReleaseBase =
    'https://github.com/EricCheng0508/SP-Player/releases/download/components-v1';

/// llama.cpp release pinned at implement time (Vulkan x64 build).
const _kLlamaCppTag = 'b10679';

const kHfOfficial = 'https://huggingface.co';
const kHfChinaMirror = 'https://hf-mirror.com';

/// All managed components, in wizard install order.
const kComponentSpecs = <ComponentSpec>[
  ComponentSpec(
    kind: ComponentKind.asrRuntime,
    displayName: '识别运行时',
    installDirName: 'asr-server',
    host: kComponentsReleaseBase,
    extract: true,
    archiveEntry: 'sp-asr-server.exe',
    files: [
      ComponentFile(
        remotePath: 'sp-asr-server-windows-x64.zip',
        relativePath: 'sp-asr-server-windows-x64.zip',
        minBytes: 2 * 1024 * 1024 * 1024 ~/ 1,
      ),
    ],
    sizeHint: '约 2.1 GB',
  ),
  ComponentSpec(
    kind: ComponentKind.asrModel,
    displayName: '识别模型 large-v3-turbo',
    installDirName: 'asr-models/large-v3-turbo',
    host: kHfOfficial,
    files: [
      ComponentFile(
        remotePath:
            'mobiuslabsgmbh/faster-whisper-large-v3-turbo/resolve/main/model.bin',
        relativePath: 'model.bin',
        minBytes: 1500 * 1024 * 1024 ~/ 1,
      ),
      ComponentFile(
        remotePath:
            'mobiuslabsgmbh/faster-whisper-large-v3-turbo/resolve/main/config.json',
        relativePath: 'config.json',
        minBytes: 1024,
      ),
      ComponentFile(
        remotePath:
            'mobiuslabsgmbh/faster-whisper-large-v3-turbo/resolve/main/preprocessor_config.json',
        relativePath: 'preprocessor_config.json',
        minBytes: 256,
      ),
      ComponentFile(
        remotePath:
            'mobiuslabsgmbh/faster-whisper-large-v3-turbo/resolve/main/tokenizer.json',
        relativePath: 'tokenizer.json',
        minBytes: 2 * 1024 * 1024,
      ),
      ComponentFile(
        remotePath:
            'mobiuslabsgmbh/faster-whisper-large-v3-turbo/resolve/main/vocabulary.json',
        relativePath: 'vocabulary.json',
        minBytes: 1024 * 1024,
      ),
    ],
    // model.bin X-Linked-Size = 1,617,884,929 bytes.
    sizeHint: '约 1.7 GB',
  ),
  ComponentSpec(
    kind: ComponentKind.mtRuntime,
    displayName: '翻译运行时 llama-server',
    installDirName: 'llama-server',
    host:
        'https://github.com/ggml-org/llama.cpp/releases/download/$_kLlamaCppTag',
    extract: true,
    archiveEntry: 'llama-server.exe',
    files: [
      ComponentFile(
        remotePath: 'llama-$_kLlamaCppTag-bin-win-vulkan-x64.zip',
        relativePath: 'llama-$_kLlamaCppTag-bin-win-vulkan-x64.zip',
        minBytes: 20 * 1024 * 1024,
      ),
    ],
    sizeHint: '约 0.1 GB',
  ),
  ComponentSpec(
    kind: ComponentKind.mtModel,
    displayName: '翻译模型 TranslateGemma 4B',
    installDirName: 'mt-models',
    host: kHfOfficial,
    optional: true,
    files: [
      ComponentFile(
        remotePath:
            'bullerwins/translategemma-4b-it-GGUF/resolve/main/translategemma-4b-it-Q4_K_M.gguf',
        relativePath: 'translategemma-4b-it-Q4_K_M.gguf',
        minBytes: 2490 * 1024 * 1024 ~/ 1,
      ),
    ],
    sizeHint: '约 2.5 GB',
  ),
];

ComponentSpec specOf(ComponentKind kind) =>
    kComponentSpecs.firstWhere((s) => s.kind == kind);

/// Swaps huggingface.co for a mirror endpoint when [endpoint] is provided.
String applyHfMirror(String url, String? endpoint) {
  final ep = endpoint?.trim();
  if (ep == null || ep.isEmpty) return url;
  final normalized = ep.endsWith('/') ? ep.substring(0, ep.length - 1) : ep;
  return url
      .replaceFirst('$kHfOfficial/', '$normalized/')
      .replaceFirst('http://huggingface.co/', '$normalized/');
}

/// Full download URL for [file] of [spec], honoring the HF mirror endpoint.
String componentFileUrl(ComponentSpec spec, ComponentFile file, String? hfEndpoint) =>
    applyHfMirror('${spec.host}/${file.remotePath}', hfEndpoint);
