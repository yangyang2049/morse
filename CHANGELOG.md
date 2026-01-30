# Changelog

## [2.0.0] - 2026-01-30

### 变更

- **主应用「其他应用」增加第三个应用「码上学」**：在「我」页其他应用区域新增「码上学」（Rust Master）卡片，图标使用 rustmaster 项目的 startIcon（已复制为 `rawfile/appicon_rustmaster.png`），点击跳转应用市场或浏览器打开 `https://appgallery.huawei.com/app/detail?id=com.douhua.rustmaster`；中文名「码上学」、英文名「Rust Master」来自 rustmaster 项目。
- **手表端首页右滑退出**：参考 WATCH/zhaocha 项目，改用 ArcSwiper 的 `onGestureRecognizerJudgeBegin` 实现。在首页（学习 tab）右滑时返回 `GestureJudgeResult.REJECT`，由系统处理退出手势；非首页右滑返回 `CONTINUE`，由 ArcSwiper 正常切换 tab。移除原先的 PanGesture + terminateSelf 方式，解决首页右滑无法退出的问题。
