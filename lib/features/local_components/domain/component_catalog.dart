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

  /// qwen3-asr-wgpu native sidecar (Rust, no Python) — default ASR engine.
  /// TODO(components-v2): flip `optional` to false once the runtime pack is
  /// published and the model asset paths below are pinned.
  qwenAsrRuntime,

  /// Qwen3-ASR-0.6B ONNX weights (English-primary, WER ≈ 8.9%).
  qwenAsrModel,

  /// HTDemucs v4 vocal separation (optional pre-ASR BGM/noise removal).
  vocalSeparation,

  /// CTC forced aligner engine — transcript matching (ADR-0106 §4, P1).
  ctcAlignerRuntime,

  /// omniASR-CTC-300M-v2 weights for transcript matching (P1).
  ctcAlignerModel,

  /// NVIDIA Nemotron-3.5 streaming transducer (int8) for the live captions
  /// real-time engine — sub-second latency, CPU-only decode, no server.
  liveAsr,
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
    this.uiGroupId,
    this.uiGroupLabel,
    this.uiGroupSizeHint,
    this.uiGroupNote,
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

  /// Settings-UI grouping key: specs sharing a group render as ONE row
  /// (e.g. the qwen runtime+model pair shows as a single "识别引擎" row).
  /// Null renders the spec as its own row.
  final String? uiGroupId;

  /// Row title for the merged group row (first spec's value wins).
  final String? uiGroupLabel;

  /// Combined size hint for the merged group row, e.g. `约 1.7 GB`.
  final String? uiGroupSizeHint;

  /// One-line capability note shown under the merged group row title.
  final String? uiGroupNote;
}

/// GitHub Release that hosts SP Player's own runtime packs (the frozen ASR
/// service). Update the tag when publishing a new pack build.
const kComponentsReleaseBase =
    'https://github.com/EricCheng0508/SP-Player/releases/download/components-v1';

/// Release tag for the native (Rust / wgpu) component packs — qwen ASR
/// sidecar and the vocal separation engine. Publish assets here before
/// flipping the `qwenAsr*` specs from optional to required.
const kComponentsReleaseBaseV2 =
    'https://github.com/EricCheng0508/SP-Player/releases/download/components-v2';

/// llama.cpp release pinned at implement time (Vulkan x64 build).
const _kLlamaCppTag = 'b10679';

const kHfOfficial = 'https://huggingface.co';
const kHfChinaMirror = 'https://hf-mirror.com';

