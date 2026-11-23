# SP Player 本地版

> 只在自己电脑上用的外语精听播放器。无账号、无订阅、无积分、无云端；
> AI 只连自己填的端点，字幕识别和翻译模型都跑在本机。
>
> 基于 [baizhiheizi/enjoy_player](https://github.com/baizhiheizi/enjoy_player)（AGPL-3.0）修改，
> 沿用同一许可证，详见 [LICENSE](LICENSE)。

这个仓库只有一个用途：**哪天exe删了、系统重装了，从这里 clone 下来
照着下面几步就能恢复，不用再回忆当初怎么弄的。**

当前版本 **0.10.3**，两种形态：

| 形态 | 产物 | 说明 |
|---|---|---|
| 便携版 | `build\windows\x64\runner\Release\`（含 `components\`） | 解压即用，模型已预置 |
| 安装包 | `windows/installer.iss` → `SPPlayer-Setup-0.10.3.exe` | Inno Setup 打包，带协议注册（`enjoyplayer://` 登录回跳） |

---

## 一、这套东西由两块组成

| | 是什么 | 在哪 | 干什么 |
|---|---|---|---|
| **播放器** | 本仓库，Flutter + libmpv | `D:\code\SP-Player` | 播放、字幕、逐句练、跟读、听写、生词本 |
| **本地组件** | faster-whisper + llama.cpp | 播放器 `components\` 目录（首次运行向导安装/预置） | 语音识别、本地翻译 |

**不再需要外挂 subgen 项目**：识别服务由播放器自己拉起和管理
（`lib/features/ai/data/local_subgen_asr_service.dart`，静默启动、TCP 端口探测、
退出即回收），监听 `http://127.0.0.1:8000/v1`。

- 识别模型 `large-v3-turbo`，路径 `components\asr-models\large-v3-turbo`；
  CPU（int8）约 1.8× 实时，5 分钟视频约 2.5–3 分钟出全文；有 CUDA 显卡时自动走 GPU。
- 本地翻译：llama.cpp Vulkan 运行时 + TranslateGemma 4B GGUF（`managed_llama_server.dart`）。
- 翻译、查词也可以走你自己填的 OpenAI 兼容端点（BYOK）。

播放和识别都在本地，音频不出机器。

---

## 二、从 GitHub 拉下来之后怎么恢复

### 1. 构建环境（只需一次）

| 需要 | 版本 | 本机参考路径 |
|---|---|---|
| Flutter | 3.47.6 | `D:\dev\flutter`（pub-cache `D:\dev\pub-cache`） |
| Visual Studio 2022 | 含「使用 C++ 的桌面开发」负载 | `D:\VS\BuildTools` |
| Python 3.10+ | 含 faster-whisper 依赖 | `D:\dev\pylibs` |
| FFmpeg | essentials 构建 | 见第 2 步 |

Flutter 需要的环境变量：

```
PATH                     += D:\dev\flutter\bin
FLUTTER_ROOT              = D:\dev\flutter
FLUTTER_STORAGE_BASE_URL  = https://storage.flutter-io.cn
PUB_HOSTED_URL            = https://pub.flutter-io.cn
```

### 2. 取 ffmpeg.exe

仓库里**不含** ffmpeg：单个文件超过 GitHub 单文件 100 MiB 硬上限，推不上去。
用仓库自带脚本下载到 `windows\ffmpeg\ffmpeg.exe`，编译时 CMake 会自动复制到 exe 旁边：

```powershell
pwsh windows/scripts/fetch_ffmpeg.ps1
```

> **不做这一步，「提取字幕」会失败。**
> 应用找的是 `sp_player.exe` 同目录下的 `ffmpeg.exe`，其次才是 PATH。

### 3. 编译

```powershell
cd D:\code\SP-Player
flutter pub get
flutter build windows --release
```

产物在 `build\windows\x64\runner\Release\`，**整个目录**一起拿（exe 只有几百 KB，
主体是 `data\app.so`、`libmpv-2.dll`、`flutter_windows.dll`、`ffmpeg.exe`）。

打安装包（需要先装 Inno Setup 6）：

```powershell
iscc windows\installer.iss        # 产物 build\installer\SPPlayer-Setup-0.10.3.exe
```

### 4. 识别/翻译模型

两种来源任选：

- **便携版**：直接把 `components\` 目录放到 exe 旁边（模型已预置，`asr-models\large-v3-turbo`）。
- **向导安装**：首次运行播放器 → 设置向导 → 本地组件页，按提示下载。

组件装好后无需手动起服务：点「生成字幕」时播放器自动拉起 faster-whisper，
用完自动退出；日志在 `%APPDATA%\SP\SP Player\logs\`。

### 5. 应用内配置（可选，用云端 AI 时才需要）

播放器 → **设置 → AI**：

| 标签 | 字段 | 填什么 |
|---|---|---|
| **语言模型** | Base URL / Key / 模型 | 任意 OpenAI 兼容端点，或本地网关 `http://127.0.0.1:<端口>/v1` |
| **语音识别** | Base URL | `http://127.0.0.1:8000/v1`（本地组件，一般不用改） |

---

## 三、字幕怎么来

| | **应用内「生成字幕」** | **导入现成 .srt** |
|---|---|---|
| 入口 | 播放器里对某个视频点「生成字幕」 | 把 `.srt` 和视频放一起导入 |
| 前提 | 本地组件已安装（首次自动拉起服务） | 无 |
| 产物 | 直接写进应用数据库，立刻能逐句练 | 直接可用 |
| 双语 | 生成后靠 AI 翻译逐句翻 | 一步到位的双语 `.srt` |

### 应用内「生成字幕」到底做了什么

```
点「生成字幕」
  → 选语言（可自动检测）
  → 长音频弹一次确认框（识别在本机，不产生任何费用）
  → 用 exe 旁边的 ffmpeg.exe 抽 16k 单声道 wav
  → POST http://127.0.0.1:8000/v1/audio/transcriptions
        response_format=verbose_json（强制，为了拿到逐句 segments）
  → 得到 [{start, end, text}, ...]
  → 写成 source='ai' 的字幕轨，存进本地 SQLite
```

**它不生成 .srt 文件，而是直接进库。** 识别过程中有按设备标定的实时进度条
（`asr_recognition_progress.dart`，会按上一次实际耗时自动校准），不再是假进度。

---

## 四、单词发音

选中单词点喇叭 → 本地直接拼有道词典的音频地址播放，不经过 AI：

```
https://dict.youdao.com/dictvoice?audio=<单词>&type=2   美音（type=1 英音）
```

下载的 mp3 存到 `%APPDATA%\...\pronounce_audio\<sha1>.mp3`，
**听过的词以后永久离线可听**。查不到的词有道返回 500，按「该词没有发音」静默处理。

---

## 五、和原项目的差别

### 删掉的（133 个文件，约 −12700 行）

- 账号体系与登录墙（`/sign-in`、`/profile`、`/credits`、`/subscription`）
- 订阅、积分、套餐、社区、云端书库的页面与接口
- Enjoy AI worker 客户端：chat / ASR / 翻译 / 词典 / Azure token
- YouTube 字幕的 worker 缓存查询、时间轴上传、客户端配置下发
- 上述能力依赖的 sync 任务类型与重试逻辑

### 换成本地的

- 语音识别：远端 Whisper → 本机 faster-whisper（应用托管，`large-v3-turbo`）
- 翻译：远端 LLM → 本机 llama.cpp（TranslateGemma 4B）或 BYOK 端点
- 词典/例句：远端 worker → 本地数据 + BYOK

### 保留的

- 本地播放、导入、字幕、逐句循环、跟读、听写、生词本
- 单视频 YouTube 导入（本地 InnerTube 抓字幕，不经过任何远端）
- AI 翻译 / 查词 / 语境翻译，全部 BYOK

### 仍会碰到原服务器的唯一功能

频道订阅 / 播放列表（`features/discover`）：粘 `@频道` 或播放列表链接时，
本地没有等价实现。**单视频导入完全不受影响**：解析 ID → `youtube.com/oembed`
取标题 → WebView 播放 → 本地抓字幕，全程直连 Google。

---

## 六、以后想改代码，从这几个文件入手

| 文件 | 作用 |
|---|---|
| `lib/core/config/local_mode.dart` | 本地化分支总开关 |
| `lib/features/ai/data/local_subgen_asr_service.dart` | 托管 faster-whisper：拉起/探测/回收 |
| `lib/features/ai/data/local_subgen_asr_capability.dart` | 识别能力接线（端点、模型、吞吐标定） |
| `lib/features/asr/application/asr_recognition_progress.dart` | 识别进度估算与自标定 |
| `lib/features/local_components/data/managed_llama_server.dart` | 托管 llama.cpp 翻译网关 |
| `lib/features/player/presentation/widgets/player_surface_target.dart` | 视频表面目标注册（黑屏修复点） |
| `lib/features/player/presentation/widgets/media_kit_video_stage.dart` | mpv 视频舞台（纹理挂载） |
| `lib/core/platform/hidden_process.dart` | Win32 静默启动子进程（不弹黑框） |
| `lib/features/asr/application/asr_generation_controller.dart` | 「生成字幕」流程编排 |
| `lib/features/pronounce/data/youdao_pronounce_source.dart` | 有道发音地址与语种映射 |
| `lib/features/transcript/data/transcript_repository_youtube_fetch.dart` | 本地抓 YouTube 字幕 |

改完 UI 文字或 provider 之后，别忘了：

```powershell
dart run build_runner build --delete-conflicting-outputs
```

`.g.dart` 不参与 `dart analyze`，但参与编译——删 provider 时不同步会只在编译阶段报错。

---

## 七、常见问题

**「生成字幕失败」/ 点了没反应**
本地组件是否装好：设置 → 本地组件；服务日志在
`%APPDATA%\SP\SP Player\logs\`。手动验证服务：
`http://127.0.0.1:8000/health` 应返回 `{"ok":true,"model":"large-v3-turbo",...}`。

**点「重新转写」弹黑框**
0.10.3 已修复：子进程通过 `hidden_process.dart`（CREATE_NO_WINDOW）静默启动。

**打开视频黑屏 / 画面闪烁**
0.10.3 已修复：黑屏根因是表面注册表所有权竞态导致视频舞台被卸载；
闪烁是旧版「踢帧」补丁的副作用，两者都已移除。

**识别速度慢**
CPU 上 `large-v3-turbo` 约 1.8× 实时（5 分钟视频 ≈ 3 分钟），i7-1360P 实测。
有 NVIDIA 显卡会自动走 CUDA，快一个量级。

**提示「文件过大，无法生成字幕」**
单次抽音轨上限 500 MB wav，正常剧集碰不到；超长有声书先导出音频再分卷。

**双击 exe 报缺少 DLL**
只拷了 exe，没拷同目录的 dll。整个 `Release` 目录一起拿走。

**原作者更新了要不要合**
不建议。这边删了他 133 个文件，合并必然大面积冲突。要新功能去他仓库看，手动挑。

---

## 八、许可与来源

本仓库是 [baizhiheizi/enjoy_player](https://github.com/baizhiheizi/enjoy_player) 的**修改版**，
不是原项目，也不提供原项目的安装包或服务。

按 **AGPL-3.0** 发布，见 [LICENSE](LICENSE)；`packages/ffmpeg_kit_flutter_new`
等第三方组件的版权声明一并保留。
