# ADR-0106: 多引擎 ASR 架构（Qwen3-ASR + Whisper + 对齐阶段）

## Status

Accepted（2026-11-27，用户确认实施）

## Scope & invariants（范围与不变式）

- **产品定位**：英语识别 → 中文翻译。不做多语言路由，不做日语/粤语等长尾语种决策。
- **OneAsr 仅参考引擎内部实现**（wgpu 引擎、VAD → ASR → 对齐 → 断句管线、模型分发），**不参考其 UI**。
- **现有功能零删减**：右侧逐句字幕面板、过词（卡拉OK逐词高亮）、实时监听（live-asr）、跟读 / 听写练习、生词本全部保持原样。本次升级只替换/新增「字幕怎么生成」的引擎层。**例外（用户 2026-11-27 决策）**：AI 翻译触发方式由「跟随播放逐句自动翻」改为「手动全片批量翻译」，见 Decision 第 5 条。
- 页面结构不重设计，UI 只加入口（见 Decision 第 5 条）。

## Context

当前本地识别由 PyInstaller 打包的 `sp-asr-server`（faster-whisper，默认 large-v3-turbo）以 OpenAI 兼容服务形式提供，监听 `127.0.0.1:8000/v1`。存在四个问题：

1. **中文质量瓶颈**。faster-whisper 在中文/粤语/方言上明显落后于新一代模型：AISHELL-2 CER 5.06% vs Qwen3-ASR-0.6B 3.15%；方言 KeSpeech 28.79% vs 7.08%；粤语 16.23% vs 9.50%（Qwen3-ASR 官方评测）。静音段/纯音乐段的幻觉也是 Whisper 老毛病。
2. **体积与依赖**。sidecar 含 Python 运行时 + CUDA/cuBLAS，约 2GiB+；AMD/Intel 显卡用户只能回落慢速 CPU。
3. **时间戳精度**。Whisper 词级时间戳来自 cross-attention DTW，长视频漂移明显，直接决定卡拉OK逐词高亮的上限。
4. **分发**。2GiB+ 资产走 GitHub Releases，国内下载体验一般。

