# SP Player 本地版

> 只在自己电脑上用的外语精听播放器。无账号、无订阅、无积分、无云端；
> AI 只连自己填的端点，字幕识别用本机的 faster-whisper。
>
> 基于 [baizhiheizi/enjoy_player](https://github.com/baizhiheizi/enjoy_player)（AGPL-3.0）修改，
> 沿用同一许可证，详见 [LICENSE](LICENSE)。

这个仓库只有一个用途：**本机那份 202 MB 的 exe 哪天删了、系统重装了，
从这里 clone 下来照着下面几步就能装回来，不用再回忆当初怎么弄的。**

---

## 一、这套东西由两块组成

| | 是什么 | 在哪 | 干什么 |
|---|---|---|---|
| **播放器** | 本仓库，Flutter + libmpv | `D:\code\idea\sp_player` → 编译到 `D:\Tool\SPPlayer-Local` | 播放、字幕、跟读、生词本、AI 翻译 |
| **字幕引擎** | Python + faster-whisper | `D:\Tool\subgen`（独立项目） | 音频转带时间轴的字幕，也能给播放器当识别服务 |

播放和识别都在本地，音频不出机器。翻译、查词走你自己填的 OpenAI 兼容端点。
识别模型 `large-v3`（2.9 GB），首次运行自动下载。

---

## 二、从 GitHub 拉下来之后怎么恢复

### 1. 构建环境（只需一次）

| 需要 | 版本 | 本机参考路径 |
|---|---|---|
| Flutter | 3.50.1（Dart 3.14） | `D:\Tool\flutter` |
| Visual Studio 2022 | 含「使用 C++ 的桌面开发」负载 | `D:\IDE\VS2022` |
| NuGet CLI | 任意 | `D:\Tool\nuget` |
| FFmpeg | essentials 构建 | 见第 2 步 |

Flutter 需要的四个环境变量：

```
PATH                     += D:\Tool\flutter\bin
FLUTTER_ROOT              = D:\Tool\flutter
FLUTTER_STORAGE_BASE_URL  = https://storage.flutter-io.cn
PUB_HOSTED_URL            = https://pub.flutter-io.cn
```

### 2. 取 ffmpeg.exe

仓库里**不含** ffmpeg：单个文件 100.5 MB，超过 GitHub 单文件硬上限 100 MiB，推不上去。
用官方脚本下载到 `windows\ffmpeg\ffmpeg.exe`，编译时 CMake 会自动复制到 exe 旁边：

```powershell
pwsh windows/scripts/fetch_ffmpeg.ps1
```

已经有现成的也可以直接拷：`copy "D:\Tool\Enjoy Player\ffmpeg.exe" windows\ffmpeg\`

> **不做这一步，「提取字幕」和「提取内嵌字幕」都会失败。**
> 应用找的是 `sp_player.exe` 同目录下的 `ffmpeg.exe`，其次才是 PATH。

### 3. 编译

```powershell
cd D:\code\idea\sp_player
flutter pub get
flutter build windows --release
```

产物在 `build\windows\x64\runner\Release\`，**整个目录**复制过去：

```powershell
robocopy build\windows\x64\runner\Release D:\Tool\SPPlayer-Local /E
```

> 不能只拿 `sp_player.exe`——它只有 0.1 MB。主体是旁边的
> `data\app.so`（16.7 MB）、`libmpv-2.dll`（29 MB）、`flutter_windows.dll`（21 MB）、
> `ffmpeg.exe`（101 MB），合计约 202 MB。

### 4. 起本地字幕服务（要用应用内「提取字幕」就必须）

```powershell
D:\Tool\subgen\start-asr-server.bat
```

窗口出现 `Uvicorn running on http://127.0.0.1:8000` 即可。模型冷加载 30–60 秒，
之后常驻显存；这个窗口不要关。

### 5. 应用内配置

播放器 → **设置 → AI → AI 提供商**：

| 标签 | 字段 | 填什么 |
|---|---|---|
| **语言模型** | API 规范 | OpenAI |
| | Base URL | `http://127.0.0.1:3425/v1`（你自己的网关，或任意 OpenAI 兼容端点） |
| | API Key | 你的 key |
| | 模型 | 你的模型名 |
| **语音识别** | API 规范 | OpenAI |
| | Base URL | `http://127.0.0.1:8000/v1` |
| | API Key | 随便，如 `local`（本地服务不校验） |
| | 模型 | `large-v3` |

---

## 三、字幕怎么来（两条路，别混）

| | **应用内「提取字幕」** | **subgen 拖拽生成 .srt** |
|---|---|---|
| 入口 | 播放器里对某个视频点「生成字幕」 | 把视频拖到 `make-srt.bat` / `make-bilingual.bat` |
| 前提 | 第 4 步的服务在跑 | 不需要服务 |
| 产物 | 直接写进应用数据库，立刻能逐句练 | 同目录生成 `.srt` / `.vtt` 文件 |
| 双语 | 生成后靠 AI 翻译逐句翻 | 一步到位出 `.zh.srt` + `.bilingual.srt` |
| 适合 | 边看边补字幕 | 批量处理、要现成的双语字幕文件 |

### 应用内「提取字幕」到底做了什么

```
点「生成字幕」
  → 选语言（可自动检测）
  → 长音频弹一次确认框（提示要几分钟；识别在本机，不产生任何费用）
  → 用 exe 旁边的 ffmpeg.exe 抽 16k 单声道 wav
  → POST http://127.0.0.1:8000/v1/audio/transcriptions
        response_format=verbose_json（强制，为了拿到逐句 segments）
  → 得到 [{start, end, text}, ...]
  → 写成 source='ai' 的字幕轨，存进本地 SQLite
```

**它不生成 .srt 文件，而是直接进库。** 想导出文件走 subgen 那条路。

超过 15 分钟会走「长音频」分支，但 BYOK 模式下没有远端任务队列，实际就是
**整段 wav 一次性 POST 过去**。22 分钟的剧集约 40 MB 上传 + 50 秒识别，环回没问题。

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

### 保留的

- 本地播放、导入、字幕、逐句循环、跟读、听写、生词本
- 单视频 YouTube 导入（本地 InnerTube 抓字幕，不经过任何远端）
- AI 翻译 / 查词 / 语境翻译，全部 BYOK
- 应用内语音识别，走本地 Whisper 服务

### 仍会碰到原服务器的唯一功能

频道订阅 / 播放列表（`features/discover`）：粘 `@频道` 或播放列表链接时，
本地没有等价实现，只能拼 `worker.enjoy.bot/youtube/channel/...`。
**单视频导入完全不受影响**：解析 ID → `youtube.com/oembed` 取标题 → WebView 播放
→ 本地抓字幕，全程直连 Google。

---

## 六、以后想改代码，从这几个文件入手

| 文件 | 作用 |
|---|---|
| `lib/core/config/local_mode.dart` | `kLocalOfflineMode = true`，本地化分支总开关 |
| `lib/features/ai/data/byok/byok_url_guard.dart` | 放行 http / localhost / 私网（默认只准 https） |
| `lib/features/ai/data/byok/byok_asr_openai_capability.dart` | 强制 `verbose_json`，否则字幕时间被均分 |
| `lib/features/ai/data/byok/byok_whisper_client.dart` | 上传 wav 到识别端点 |
| `lib/features/asr/application/asr_generation_controller.dart` | 「提取字幕」流程编排 |
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
先看服务活着没：浏览器打开 `http://127.0.0.1:8000/health`，应返回
`{"ok":true,"model":"large-v3","device":"cuda"}`。再确认设置里的 Base URL 带 `/v1`。

**提示「文件过大，无法生成字幕」**
单次抽音轨上限 500 MB wav，正常剧集碰不到；超长有声书先用 subgen 生成 srt 再导入。

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
