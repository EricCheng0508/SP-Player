# SP Player

本地优先的外语精听播放器（Windows）。无账号、无订阅、无云端依赖；
AI 只连你自己填的端点，语音识别和翻译都可以完全跑在本机，音频不出机器。

基于 [baizhiheizi/enjoy_player](https://github.com/baizhiheizi/enjoy_player)
（AGPL-3.0）修改，沿用同一许可证，见 [LICENSE](LICENSE)。

## 它能做什么

- **精听播放**：本地视频 / YouTube，逐句循环、跟读、听写、生词本
- **字幕**：内置 faster-whisper（large-v3-turbo）本地生成，或导入 SRT /
  抓取 YouTube 自带字幕；词级卡拉OK高亮
- **AI 翻译**：整屏句子自动合批为一次 LLM 调用（省 token、更快、上下文更准），
  支持任何 OpenAI 兼容端点（云端 API 或 Ollama / LM Studio 等本地模型）
- **本地翻译**：llama.cpp + TranslateGemma 4B，完全离线
- **发音**：有道真人发音，单词即点即读

## 架构一览

| | 是什么 | 干什么 |
|---|---|---|
| 播放器 | 本仓库，Flutter + libmpv | 播放、字幕、逐句练 |
| 本地组件 | faster-whisper + llama.cpp | 语音识别、离线翻译 |

播放器自带识别服务的托管：静默拉起、端口探测、退出即回收，
监听 `http://127.0.0.1:8000/v1`，不需要外挂任何脚本。

## 构建与运行

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build windows --release
```

产物在 `build\windows\x64\runner\Release\`，整个目录一起拷走即可运行
（首次使用需在应用内安装本地组件，或预置到 `components\` 目录）。

识别模型与运行时通过 GitHub 的 `components-v1` release 分发
（单资产超 2GiB，不随安装包走）。

## 环境要求

- Flutter 3.x（桌面 stable）
- Visual Studio 2022，含「使用 C++ 的桌面开发」负载
- Python 3.10+（faster-whisper 依赖）
- FFmpeg（essentials 构建）

## 与原项目的差别

删掉了账号、积分、云端分发等 133 个文件（约 −12700 行），
替换为本地实现：faster-whisper 识别、llama.cpp 翻译、BYOK 端点直连。
不建议与上游合并——改动面太大，冲突必然大面积出现。

## 许可

AGPL-3.0。第三方组件（`packages/ffmpeg_kit_flutter_new` 等）版权声明一并保留。
