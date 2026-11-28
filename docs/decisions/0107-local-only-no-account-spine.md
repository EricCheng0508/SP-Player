# ADR-0107: 本地版移除账号/积分/云同步脊柱

## Status

Accepted（2026-11-28，用户确认执行）

## Context

本地版（无账号分发）此前仍保留上游 Enjoy 账号体系的完整脊柱：登录（邮箱 OTP / Google / Apple + PKCE 深链）、按用户隔离的 SQLite 会话、`sync_queue` 出站云同步、云端 worker API（audio/video/recording/vocabulary/transcript/user/auth/stats/direct_uploads）、积分与订阅（402 配额、套餐 CTA、checkout 路由）。这些功能在本地版全部不可达或无意义：worker API 已无调用方，登录后才能用的入口在 L1 已清（设置页云同步区块、checkout/sign-in 路由、`/cloud` 死路由），但脊柱代码本身仍在，拖着 `ApiClient`/token 刷新/多会话 DB 切换等大量死基础设施，编译期还产生约 900 个测试错误与持续的红树基线（lookup 门禁/积分横幅等 ~22 个远端时代断言）。

## Decision

整体删除脊柱（分两轮：L1 可见残留先行，本 ADR 覆盖 L2/L3 脊柱手术）：

1. **删除** `lib/features/sync`（全部）、`lib/features/auth`（全部；`AuthRequiredCallout` 已是 BYOK 提示，迁至 `lib/features/lookup/presentation/widgets/`，类名沿用上游以减少调用点改动）、云端 API services 九件 + `api_client.dart`/`rest_api.dart`/`rest_repository.dart`/`api_client_dispatch|decoding|uploads`/`case_conversion`/`json_isolate`/`query_params`/`secure_token_store`、`SyncQueueDao`、`AuthFailure`/`AuthFailureCode`/`SubscriptionConflictFailure` 失败类型。
2. **单一本地会话**：`appDatabaseProvider` 直接打开 `enjoy_player_local.sqlite`，不再等待登录态、不再按用户切换/驱逐；`kLocalOfflineMode` 编译开关删除（local_mode.dart 只留 `kLocalSessionId`），行为即唯一路径。
3. **积分死路径切除**：全部存活的 `ApiException` 来源要么 `byokProvider: true`（BYOK 端点 402 → `ProviderBillingFailure`），要么固定 400/502/503 —— `CreditsFailure` 及其 UI 管线（`runAiCall.onCredits`、积分横幅、`LookupCreditsNotice`、craft/pronounce/shadow-reading 的 credits 传参）不可达，一并删除。
4. **保留**：discover 的 YouTube 频道订阅仍走 worker RSSHub 代理（唯一 worker 依赖，删除 token 鉴权头后以无鉴权请求）；BYOK 基础设施（`byok_secret_store`、`secure_storage_*` 三件、`api_exception.dart`）保留。
5. **Drift schema 不迁移**：`syncStatus`/`serverUpdatedAt` 列与 `sync_queue` 表保留在 schema 里（休眠，无 Dart 读写）；旧安装遗留的 `enjoy_player_<userId>.sqlite` 文件不被打开，GC 的跨文件探测仍覆盖它们。

## Consequences

- `settings` 里的 `apiBaseUrl`/`apiAiBaseUrl` 键与 l10n 的登录/积分文案成为休眠数据/键值，保留以避免测试夹具与 schema 连锁改动。
- analytics 不再 identify/reset；super properties 只剩 locale / 学习语言 / 分发渠道。
- 上游若恢复账号功能，需要按 0006/0010/0013/0031 重新实现，本 ADR 是反向决策记录。
- 后续新增网络能力一律走 BYOK 模式；worker 只服务 discover feed。