/// ModelScope host for the Qwen3-ASR weights (mainland-friendly, resumable).
const kModelScope = 'https://modelscope.cn/models';

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
        // Actual release asset is ~1.98 GiB — keep the floor well below.
        minBytes: 1800 * 1024 * 1024 ~/ 1,
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
  // --- Native ASR stack (ADR-0106): qwen3-asr-wgpu sidecar + 0.6B weights.
  // Both stay `optional` until the components-v2 release is published; the
  // engine resolver falls back to the faster-whisper sidecar meanwhile.
  ComponentSpec(
    kind: ComponentKind.qwenAsrRuntime,
    displayName: '千问识别运行时',
    installDirName: 'qwen-asr-server',
    host: kComponentsReleaseBaseV2,
    extract: true,
    archiveEntry: 'sp-qwen-asr-server.exe',
    optional: true,
    uiGroupId: 'qwenAsr',
    uiGroupLabel: '千问识别引擎 Qwen3-ASR',
    uiGroupSizeHint: '约 1.7 GB',
    uiGroupNote:
        '运行时 0.1 GB + 模型 1.6 GB · qwen3-asr-wgpu 原生组件（Rust，秒开）'
        '· 英语词错率 8.9% · 速度约快 8 倍 · 仅用于「生成字幕」，实时字幕用流式引擎',
    files: [
      ComponentFile(
        remotePath: 'sp-qwen-asr-server-windows-x64.zip',
        relativePath: 'sp-qwen-asr-server-windows-x64.zip',
        // Rust/wgpu sidecar: binary + shaders + DXC, expected well under 100 MB.
        minBytes: 20 * 1024 * 1024,
      ),
    ],
    sizeHint: '约 0.1 GB',
  ),
  ComponentSpec(
    kind: ComponentKind.qwenAsrModel,
    displayName: '千问识别模型 Qwen3-ASR-0.6B',
    installDirName: 'asr-models/qwen3-asr-0.6b',
    host: kModelScope,
    optional: true,
    uiGroupId: 'qwenAsr',
    uiGroupLabel: '千问识别引擎 Qwen3-ASR',
    uiGroupSizeHint: '约 1.7 GB',
    uiGroupNote:
        '运行时 0.1 GB + 模型 1.6 GB · qwen3-asr-wgpu 原生组件（Rust，秒开）'
        '· 英语词错率 8.9% · 速度约快 8 倍 · 仅用于「生成字幕」，实时字幕用流式引擎',
    files: [
      // TODO(components-v2): pin the exact ModelScope repo path and ONNX file
      // names when the sidecar build freezes its loading layout.
      ComponentFile(
        remotePath: 'OneAsr/Qwen3-ASR-0.6B-hf/resolve/main/model.onnx',
        relativePath: 'model.onnx',
        minBytes: 1400 * 1024 * 1024 ~/ 1,
      ),
      ComponentFile(
        remotePath: 'OneAsr/Qwen3-ASR-0.6B-hf/resolve/main/tokenizer.json',
        relativePath: 'tokenizer.json',
        minBytes: 512 * 1024,
      ),
      ComponentFile(
        remotePath: 'OneAsr/Qwen3-ASR-0.6B-hf/resolve/main/config.json',
        relativePath: 'config.json',
        minBytes: 256,
      ),
    ],
    sizeHint: '约 1.6 GB',
  ),
  ComponentSpec(
    kind: ComponentKind.vocalSeparation,
    displayName: '人声分离 HTDemucs',
    installDirName: 'vocal-separation',
    host: kComponentsReleaseBaseV2,
    extract: true,
    archiveEntry: 'sp-demucs-server.exe',
    optional: true,
    files: [
      // TODO(components-v2): engine pack (demucs-wgpu + weights, ~84 MB).
      ComponentFile(
        remotePath: 'sp-demucs-windows-x64.zip',
        relativePath: 'sp-demucs-windows-x64.zip',
        minBytes: 60 * 1024 * 1024,
      ),
    ],
    sizeHint: '约 0.1 GB',
  ),
  // --- Transcript matching (P1): CTC aligner engine + omniASR weights.
  ComponentSpec(
    kind: ComponentKind.ctcAlignerRuntime,
    displayName: '台本对齐引擎',
    installDirName: 'ctc-aligner',
    host: kComponentsReleaseBaseV2,
    extract: true,
    archiveEntry: 'sp-ctc-aligner.exe',
    optional: true,
    uiGroupId: 'ctcAligner',
    uiGroupLabel: '台本对齐',
    uiGroupSizeHint: '约 1.4 GB',
    uiGroupNote: '已有校对稿的 SRT/TXT 直接对齐出词级时间轴，文字 100% 准确',
    files: [
      // TODO(components-v2): ctc-forced-aligner-wgpu engine pack.
      ComponentFile(
        remotePath: 'sp-ctc-aligner-windows-x64.zip',
        relativePath: 'sp-ctc-aligner-windows-x64.zip',
        minBytes: 15 * 1024 * 1024,
      ),
    ],
    sizeHint: '约 0.1 GB',
  ),
  ComponentSpec(
    kind: ComponentKind.ctcAlignerModel,
    displayName: '台本对齐模型 omniASR-CTC-300M',
    installDirName: 'asr-models/omniasr-ctc-300m',
    host: kModelScope,
    optional: true,
    uiGroupId: 'ctcAligner',
    uiGroupLabel: '台本对齐',
    uiGroupSizeHint: '约 1.4 GB',
    uiGroupNote: '已有校对稿的 SRT/TXT 直接对齐出词级时间轴，文字 100% 准确',
    files: [
      // TODO(components-v2): pin the exact ModelScope repo path at build time.
      ComponentFile(
        remotePath: 'OneAsr/omniASR-CTC-300M-v2-hf/resolve/main/model.onnx',
        relativePath: 'model.onnx',
        minBytes: 1200 * 1024 * 1024 ~/ 1,
      ),
      ComponentFile(
        remotePath: 'OneAsr/omniASR-CTC-300M-v2-hf/resolve/main/tokenizer.json',
        relativePath: 'tokenizer.json',
        minBytes: 256 * 1024,
      ),
    ],
    sizeHint: '约 1.3 GB',
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
  ComponentSpec(
    kind: ComponentKind.liveAsr,
    displayName: '流式识别引擎 Nemotron-3.5 0.6B',
    installDirName: 'live-asr',
    host: kHfOfficial,
    files: [
      ComponentFile(
        remotePath:
            'csukuangfj2/sherpa-onnx-nemotron-3.5-asr-streaming-0.6b-560ms-int8-2026-06-11/resolve/main/encoder.int8.onnx',
        relativePath: 'encoder.int8.onnx',
        minBytes: 650 * 1024 * 1024,
      ),
      ComponentFile(
        remotePath:
            'csukuangfj2/sherpa-onnx-nemotron-3.5-asr-streaming-0.6b-560ms-int8-2026-06-11/resolve/main/decoder.int8.onnx',
        relativePath: 'decoder.int8.onnx',
        minBytes: 13 * 1024 * 1024,
      ),
      ComponentFile(
        remotePath:
            'csukuangfj2/sherpa-onnx-nemotron-3.5-asr-streaming-0.6b-560ms-int8-2026-06-11/resolve/main/joiner.int8.onnx',
        relativePath: 'joiner.int8.onnx',
        minBytes: 8 * 1024 * 1024,
      ),
      ComponentFile(
        remotePath:
            'csukuangfj2/sherpa-onnx-nemotron-3.5-asr-streaming-0.6b-560ms-int8-2026-06-11/resolve/main/tokens.txt',
        relativePath: 'tokens.txt',
        minBytes: 128 * 1024,
      ),
    ],
    sizeHint: '约 0.7 GB',
    optional: true,
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
String componentFileUrl(
  ComponentSpec spec,
  ComponentFile file,
  String? hfEndpoint,
) => applyHfMirror('${spec.host}/${file.remotePath}', hfEndpoint);
