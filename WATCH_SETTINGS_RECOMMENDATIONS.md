# Watch App Settings Recommendations

## 概述
本文档列出了手表应用（Watch App）应该包含的设置项，基于当前代码分析、主应用功能以及手表设备特性。

---

## 当前状态

### 已实现的设置
- ✅ **振动反馈** (`vibrationEnabled`) - 已实现

### 代码中已使用但未在设置中暴露的
- ⚠️ **单键/双键模式** (`useSingleButton`) - 在 `LessonDetailPage` 和 `PracticeDetailPage` 中使用，但未在设置页面暴露
- ⚠️ **长按时间阈值** (`longPressThreshold`) - 在 `LessonDetailPage` 和 `PracticeDetailPage` 中使用，但未在设置页面暴露

---

## 推荐设置项

### 1. 输入设置（高优先级）

#### 1.1 输入模式
**设置项**: 单键模式 / 双键模式
**类型**: Toggle 或选择器
**默认值**: 单键模式
**说明**: 
- 单键模式：短按输入点（·），长按输入划（-）
- 双键模式：两个按钮分别输入点和划
- 适合不同用户习惯和手表硬件配置

**实现位置**: `WatchIndexPage.ets` SettingsTab
**存储键**: `use_single_button` (已存在于 `practice_settings`)

#### 1.2 长按时间阈值
**设置项**: 长按时间（毫秒）
**类型**: Slider
**范围**: 100ms - 600ms
**默认值**: 300ms
**步进**: 25ms
**说明**: 
- 控制单键模式下，按下多长时间算作长按（划）
- 太短容易误触，太长影响输入速度
- 用户可以根据自己的反应速度调整

**实现位置**: `WatchIndexPage.ets` SettingsTab
**存储键**: `long_press_threshold` (已存在于 `practice_settings`)

---

### 2. 音频设置（中优先级）

#### 2.1 声音开关
**设置项**: 声音反馈
**类型**: Toggle
**默认值**: 开启
**说明**: 
- 控制播放摩斯码音频反馈
- 手表可能没有扬声器，但可以连接蓝牙耳机
- 关闭后只使用振动反馈

**实现位置**: `WatchIndexPage.ets` SettingsTab
**存储键**: `sound_enabled` (需要添加到 `practice_settings`)

#### 2.2 音频播放速度（可选）
**设置项**: 播放速度
**类型**: Slider 或选择器
**范围**: 0.5x - 2.0x
**默认值**: 1.0x
**说明**: 
- 调整摩斯码音频播放速度
- 适合不同学习阶段（初学者可以慢速，熟练后可以快速）
- 需要修改 `AudioService` 支持播放速度调节

**实现位置**: `WatchIndexPage.ets` SettingsTab
**存储键**: `audio_playback_speed` (需要添加到 `practice_settings`)

---

### 3. 学习设置（中优先级）

#### 3.1 自动检查延迟
**设置项**: 自动检查延迟
**类型**: Slider 或选择器
**选项**: 
- 快速 (500ms)
- 标准 (1000ms) - 默认
- 慢速 (1500ms)
**说明**: 
- 控制输入后多长时间自动检查答案
- 快速适合熟练用户，慢速适合初学者
- 当前代码中硬编码为 1000ms 或 1500ms

**实现位置**: `WatchIndexPage.ets` SettingsTab
**存储键**: `auto_check_delay` (需要添加到 `practice_settings`)

#### 3.2 正确反馈延迟
**设置项**: 正确后切换延迟
**类型**: Slider
**范围**: 200ms - 1000ms
**默认值**: 500ms
**说明**: 
- 控制答对后多长时间切换到下一个字符/题目
- 给用户时间看到正确的反馈
- 当前代码中硬编码为 500ms

**实现位置**: `WatchIndexPage.ets` SettingsTab
**存储键**: `correct_feedback_delay` (需要添加到 `practice_settings`)

---

### 4. 显示设置（低优先级）

#### 4.1 字体大小
**设置项**: 字体大小
**类型**: 选择器
**选项**: 
- 小
- 标准 - 默认
- 大
**说明**: 
- 调整主要文字的字体大小
- 适合不同视力需求和手表屏幕大小
- 需要定义字体大小常量

**实现位置**: `WatchIndexPage.ets` SettingsTab
**存储键**: `font_size` (需要添加到 `app_preferences`)

#### 4.2 显示模式（可选）
**设置项**: 显示模式
**类型**: 选择器
**选项**: 
- 紧凑 - 默认
- 宽松
**说明**: 
- 调整元素间距和布局
- 紧凑模式显示更多内容，宽松模式更易阅读

