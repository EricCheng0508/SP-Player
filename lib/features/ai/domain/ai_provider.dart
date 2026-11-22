/// Where AI inference runs.
///
/// 本地版：只剩用户自备的端点（BYOK）。Enjoy 云端 worker 已整体删除，
/// 这个枚举保留单值是为了兼容持久化格式与既有调用点。
enum AIProvider { byok }