参考实现：[OneAsr](https://github.com/eclipse005/OneAsr)（MIT）验证了 Qwen3-ASR 在消费级桌面 GPU 上的可行性，其引擎
[qwen3-asr-wgpu](https://github.com/eclipse005/qwen3-asr-wgpu)、
[ctc-forced-aligner-wgpu](https://github.com/eclipse005/ctc-forced-aligner-wgpu)
均为 MIT 许可的独立 Rust/wgpu 实现（NVIDIA / AMD / Intel / Apple Silicon，无 Python 依赖）。

**硬性约束**：体积小、启动快、代码质量高；页面结构不重设计，只加入口级 UI。

## Decision

### 1. 引擎层：六边形端口 + 三个实现

在 `lib/features/asr/domain` 定义 `AsrEngine` 端口（能力描述：语种覆盖、词级时间戳质量、显存需求、冷启动预算），实现放 `lib/features/asr/data`，Riverpod 注入：

| 实现 | 引擎 | 定位 | 许可 |
|---|---|---|---|
| `LocalQwenEngine` | qwen3-asr-wgpu（原生 sidecar） | **默认**，英语识别（GigaSpeech 8.88 vs Whisper 9.76，RTF≈0.05 @4090） | MIT（引擎），Qwen3-ASR 权重条款随模型 |
| `LocalWhisperEngine` | 现有 sp-asr-server（faster-whisper large-v3-turbo） | **过渡期保留，验证后整体移除**：Qwen 引擎稳定运行 1–2 周后，删 large-v3-turbo 模型（1.7GB）+ faster-whisper Python sidecar（2.1GB），合计省约 3.8GB 并甩掉 Python/CUDA 依赖；UI 目录不再展示双选 | 现状不变 |
| `RemoteEngine` | OpenAI 兼容 / Azure（现有 BYOK 路径） | 用户自带端点 | 现状不变 |

产品固定英语，无语言路由；**千问 Qwen3-ASR 为唯一识别模型，无引擎/模型选择 UI**（过渡期 Whisper 灰显标「待移除」）。识别产出的英文文本照走现有 AI 翻译链路（llama.cpp / 云端 LLM），但触发方式改为手动全片批量（见 Decision 第 5 条）；翻译进度按批次逐批上报给新增的翻译进度横幅。相关逻辑为纯函数，进 `test/features/asr` 单测。

### 2. 时间戳管线：VAD → ASR → 对齐 → 断句

新增可选对齐阶段，两个候选引擎（均为同作者 MIT wgpu 引擎，OneAsr 1.5.0 的用法可参考）：

- **识别后对齐**（主流水线）：`qwen3-aligner-wgpu`（Qwen3-ForcedAligner-Ultra，~1.8GB，词级，OneAsr 1.5.0 起为其默认对齐器），产出词级时间戳喂给现有 `asr_timeline_builder`（断句逻辑不动——它已经够好）；
- **台本对齐**（跳过识别）：`ctc-forced-aligner-wgpu`（omniASR-CTC-300M，~1.3GB，帧同步 CTC）——已校对的 SRT/TXT 直接 CTC 对齐，产出文字 100% 准确的词级时间轴；此场景 CTC 是 OneAsr 的专用选择。

若需要控制默认下载体积，可先只接其一（推荐先接识别后对齐的 Qwen 对齐器），台本对齐作为 P1 追加。

Whisper 路径强制 `vad_filter=true`（需确认 sidecar 传参），抑制音乐/静音段幻觉。

与 ADR-0071/0072 的关系：现有 `packages/forced_alignment`（Echogarden 接口，MFCC+DTW 对 eSpeak 合成参考音，90s 上限、以英语为主）继续服务 Craft 短片富集，保持 "unused by product flows" 边界不动。本 ADR 的对齐阶段是**不同层**的资产：神经 CTC 对齐器（帧同步、全语种、整片时长）以 sidecar 形式服务字幕生成管线，两者不合并、不互替。

### 3. 分发：ModelScope 优先

组件目录（`component_catalog.dart`）为每个资产增加 ModelScope 镜像地址；下载器沿用现有 16 线程分段并行 + 断点续传实现，来源按 `ModelScope → GitHub → 手动导入 zip` 依次回落。安装包体积不变（不带模型）；默认下载组合为 Qwen 0.6B（~1.6GB）+ 对齐器（~1.8GB，可选），Whisper 2GiB 降级为可选。

### 4. 热词（P0 内的低成本项）

设置页新增「识别热词」列表，识别时拼接进 Whisper `initial_prompt` / Qwen 对应机制（`AsrRequest.prompt` 字段现成）。

### 5. UI 入口（全部为增量，不改页面结构；2026-11-27 与用户定稿）

- 设置 → AI → 语音服务卡：**千问 Qwen3-ASR 为唯一识别模型，不做单选控件**。**2026-11-28 定稿修订**：①运行时(0.1GB)+模型(1.6GB) **合并为一行「千问识别引擎 Qwen3-ASR」**（`uiGroupId` 分组，~1.7GB，能力注记一行展示）；②**Whisper 过渡行不再出现在设置页**（代码内保留兜底，界面零展示）；③**「云端语音服务」（Azure）区块与 本地/云端 切换整体移除**（TTS 走 Windows 系统语音不吃 Azure；配置数据结构保留兼容）；④人声分离、台本对齐收进**「可选增强组件」折叠组**（默认收起，点标题展开）；⑤流式引擎行直接标 **Nemotron-3.5 0.6B**（文件在 components-v2 换装，~0.7GB）
- **导出直接下载（用户 2026-11-28 决策）**：SRT 是唯一格式、无选择必要——点 ⋯ 菜单「下载字幕」**直接保存双语 .srt，移除格式选择弹框**（`download_transcript_format_dialog.dart` 删除）
- 字幕空态（`transcript_empty_state.dart`）：按钮组插入「对齐已有字幕 / 台本」入口 + 文件选择
- 生成进度横幅：转圈改为阶段面包屑「提取音频 → 识别 → 对齐 → 断句」+ 细进度条 + 引擎/耗时信息行
- **翻译触发方式改为手动全片批量（用户 2026-11-27 决策）**：移除跟随播放的逐句自动翻译（`AutoTranslateLineQueue` 的 viewport-prioritized 调度、`kAutoTranslateViewportWindow` 机制废弃）；新增「翻译全片」入口（字幕 ⋯ 菜单 / 生成完成后提示），点击后一次性批量翻译全部句子，生成中的中文行显示占位。理由：跟播模式下网络卡顿会导致后文漏翻，用户要「一次全翻完」的确定性。
- **翻译速度设计**：现有逐句路径慢的根因是 `kAutoTranslateMaxConcurrency = 2` 且一句一请求。全片批翻改为 **每批 ~20 句合并成一次请求 + 并发 6 路**（批大小与并发数做成常量可调）：344 句 ≈ 17 次请求，云端 LLM 全片约 1–2 分钟；合并批次还带来上下文一致性（术语/人称统一）。云端未配置时走本地 TranslateGemma，速度以本地为准但不阻塞播放（后台跑，横幅显示进度）。
- **翻译进度横幅（新增）**：点击「翻译全片」后显示横幅，进度 = 已翻译句数 / 总句数（如「45 / 344 句」），信息行显示当前批次、已翻译到视频第几分钟、预计剩余时间；失败的批次自动重试并在横幅提示。
- **进度持久化 + 断点续翻（用户 2026-11-27 补充决策）**：翻译以**批为单位落库**——每批完成立即写入译文缓存，媒体维度记录状态（未开始 / 进行中 n/total / 已完成）。再次打开同一媒体：
  - **已完成** → 中文直接显示，不出横幅（⋯ 菜单保留「重新翻译全片」作为显式覆盖入口）；
  - **进行中（上次中断）** → 横幅显示已缓存进度（如「178 / 344 句」），提供两个入口：「**继续翻译**」（从首个未完成批次接着翻，已翻句子直接用缓存、不重复消耗 API）和「**重新翻译全片**」（忽略缓存全部重翻）；
  - **未开始** → 横幅显示「翻译待开始」+「翻译全片」按钮。
  - 中途退出 / 崩溃 / 断网都不丢进度——最多损失当前在途的一个批次。
- **导出联动**：双语 SRT 导出前置条件 = 翻译状态为「已完成」；进行中/未开始时点击导出提示「先执行翻译全片（已完成 n/344 句，可继续翻译）」。
- 导出：**原生已有** `download_transcript_format_dialog.dart`，**只保留 SRT**（移除 VTT 选项，不做格式单选）；未来 ASS 词级导出在该对话框加一行即可
- 生成字幕弹窗保持原生，不加引擎控件

### 6. OneAsr 最后一轮盘点（2026-11-27，实施前确认）

**新吸收（本次补充进决策）**：

- **可选人声分离 HTDemucs v4**（~84 MB，`demucs-wgpu` 原生引擎）：识别前可选去 BGM/噪声。SP-Player 的学习素材常带背景音乐，干净人声对 Qwen 与对齐阶段都直接提升准确率。作为可选组件行出现在语音服务卡，默认不装、P1 提供下载入口。
- **VAD 切分落点优化**：静音切分落在**最低能量点**而非固定网格（OneAsr 1.5.0 教训），避免切在词中间。写进 P1 的 VAD 传参确认项。
- **sidecar 进度协议**：引擎 sidecar 输出**机器可读 JSON 进度事件**（阶段、百分比、批次号），而非解析 stdout 文本——识别/翻译两条横幅的数据源统一走这个协议。
- **wgpu sidecar 工程要求**：① 无独显/驱动异常时自动回退 CPU；② Windows 上随包携带 dxcompiler.dll（DX12 兜底），否则首次着色器编译可慢到十几分钟（OneAsr 实测 1051s → 17s）；③ 供应链钉住——ffmpeg/DXC 等外部二进制用 sha256 清单校验来源，CI 复核，Rust 依赖 `--locked` 构建。符合「代码质量高」硬性约束。

**明确不吸收（已评估，不适用本产品）**：

- CLI（`oneasr-cli`）——GUI 播放器无此需求；纯转写模式（只 TXT 停在对齐前）——词级卡拉OK时间轴是刚需；多语言/简繁转换——产品固定英语→中文；11 语种——同前。
- SenseVoiceSmall 热词（~940 MB）——热词入口此前已砍；若未来恢复热词需求再评估。
- Qwen3-ASR-1.7B 档（~4.1 GB）——**用户 2026-11-27 确认不需要**：更准但更慢更吃显存，英语 0.6B 已够用，且与「体积小、启动快」约束冲突。

### 演进路线

| 阶段 | 内容 | 验收 |
|---|---|---|
| **P0** | Qwen 引擎接入（wgpu sidecar、懒启动、退出回收）、语言路由、热词、台本对齐 MVP；Whisper 过渡期保留 | 同一中文样片 CER 低于 Whisper 基线；10 分钟音频 4090 上 < 1 分钟；冷启动 < 1s；不改任何现有页面结构 |
| **P1** | 对齐阶段进主流水线、字幕导出、ModelScope 源、VAD 传参确认、进度阶段化；Whisper 组件移除（省 ~3.8GB）；**实时字幕逐词显示**（渲染 partial hypothesis，复用词级卡拉OK基建）；**流式引擎换 NVIDIA Nemotron-3.5-ASR-Streaming 0.6B**（int8 ~682MB，chunk 560ms，口语准确率显著高于现 zipformer-en-2023；同一接入协议，仅换组件文件）。**实施状态（2026-11-27）**：SRT-only 导出 ✓、ModelScope 源 ✓、进度阶段化（横幅面包屑 提取音频→识别→对齐→断句 + 引擎/耗时信息行，`asr_stage_pipeline.dart` 纯函数 + 单测）✓；对齐进主流水线与 Nemotron 换装依赖 components-v2 sidecar 发布后钉 URL | 词时间戳漂移实测改善；导出可用；实时字幕逐词出字延迟 < 1s；CPU RTF < 1 |
| **P2** | 长视频静音切分并行推理（wgpu 引擎接入后 Python sidecar 已随 Whisper 移除） | AMD/Intel 全 GPU 路径可用 |

## Consequences

- **体积**：默认路径（Qwen 0.6B + 对齐器）约 3.4GB，比现在的单 Whisper 2GiB 大，但换来质量/速度跃升；Whisper 改可选后，纯中文用户的总占用可控。量化版本（如 MLX 5-bit 在 Apple 上 1.03GB）留作后续观察，wgpu 引擎的量化支持以 qwen3-asr-wgpu 实际能力为准。
- **启动**：wgpu 引擎为几十 MB 原生二进制，冷启动远快于 PyInstaller；Whisper 引擎保持按需静默拉起 + 退出回收（沿用 ADR 中本地组件托管机制）。
- **代码质量**：路由、断句、导出全部走纯函数 + 单测（fixtures 已有 `test_assets/fixtures/asr`）；引擎适配层不做业务逻辑；不新增 UI 框架/状态管理依赖。
- **风险**：qwen3-asr-wgpu 为单作者项目，需 pin 版本 + 自托管 fork 兜底；1.7B 档的显存需求（≥6GB）需在模型卡中标注；license 义务：MIT 引擎保留版权声明，Qwen3-ASR 权重条款随模型分发一并展示。
- **明确不做**：不引入说话人分离、不做批量字幕工厂队列——与播放器定位无关；不从上游 enjoy_player 合并。
