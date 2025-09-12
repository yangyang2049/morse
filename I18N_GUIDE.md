# 鸿蒙应用多语言支持完整指南

## 概述

本项目采用**应用内字典型多语言方案**，具有以下优势：
- ✅ 语言切换立即生效，无需重启应用
- ✅ 跨版本兼容性好，不依赖系统资源热切换
- ✅ 支持模板参数和动态内容
- ✅ 性能优异，查找效率高
- ✅ 易于扩展和维护

## 核心架构

### 1. I18nService 服务类
位置：`entry/src/main/ets/services/I18nService.ets`

**主要功能：**
- 管理多语言字典
- 提供翻译接口 `t(key, params?)`
- 处理语言切换逻辑
- 持久化语言设置

**核心API：**
```typescript
// 获取翻译文本
i18nService.t('welcome') // "欢迎使用"
i18nService.t('hello_user', { name: 'John' }) // "你好，John"

// 语言管理
i18nService.setLanguage('en-US') // 切换到英文
i18nService.getCurrentLanguage() // 获取当前语言
i18nService.isChinese() // 是否为中文
i18nService.isEnglish() // 是否为英文
```

### 2. LanguageSwitcher 组件
位置：`entry/src/main/ets/widgets/LanguageSwitcher.ets`

**提供两个组件：**
- `LanguageSwitcher`: 完整的语言选择对话框
- `SimpleLanguageSwitcher`: 简单的中英文切换按钮

### 3. 应用初始化
位置：`entry/src/main/ets/entryability/EntryAbility.ets`

在应用启动时初始化I18n服务：
```typescript
import { i18nService } from '../services/I18nService'

// 在onWindowStageCreate中初始化
i18nService.init(this.context).finally(() => {
  windowStage.loadContent('pages/Index', (err) => {
    // 加载主页面
  })
})
```

## 使用指南

### 1. 页面中使用多语言

```typescript
import { i18nService } from '../services/I18nService'

@Component
export struct MyPage {
  // 监听语言变化，自动触发UI重新渲染
  @StorageLink('currentLanguage') currentLanguage: string = 'zh-CN'

  build() {
    Column() {
      // 基础文本
      Text(i18nService.t('welcome'))
        .fontSize(18)
      
      // 带参数的文本
      Text(i18nService.t('your_score', { score: '85' }))
        .fontSize(16)
      
      // 按钮文本
      Button(i18nService.t('confirm'))
        .onClick(() => {
          // 处理点击
        })
    }
  }
}
```

### 2. 添加语言切换功能

```typescript
import { LanguageSwitcher, SimpleLanguageSwitcher } from '../widgets/LanguageSwitcher'

// 方式1：使用完整的语言选择对话框
LanguageSwitcher()

// 方式2：使用简单的切换按钮
SimpleLanguageSwitcher()
```

### 3. 添加新的翻译文本

在 `I18nService.ets` 的 `initDictionaries()` 方法中添加：

```typescript
// 中文字典
this.dictionaries['zh-CN'] = {
  'new_key': '新的中文文本',
  'template_text': '你好，{name}！'
}

// 英文字典  
this.dictionaries['en-US'] = {
  'new_key': 'New English Text',
  'template_text': 'Hello, {name}!'
}
```

### 4. 动态添加翻译

```typescript
// 运行时添加单个翻译
i18nService.addTranslation('zh-CN', 'dynamic_key', '动态文本')

// 批量添加翻译
i18nService.addTranslations('zh-CN', {
  'key1': '文本1',
  'key2': '文本2'
})
```

## 最佳实践

### 1. 翻译键命名规范
- 使用下划线分隔：`user_profile_title`
- 按模块分组：`learn_lesson_title`、`practice_score_text`
- 避免过长的键名，保持简洁明了

### 2. 模板参数使用
```typescript
// 字典中定义
'welcome_user': '欢迎，{name}！今天是{date}'

// 使用时传参
i18nService.t('welcome_user', { 
  name: '张三', 
  date: '2025年1月1日' 
})
```

### 3. 条件显示文本
```typescript
// 根据语言显示不同内容
Text(i18nService.isChinese() ? '中文特有内容' : 'English specific content')

// 根据条件选择翻译键
Text(i18nService.t(isSuccess ? 'success_message' : 'error_message'))
```

### 4. 性能优化建议
- 避免在循环中频繁调用 `t()` 方法
- 对于固定文本，可以在组件初始化时获取并缓存
- 大量翻译文本可以考虑按模块拆分字典

### 5. 错误处理
```typescript
// 翻译键不存在时，会返回键名本身
const text = i18nService.t('non_existent_key') // 返回 'non_existent_key'

// 建议在开发时检查控制台警告
console.warn(`[I18nService] Translation key not found: ${key}`)
```

## 扩展功能

### 1. 支持更多语言
```typescript
// 在getSupportedLanguages中添加
private supportedLanguages: LanguageOption[] = [
  { code: 'zh-CN', name: '简体中文', nativeName: '简体中文' },
  { code: 'en-US', name: 'English', nativeName: 'English' },
  { code: 'ja-JP', name: '日本語', nativeName: '日本語' },
  { code: 'ko-KR', name: '한국어', nativeName: '한국어' }
]

// 添加对应的字典
this.dictionaries['ja-JP'] = { /* 日文翻译 */ }
this.dictionaries['ko-KR'] = { /* 韩文翻译 */ }
```

### 2. 远程加载语言包
```typescript
async loadRemoteTranslations(languageCode: string): Promise<void> {
  try {
    const response = await fetch(`/api/translations/${languageCode}`)
    const translations = await response.json()
    this.addTranslations(languageCode, translations)
  } catch (error) {
    console.error('Failed to load remote translations:', error)
  }
}
```

### 3. 复数形式支持
```typescript
// 扩展t方法支持复数
t(key: string, params?: TemplateParams & { count?: number }): string {
  // 根据count参数选择单数或复数形式
  if (params?.count !== undefined) {
    const pluralKey = params.count === 1 ? `${key}_one` : `${key}_other`
    return this.t(pluralKey, params)
  }
  return this.t(key, params)
}
```

## 迁移指南

### 从旧的$r()系统迁移

**旧代码：**
```typescript
Text($r('app.string.welcome'))
Button($r('app.string.confirm'))
```

**新代码：**
```typescript
Text(i18nService.t('welcome'))
Button(i18nService.t('confirm'))
```

**迁移步骤：**
1. 导入I18nService
2. 添加@StorageLink监听语言变化
3. 替换所有$r()调用为i18nService.t()
4. 更新语言切换逻辑

## 故障排除

### 1. 语言切换后UI没有更新
**解决方案：**
- 确保组件中有 `@StorageLink('currentLanguage')`
- 检查是否正确导入了I18nService

### 2. 翻译文本显示为键名
**原因：** 翻译键不存在或字典未正确初始化
**解决方案：**
- 检查控制台警告信息
- 确认翻译键在字典中存在
- 验证字典初始化是否成功

### 3. 应用启动时语言设置丢失
**原因：** I18nService未在EntryAbility中正确初始化
**解决方案：**
- 确保在onWindowStageCreate中调用i18nService.init()
- 检查Preferences权限配置

## 总结

新的多语言系统相比传统的$r()方案具有以下优势：

1. **稳定性更好**：不依赖系统资源热切换，避免了不同版本/设备的兼容性问题
2. **响应更快**：语言切换立即生效，用户体验更佳
3. **功能更强**：支持模板参数、动态加载等高级功能
4. **维护更易**：集中管理翻译文本，便于维护和扩展

建议在新项目中优先使用此方案，现有项目也可以逐步迁移。
