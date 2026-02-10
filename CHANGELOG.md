# Changelog

## [2.1.0] - 2026-01-30

### 变更

- **练习页、翻译页与「我」页双键设置一致**：练习页（PracticePage）原先使用 `practice_preferences` 存储，与「我」页、课程页使用的 `practice_settings` 不一致，导致在「我」页改为双键后练习页和翻译页不生效。练习页已改为使用 `practice_settings`；练习页与翻译页均在 `onPageShow` 中重新加载按键模式与长按阈值，从「我」页返回后即可看到更新后的单/双键状态。
- **翻译页按键设置实时更新**：翻译页作为 Tab 内组件，切换 Tab 不会触发页面 onPageShow，故仅在首次加载时读一次按键设置。现通过 AppStorage 通知：在「我」页保存按键设置后递增 `practice_settings_version`，翻译页使用 `@StorageLink` + `@Watch` 监听该变化并重新从 `practice_settings` 加载单/双键与长按阈值，切回翻译 Tab 即可看到最新按钮状态。
- **翻译页单/双键改为全局设置**：翻译页不再提供单独的单双键切换文案，与课程页、练习页一致从 practice_settings 读取；仅在「我」页「按键设置」中修改即可全局生效。
- **我页文案本地化**：分享（share_title、share_description、share_text）、复制成功提示（share_copied、copied）、展开/收起（expand、collapse）、其他应用名称（app_name_caikuai、app_name_dev_assistant、app_name_rustmaster）改为使用 string 资源，并已在 base / en_US / zh_HK 补齐。
- **我页合并输入模式与按键设置为「按键设置」**：移除单独的「输入模式」入口；「按键设置」对话框内先选单键/双键（默认双键），选单键时再显示长按阈值滑块（100–600ms），确认时一并保存至 practice_settings。
- **练习页移除设置按钮，按键设置移至我页**：练习页（PracticePage）单键模式下的设置按钮已移除；长按时间等并入「我」页「按键设置」。
- **主应用点/划输入按钮统一为黄底黑字**：翻译页、课程页（LetterLessonPage）、练习页（PracticePage）中单键与双键的点/划按钮（不含斜杠、空格、删除）改为背景 #FFD700、图标/文字 #000000；LessonDetailPage、PracticeDetailPage 原已是黄底黑字未改。
- **智能体入口仅手机/平板展示**：学习 tab 底部「摩斯电码冷知识」小艺智能体入口仅在手机、平板上显示，手表等设备不展示（通过 DeviceHelper 判断）。
- **首页智能体按 HMAF 文档调起**：学习 tab 底部「摩斯电码冷知识」改为使用 [HMAF Function 组件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hmaf-function)（`@kit.AgentFrameworkKit` 的 `FunctionComponent`）调起小艺智能体，传入 `agentId`、本地化 `title` 与 `queryText`；`onError` 时回退为通过浏览器打开智能体页并带本地化 prompt。依赖 HarmonyOS 6 SDK 中的 AgentFrameworkKit。
- **首页底部小艺智能体入口**：学习 tab 底部增加「摩斯电码冷知识」入口，文案与指令已本地化（base / en_US / zh_HK）。
- **翻译页单/双按钮文案间距**：增大「单按钮/双按钮」切换文案与上方点划按钮的间距（margin top 4→20）。
- **课程页进度环显示修正**：LetterLessonViewModel 中 `getCircumference()` 原按半径 80 计算，与页面 ProgressCircle 的 220×220 圆（半径 110）不一致，导致进度 1/3 时弧长与起点偏移错误；改为按半径 110 计算周长，与 UI 一致。
- **LetterLessonPage 遵守输入模式设置**：字母/数字/符号课程页从 `practice_settings` 读取 `use_single_button` 与 `long_press_threshold`，非单词课程时按设置显示单键（短按点、长按划）或双键（点、划）；单词课程仍为三点（点、空格、划）布局。
- **主应用「其他应用」增加第三个应用「码上学」**：在「我」页其他应用区域新增「码上学」（Rust Master）卡片，图标使用 rustmaster 项目的 startIcon（已复制为 `rawfile/appicon_rustmaster.png`），点击跳转应用市场或浏览器打开 `https://appgallery.huawei.com/app/detail?id=com.douhua.rustmaster`；中文名「码上学」、英文名「Rust Master」来自 rustmaster 项目。
- **手表端首页右滑退出**：参考 WATCH/zhaocha 项目，改用 ArcSwiper 的 `onGestureRecognizerJudgeBegin` 实现。在首页（学习 tab）右滑时返回 `GestureJudgeResult.REJECT`，由系统处理退出手势；非首页右滑返回 `CONTINUE`，由 ArcSwiper 正常切换 tab。移除原先的 PanGesture + terminateSelf 方式，解决首页右滑无法退出的问题。
