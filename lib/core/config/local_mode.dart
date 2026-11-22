/// 本地离线模式的编译期开关。
///
/// 打开后：
///  * 不再强制登录 —— [resolveAuthRedirect] 对所有路由直接放行；
///  * BYOK 的 base URL 允许 `http://` 与 localhost / 私网地址，方便接
///    本机 faster-whisper 服务（`http://127.0.0.1:8000/v1`）和本地模型网关；
///  * 语音识别 / 大模型默认走 BYOK，不再回落到 Enjoy 云端 worker。
///
/// 要恢复上游行为，把它改成 `false` 即可。
library;

const bool kLocalOfflineMode = true;
