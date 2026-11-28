/// 本地离线模式的编译期开关。
///
/// 打开后：
///  * 不再强制登录 —— [resolveAuthRedirect] 对所有路由直接放行；
///  * 没有登录态可用，全部用户级数据（书库 / 偏好 / 生词本）固定落在
///    [kLocalSessionId] 这一个本地会话上（`enjoy_player_local.sqlite`），
///    不再等待 `AuthSignedIn`；
///  * BYOK 的 base URL 允许 `http://` 与 localhost / 私网地址，方便接
///    本机 faster-whisper 服务（`http://127.0.0.1:8000/v1`）和本地模型网关；
///  * 语音识别 / 大模型默认走 BYOK，不再回落到 Enjoy 云端 worker。
///
/// 要恢复上游行为，把它改成 `false` 即可。
library;

const bool kLocalOfflineMode = true;

/// 无账号版本里唯一的会话 id —— 等价于「这台机器只有一个用户」。
const String kLocalSessionId = 'local';
