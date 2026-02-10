# 摩斯密码学习 (HarmonyOS)

<div align="center">

一个使用原生 ArkUI 开发的鸿蒙 OS 摩斯密码学习应用

[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-Native-blue)](https://developer.huawei.com/consumer/cn/harmonyos/)
[![ArkTS](https://img.shields.io/badge/ArkTS-TypeScript-green)](https://developer.huawei.com/consumer/cn/arkts/)
[![开源](https://img.shields.io/badge/开源-MIT-orange)](LICENSE)

**🏆 休闲娱乐类别 Top 36**

</div>

## 📖 项目简介

这是一个完全使用鸿蒙 OS 原生 ArkUI 框架开发的摩斯密码学习应用，旨在帮助开发者了解和学习如何使用 ArkTS 和 ArkUI 构建真实的鸿蒙应用。

### ✨ 核心功能

- 🎓 **学习模式**：系统化的摩斯密码课程，包含字母课程和知识课程
- 🏋️ **练习模式**：多难度练习，巩固学习成果
- 🔄 **翻译功能**：文本与摩斯密码互相转换
- 📋 **码表查询**：完整的摩斯密码对照表和中文电码表
- 👤 **个人中心**：学习进度追踪、收藏管理、设置

### 🎯 开源目的

本项目完全开源，旨在：
- 为鸿蒙 OS 开发者提供一个真实的原生 ArkUI 应用参考
- 展示 ArkUI 的最佳实践和常见功能实现
- 帮助开发者快速上手鸿蒙应用开发
- 促进鸿蒙生态的发展和交流

## 🏗️ 项目结构

```
morse/
├── entry/src/main/
│   ├── ets/
│   │   ├── data/              # 数据配置
│   │   │   ├── LessonConfig.ets    # 课程配置
│   │   │   └── LessonData.ets      # 课程数据
│   │   ├── entryability/      # 应用入口
│   │   │   └── EntryAbility.ets
│   │   ├── models/            # 数据模型
│   │   │   └── MorseCode.ets       # 摩斯密码模型
│   │   ├── pages/             # 页面
│   │   │   ├── Index.ets           # 主页面（Tab导航）
│   │   │   ├── learn/              # 学习模块
│   │   │   │   ├── LearnPage.ets
│   │   │   │   ├── LetterLessonPage.ets
│   │   │   │   ├── KnowledgeLessonPage.ets
│   │   │   │   └── LessonQuizPage.ets
│   │   │   ├── practice/           # 练习模块
│   │   │   │   ├── PracticeDifficultyPage.ets
│   │   │   │   └── PracticePage.ets
│   │   │   ├── translate/          # 翻译模块
│   │   │   │   └── TranslatePage.ets
│   │   │   ├── codetable/          # 码表模块
│   │   │   │   ├── CodeTablePage.ets
│   │   │   │   └── ChineseTelegraphCodePage.ets
│   │   │   └── me/                 # 个人中心
│   │   │       └── MePage.ets
│   │   ├── services/          # 服务层
│   │   │   ├── AudioService.ets       # 音频服务
│   │   │   ├── FlashlightService.ets  # 闪光灯服务
│   │   │   ├── PinyinService.ets      # 拼音服务
│   │   │   └── VibratorService.ets    # 振动服务
│   │   ├── store/             # 数据持久化
│   │   │   ├── FavoritesStore.ets
│   │   │   ├── PracticeProgressStore.ets
│   │   │   └── ProgressStoreSingleton.ets
│   │   ├── viewmodel/         # 视图模型
│   │   │   ├── LearnViewModel.ets
│   │   │   ├── LetterLessonViewModel.ets
│   │   │   ├── KnowledgeLessonViewModel.ets
│   │   │   ├── PracticeViewModel.ets
│   │   │   └── QuizViewModel.ets
│   │   ├── widgets/           # 自定义组件
│   │   │   ├── CustomDialog.ets
│   │   │   ├── ExplanationTipsCard.ets
│   │   │   └── PracticeRecordDialog.ets
│   │   ├── types/             # 类型定义
│   │   │   └── Types.ets
│   │   └── utils/             # 工具类
│   │       └── EventHub.ets
│   └── resources/             # 资源文件
│       ├── base/
│       ├── en_US/
│       └── zh_HK/
├── AppScope/                  # 应用全局配置
└── build-profile.json5        # 构建配置
```

## 🛠️ 技术栈

- **开发语言**: ArkTS (TypeScript扩展)
- **UI框架**: ArkUI (鸿蒙原生声明式UI)
- **架构模式**: MVVM
- **数据持久化**: Preferences API
- **多语言**: 支持简体中文、繁体中文、英文
- **适配**: 手机 + 平板（横屏/竖屏自适应）

## 💡 核心特性展示

### 1. 平板适配
```typescript
// 自动检测设备类型，平板横屏时Tab栏自动切换到侧边
this.isTablet = deviceInfo.deviceType === 'tablet'
Tabs({ barPosition: this.isTablet ? BarPosition.Start : BarPosition.End })
```

### 2. 数据持久化
使用 Preferences API 保存用户数据（学习进度、收藏、设置等）

### 3. 多语言支持
完整的国际化方案，支持简繁英三种语言

### 4. 音频播放
使用 SoundPool 实现摩斯密码音频播放

### 5. 闪光灯控制
调用系统相机闪光灯 API 实现摩斯密码的闪光展示

### 6. 振动反馈
使用 Vibrator API 提供触觉反馈，支持输入振动和答题反馈

## 🚀 快速开始

### 环境要求

- DevEco Studio 5.0+
- HarmonyOS SDK API 12+

### 运行步骤

1. 克隆项目
```bash
git clone https://gitee.com/shishizii/morse-code-hos.git
```

2. 使用 DevEco Studio 打开项目

3. 连接鸿蒙设备或启动模拟器

4. 点击运行按钮

## 📝 版本历史

### v2.1.0 (2026-01-30)
- ✅ 练习页、翻译页与「我」页双键设置一致（统一使用 practice_settings，onPageShow 重载）

### v2.0.0 (2026-01-30)
- ✅ 适配鸿蒙 OS 5.0 NEXT
- ✅ 增加「其他应用」推荐
- ✅ 手表端交互优化

### v1.5.0 (2024-11-29)
- ✅ 振动反馈功能
  - 输入时振动（点短振100ms，划长振300ms）
  - 选择模式答题反馈振动
  - 声音播放同步振动
  - 可在设置中开关
- ✅ 单按钮输入模式完整实现
- ✅ 复习模式提示
- ✅ 数据持久化优化
- ✅ 性能优化（音频预加载、列表渲染）
- ✅ UI统一（对话框样式）

### v1.2.1
- ✅ 自动解锁课程
- ✅ 文本到摩斯密码的闪光灯功能
- ✅ 声音播放
- ✅ 课程复习功能

## 🤝 交流与支持

QQ 群：740761680  
微信：yangyang500102

## 📄 开源协议

本项目采用 MIT 协议开源，欢迎学习、使用和贡献代码。

## 🙏 致谢

感谢所有为鸿蒙生态做出贡献的开发者们！

---

⭐ 如果这个项目对你有帮助，欢迎 Star 支持！
