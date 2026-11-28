/// 无账号版本的本地会话常量。
///
/// 这台机器只有一个用户：全部用户级数据（书库 / 偏好 / 生词本）固定落在
/// [kLocalSessionId] 这一个本地会话上（`enjoy_player_local.sqlite`）。
library;

/// 无账号版本里唯一的会话 id —— 等价于「这台机器只有一个用户」。
const String kLocalSessionId = 'local';