**实现位置**: `WatchIndexPage.ets` SettingsTab
**存储键**: `display_mode` (需要添加到 `app_preferences`)

---

### 5. 数据管理（低优先级）

#### 5.1 重置进度
**设置项**: 重置学习进度
**类型**: 按钮（带确认对话框）
**说明**: 
- 清除所有学习进度数据
- 包括字母课程进度、数字课程进度、基础课程完成状态
- 需要二次确认，防止误操作

**实现位置**: `WatchIndexPage.ets` SettingsTab
**存储键**: 不需要存储，直接清除相关数据

#### 5.2 导出/导入数据（可选，未来功能）
**设置项**: 数据同步
**类型**: 按钮
**说明**: 
- 导出学习数据到手机应用
- 或从手机应用导入数据
- 需要实现数据同步机制

**实现位置**: `WatchIndexPage.ets` SettingsTab
**存储键**: 不需要存储

---

### 6. 操作功能（中优先级）

#### 6.1 意见建议
**设置项**: 意见建议
**类型**: 按钮（打开反馈对话框）
**说明**: 
- 允许用户提交反馈、建议或报告问题
- 可以包含邮箱地址或反馈表单
- 参考 zhaocha 项目的反馈功能实现

**实现位置**: `WatchIndexPage.ets` SettingsTab
**存储键**: 不需要存储

#### 6.2 分享应用
**设置项**: 分享给朋友
**类型**: 按钮（打开系统分享面板）
**说明**: 
- 使用系统分享功能分享应用
- 可以分享应用链接或二维码
- 参考 zhaocha 项目的分享功能实现

**实现位置**: `WatchIndexPage.ets` SettingsTab
**存储键**: 不需要存储

---

### 7. 关于信息（低优先级）

#### 7.1 应用信息
**设置项**: 关于
**类型**: 按钮（跳转到关于页面或显示对话框）
**显示内容**: 
- 应用名称
- 版本号
- 开发者信息
- 使用说明链接

**实现位置**: `WatchIndexPage.ets` SettingsTab

---

## 实现建议

### 设置页面布局结构

```typescript
@Builder SettingsTab() {
  Column() {
    // 标题栏
    Text('设置')
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#FFFFFF')
      .width('100%')
      .textAlign(TextAlign.Center)
      .margin({ top: 15, bottom: 10 })
    
    Scroll() {
      Column() {
        // 1. 输入设置
        this.InputSettingsSection()
        
        // 2. 音频设置
        this.AudioSettingsSection()
        
        // 3. 学习设置
        this.LearningSettingsSection()
        
        // 4. 显示设置（可选）
        this.DisplaySettingsSection()
        
        // 5. 数据管理
        this.DataManagementSection()
        
        // 6. 关于
        this.AboutSection()
      }
      .width('80%')
      .padding(16)
    }
    .layoutWeight(1)
    .width('100%')
  }
  .width('100%')
  .height('100%')
  .backgroundColor('#000000')
}
```

### 设置项组件模板

```typescript
// Toggle 设置项
@Builder ToggleSettingItem(title: string, value: boolean, onChange: (value: boolean) => void) {
  Row() {
    Text(title)
      .fontSize(16)
      .fontColor('#FFFFFF')
      .layoutWeight(1)
    
    Toggle({ type: ToggleType.Switch, isOn: value })
      .selectedColor('#FFD700')
      .onChange(onChange)
  }
  .width('100%')
  .height(48)
  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
  .backgroundColor('rgba(255, 255, 255, 0.1)')
  .borderRadius(8)
  .margin({ top: 6, bottom: 6 })
}

// Slider 设置项
@Builder SliderSettingItem(title: string, value: number, min: number, max: number, 
                           step: number, unit: string, onChange: (value: number) => void) {
  Column() {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .layoutWeight(1)
      
      Text(`${value}${unit}`)
        .fontSize(14)
        .fontColor('#FFD700')
    }
    .width('100%')
    .margin({ bottom: 8 })
    
    Slider({
      value: value,
      min: min,
      max: max,
      step: step
    })
    .blockColor('#FFD700')
    .trackColor('#333333')
    .selectedColor('#FFD700')
    .onChange(onChange)
  }
  .width('100%')
  .padding({ left: 12, right: 12, top: 12, bottom: 12 })
  .backgroundColor('rgba(255, 255, 255, 0.1)')
  .borderRadius(8)
  .margin({ top: 6, bottom: 6 })
}
```

---

## 优先级建议

### 第一阶段（立即实现）
1. ✅ **振动反馈** - 已完成
2. **输入模式** - 单键/双键切换
3. **长按时间阈值** - Slider 调节

