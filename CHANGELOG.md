# Changelog

## [Unreleased]

### 变更

- **发布前修复**：watch Index 移除未使用的 ArcSwiperAttribute 导入；watch LessonDetailPage 退出时保存进度 key 补全 punctuation_progress，与 saveLessonProgress 一致。
- **手表课程完成页最后一组只显示返回**：完成最后一组时仅显示「返回」按钮，点击退出；非最后一组显示「下一组」+「返回」。
- **手表课程完成页两按钮间距缩小**：「下一组」与「返回」之间仅 6px，返回贴底。
- **手表课程详情页去掉最外层 Scroll**：主内容 Column 直接作为 Stack 子节点，ArcButton 贴底；完成页布局收紧、返回贴底。
- **手表端移除双键模式**：手表仅支持单键 ArcButton。LessonDetailPage、PracticeDetailPage、PracticeMistakesPage 移除 @State useSingleButton、loadButtonModePreference 及双键分支（点/划两个 Button 的 Row），仅保留 ArcButton 单键输入。
- **手表课程详情页移除删除/清除按钮**：watch LessonDetailPage 单键与双键模式下均移除「删除」「清除」两枚按钮，ArcButton 贴底无间隙。
- **手表端所有 tab 标题改为黄色**：LearnPage、PracticePage、CodeTablePage、SettingsPage 的标题栏文字由 #FFFFFF 改为 #FFD700，与主题色一致。
- **手表练习详情页 text-to-code 布局：ArcButton 贴底无间隙**：watch PracticeDetailPage 的 text_to_code 模式用外层 Column 包裹并设 layoutWeight(1)、height('100%')，内容区 Column 设 layoutWeight(1) 占满剩余高度，单键 ArcButton 改为 margin bottom 0，贴底部边缘无间隙。
- **手表练习详情页 ArcButton、本地化与结构修复**：watch PracticeDetailPage 单键模式改为使用 ArcButton（BOTTOM_EDGE、金色样式），与 LessonDetailPage、PracticeMistakesPage 一致；答案展示区用 Column 包裹，修复多根节点导致的编译错误；文案已通过 LocalizationHelper 本地化（watch_correct、watch_wrong、watch_correct_answer、watch_next_question、watch_guide_*、watch_try_again 等）。
- **手表课程详情页布局收紧、ArcButton 完全可见**：watch LessonDetailPage 缩小垂直间距（字母行/字符/摩斯/输入区 margin 8→4、12→6，大字符 64→56、摩斯 22→20，输入区 height 32→28、padding 8→6），内容区用 Column+layoutWeight(1) 占满剩余高度，单键 ArcButton margin 改为 top:4、bottom:0 贴底，控制按钮行 height 32→28、间距收紧；整体 padding 8→4，确保 ArcButton 在屏幕内完全可见。
- **手表课程详情页 ArcButton 与双键样式统一**：watch LessonDetailPage 单键 ArcButton 外边距改为 `top: 8, bottom: 8` 与 PracticeDetailPage 一致；双键模式点/划按钮由 55×55、borderRadius 28 改为 60×60、borderRadius 30，与手表练习页一致。页面已使用 ArcButton 且所有文案均通过 LocalizationHelper 本地化。
- **单键模式改为手绘圆点**：单键「·」由 Text 改为 Circle(20,20).fill('#444444')，与双键点按钮一致（LetterLessonPage、PracticePage、TranslatePage、PracticeDetailPage、watch PracticeDetailPage、LessonDetailPage、watch LessonDetailPage、watch PracticeMistakesPage）；手机 PracticeDetailPage 单键仍为 ArcButton 的 label，未改。
- **点/划输入按钮颜色调淡**：单键「·」文字与双键 ·/- 按钮文字/图形均由 #000000 改为 #444444；双键模式下点/划为 Circle、Rect 图形（非文字），LetterLessonPage、PracticePage、TranslatePage 中其 .fill 已一并改为 #444444。
- **点/划输入按钮文字缩小**：单键「·」与双键 ·/- 输入按钮字体统一改为 16（LetterLessonPage、PracticePage、TranslatePage、PracticeDetailPage、watch 各练习/课程页）。
- **设置页公司名称**：watch_company_name 改为「重庆豆花科技有限公司」（base/zh_HK），英文为 Chongqing Douhua Technology Co., Ltd.。
- **手表错题页去掉右上角返回按钮**：PracticeMistakesPage 移除右上角 Back 按钮，保留手势或页面内返回方式。
- **练习模式文本→代码：内容区加高、ArcButton 贴底**：手表 PracticeDetailPage 的 text_to_code 外层 Column 增加 `.layoutWeight(1).width('100%')`，内容区占满剩余高度，单键 ArcButton 贴底部边缘。
- **手表练习页单键改为 ArcButton**：PracticeDetailPage 单键模式由普通 Button+Circle 改为 ArcButton（BOTTOM_EDGE、金色样式），与 LessonDetailPage、PracticeMistakesPage 一致，保留 onTouch 短按/长按逻辑。
- **手表端文案全部本地化**：核对 watch 页面所用字符串，补全并统一本地化。新增 `hint`、`watch_guide_click_to_input_code`（base/en_US/zh_HK）；LearnPage「标点」改为 `punctuation`，LessonDetailPage/PracticeDetailPage 引导框「提示」及「点击输入电码…」改为 `hint`、`watch_guide_click_to_input_code`。所有 watch 用到的 key 均在 base/en_US/zh_HK 中有对应条目。
- **手表隐私页布局改为与 2048 一致**：使用 ArcButton 作为「同意」按钮（底部弧形）、退出为上方 Text 样式；二维码区域改为 35% 宽高比、Scan 提示在下方；整体为 Scroll + 底部按钮区。
- **修复手表端按钮/文字不可见（根本原因：字符串资源缺失）**：手表端所有 watch 页面引用的 35 个字符串 key（如 watch_settings、watch_vibration_feedback、agree、exit_app、scan_to_read 等）从未在任何 string.json 中定义过，导致 `$r('app.string.xxx')` 返回空值、Text/Button 文字不可见。已将全部缺失的字符串补齐到 base/element/string.json（中文）、en_US/element/string.json（英文）、zh_HK/element/string.json（繁体中文）。同时此前已将 base 颜色定义补齐到 wearable/element/color.json。
- **码上学英文名**：其他应用「码上学」英文显示由 Rust Master 改为 Code Now（en_US string）。
- **练习页候选选项去掉边框**：PracticeDetailPage、PracticePage 中 code_to_text / sound_to_text 的候选格选项不再显示边框（.border 已移除）。
- **第 3 次错误高亮正确答案后先取消高亮再进入下一题**：手表 PracticeDetailPage 在约 1s 后取消候选格高亮并清空选择，再进入下一题；手机 PracticePage 在约 1s 后将 candidateWrongTries 置 0 以取消高亮，恢复为与第 1、2 次错误相同的无高亮状态。
- **手表/手机练习页 code-to-text、sound-to-text 第 3 次错误才高亮正确答案**：watch PracticeDetailPage 使用 showCorrectInGrid 布尔量，仅在错误次数 ≥3 时在候选格高亮正确答案；手机 PracticePage 的 code_to_text、sound_to_text 增加 candidateWrongTries，选错时前两次不显示正确答案高亮，第 3 次选错时才在候选格高亮正确答案；换题或切换类别时重置计数。

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