### 第二阶段（近期实现）
4. **声音开关** - Toggle
5. **自动检查延迟** - 选择器或 Slider
6. **正确反馈延迟** - Slider
7. **意见建议** - 按钮（参考 zhaocha 项目）
8. **分享应用** - 按钮（参考 zhaocha 项目）

### 第三阶段（优化改进）
9. **字体大小** - 选择器
10. **重置进度** - 按钮
11. **关于信息** - 按钮
12. **版本信息** - 显示版本号（参考 zhaocha 项目）

### 第四阶段（未来功能）
13. **音频播放速度** - Slider
14. **显示模式** - 选择器
15. **数据同步** - 按钮
16. **练习限时模式** - 选择器（参考 zhaocha 项目的限时功能）

---

## 存储结构建议

### Preferences 存储键

```typescript
// practice_settings
{
  "vibration_enabled": boolean,           // 振动反馈
  "sound_enabled": boolean,               // 声音开关
  "use_single_button": boolean,          // 输入模式
  "long_press_threshold": number,        // 长按时间阈值 (ms)
  "auto_check_delay": number,             // 自动检查延迟 (ms)
  "correct_feedback_delay": number,       // 正确反馈延迟 (ms)
  "audio_playback_speed": number,        // 音频播放速度 (0.5-2.0)
  "has_set_button_mode": boolean         // 是否设置过按钮模式
}

// app_preferences
{
  "font_size": string,                    // 字体大小 ("small" | "normal" | "large")
  "display_mode": string                  // 显示模式 ("compact" | "spacious")
}
```

---

## 注意事项

1. **手表屏幕限制**: 设置项应该简洁，避免过多选项导致滚动困难
2. **触摸目标大小**: 所有可点击元素应该至少 32vp-48vp 高
3. **设置持久化**: 所有设置应该立即保存到 Preferences，不需要"保存"按钮
4. **默认值**: 为所有设置提供合理的默认值
5. **设置同步**: 如果将来支持多设备，考虑设置同步机制
6. **用户引导**: 首次使用时，可以显示设置说明或推荐配置

---

## 参考 zhaocha 项目（全能计分器）的设置项

基于对 `./watch/zhaocha` 项目的分析，以下设置项值得参考：

### zhaocha 项目中的设置项
1. **振动反馈** (`vibrationEnabled`) - ✅ 已实现
2. **音效开关** (`soundEnabled`) - 建议添加
3. **限时时长** (`timeLimitMinutes`) - 1/2/3/5 分钟选择器，建议添加为练习限时模式
4. **深色模式** (`colorMode`) - 仅手机设备，手表不需要
5. **意见建议** - 包含邮箱复制和邮件应用打开功能
6. **分享给朋友** - 使用系统分享面板
7. **版本信息** - 显示应用版本号
8. **自定义内容** - 自定义字母、汉字、Emoji（仅手机，手表不需要）

### zhaocha 项目的实现特点
- **手表设备**: 使用 `ListItem` 和 `ListItemGroup` 组织设置项
- **手机设备**: 使用卡片式布局（`Column` + `backgroundColor` + `borderRadius`）
- **设置项组件**: 使用 `Toggle` 开关和选择器对话框
- **设置管理**: 使用 `PreferencesManager` 统一管理所有设置
- **反馈功能**: 包含邮箱地址复制和邮件应用打开
- **分享功能**: 使用 `systemShare` API 打开系统分享面板
- **版本信息**: 从 `module.json5` 读取版本号显示

### 可参考的实现细节
1. **意见建议对话框**:
   - 显示邮箱地址
   - 提供"复制邮箱"按钮（使用 `pasteboard` API）
   - 提供"打开邮件应用"按钮（使用 `Want` API）
   - 错误处理和用户提示

2. **分享功能**:
   - 使用 `systemShare` API
   - 可以分享应用链接或生成二维码
   - 错误处理和用户提示

3. **限时模式**:
   - 使用对话框选择时长（1/2/3/5 分钟）
   - 保存到 Preferences
   - 在练习模式中使用

4. **版本信息显示**:
   - 从 `module.json5` 读取版本号
   - 显示在设置页面底部
   - 可以点击查看详细信息

---

## 总结

手表应用应该至少包含以下核心设置：
- ✅ 振动反馈（已实现）
- ✅ 长按时间阈值（已实现）
- ⚠️ 输入模式（代码中已有，需暴露）
- 声音开关（参考 zhaocha）
- 自动检查延迟
- 正确反馈延迟
- 意见建议（参考 zhaocha）
- 分享应用（参考 zhaocha）
- 版本信息（参考 zhaocha）

这些设置可以显著提升用户体验，让用户根据自己的习惯和需求个性化配置应用。

