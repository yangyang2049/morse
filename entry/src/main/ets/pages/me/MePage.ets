import { promptAction } from '@kit.ArkUI'
import { common, Want } from '@kit.AbilityKit'
import pasteboard from '@ohos.pasteboard'
import { resourceManager, i18n } from '@kit.LocalizationKit'
import { BusinessError } from '@kit.BasicServicesKit'
import preferences from '@ohos.data.preferences'
import { systemShare } from '@kit.ShareKit'
import { uniformTypeDescriptor } from '@kit.ArkData'
import { vibratorService } from '../../services/VibratorService'
// 手电筒功能已移至翻译页面
// import { flashlightService } from '../../services/FlashlightService'

// 语言选项接口
interface LanguageOption {
  code: string
  nativeName: string
}

// 支持的语言列表
const SUPPORTED_LANGUAGES: LanguageOption[] = [
  { code: 'zh-CN', nativeName: '简体中文' },
  { code: 'zh-HK', nativeName: '繁體中文' },
  { code: 'en-US', nativeName: 'English' }
]

@Component
export struct MePage {
  @State appVersion: string = '1.3.1'
  @StorageLink('currentLanguage') currentLanguage: string = this.getInitialLanguage()
  @State useSingleButton: boolean = false // 是否使用单按钮模式
  @State showButtonModeDialog: boolean = false // 是否显示按钮模式选择对话框
  @State vibrationEnabled: boolean = true // 振动反馈开关
  // 手电筒相关状态已移除（功能已移至翻译页面）
  // @State isFlashlightOn: boolean = false
  // @State flashlightInitialized: boolean = false
  // @State isPlayingSOS: boolean = false
  // 资源管理器
  private resourceMgr: resourceManager.ResourceManager | null = null
  private preferencesStore: preferences.Preferences | null = null
  private privacyLink = 'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1776276266387804160'

  async aboutToAppear() {
    // 初始化资源管理器
    try {
      this.resourceMgr = getContext(this).resourceManager
    } catch (error) {
      console.error('[MePage] Failed to get resource manager:', error)
    }

    // 初始化偏好设置存储
    await this.initPreferences()
    // 加载按钮模式偏好设置
    await this.loadButtonModePreference()
    // 加载振动偏好设置
    await this.loadVibrationPreference()

    // 手电筒服务初始化已移除（功能已移至翻译页面）

    this.loadAppInfo()
  }

  // 获取初始语言
  private getInitialLanguage(): string {
    try {
      const currentLocale = i18n.System.getSystemLocale()
      console.log(`[MePage] System locale: ${currentLocale}`)
      // 将系统locale转换为我们的语言代码格式
      if (currentLocale.startsWith('zh')) {
        // 判断是繁体还是简体
        if (currentLocale.includes('Hant') || currentLocale.includes('HK') || currentLocale.includes('TW') || currentLocale.includes('MO')) {
          return 'zh-HK' // 繁体中文
        }
        return 'zh-CN' // 简体中文
      } else if (currentLocale.startsWith('en')) {
        return 'en-US'
      }
      return 'zh-CN' // 默认简体中文
    } catch (error) {
      console.error('[MePage] Failed to get initial language:', error)
      return 'zh-CN' // 默认简体中文
    }
  }

  aboutToDisappear() {
    // 手电筒相关清理已移除（功能已移至翻译页面）
  }

  // 获取系统资源字符串
  private async getStringResource(key: string): Promise<string> {
    try {
      if (this.resourceMgr) {
        // 使用资源ID获取字符串
        const resourceId = await this.resourceMgr.getStringByName(key)
        return resourceId
      }
      return key
    } catch (error) {
      console.error(`[MePage] Failed to get string resource ${key}:`, error)
      // 如果系统资源获取失败，返回key作为fallback
      return key
    }
  }

  // 设置系统语言（使用官方API）
  private async setSystemLanguage(languageCode: string): Promise<void> {
    try {
      console.log(`[MePage] Attempting to set app preferred language to: ${languageCode}`)

      // 使用HarmonyOS官方API设置应用偏好语言
      // 将语言代码转换为正确的格式
      let preferredLanguage = languageCode
      if (languageCode === 'zh-CN') {
        preferredLanguage = 'zh-Hans-CN' // 简体中文
      } else if (languageCode === 'zh-HK') {
        preferredLanguage = 'zh-Hant-HK' // 繁体中文（香港）
      } else if (languageCode === 'en-US') {
        preferredLanguage = 'en-Latn-US' // 美式英语
      }

      // 设置应用偏好语言
      i18n.System.setAppPreferredLanguage(preferredLanguage)
      console.log(`[MePage] App preferred language set to: ${preferredLanguage}`)

      // 更新当前语言状态
      this.currentLanguage = languageCode

      // 同步到AppStorage，供其他页面使用
      AppStorage.setOrCreate('currentLanguage', languageCode)

      // 触发语言刷新事件
      const currentTrigger = AppStorage.get<number>('languageRefreshTrigger') || 0
      AppStorage.setOrCreate('languageRefreshTrigger', currentTrigger + 1)
      console.log(`[MePage] Language refresh trigger incremented to: ${currentTrigger + 1}`)

    } catch (error) {
      const err = error as BusinessError
      console.error(`[MePage] Failed to set app preferred language, error code: ${err.code}, message: ${err.message}`)
      // 即使系统语言设置失败，也不抛出错误，让应用继续使用自定义i18n
    }
  }

  // 获取当前语言
  private getCurrentLanguage(): string {
    try {
      const currentLocale = i18n.System.getSystemLocale()
      // 将系统locale转换为我们的语言代码格式
      if (currentLocale.startsWith('zh')) {
        // 判断是繁体还是简体
        if (currentLocale.includes('Hant') || currentLocale.includes('HK') || currentLocale.includes('TW') || currentLocale.includes('MO')) {
          return 'zh-HK' // 繁体中文
        }
        return 'zh-CN' // 简体中文
      } else if (currentLocale.startsWith('en')) {
        return 'en-US'
      }
      return 'zh-CN' // 默认简体中文
    } catch (error) {
      console.error('[MePage] Failed to get current language:', error)
      return 'zh-CN' // 默认简体中文
    }
  }

  private loadAppInfo() {
    this.appVersion = '1.3.1'
  }

  // 初始化偏好设置存储
  private async initPreferences(): Promise<void> {
    try {
      const context = getContext(this)
      this.preferencesStore = await preferences.getPreferences(context, 'practice_preferences')
      console.log('[MePage] Preferences store initialized')
    } catch (error) {
      console.error('[MePage] Failed to initialize preferences:', error)
    }
  }

  // 加载按钮模式偏好设置
  private async loadButtonModePreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        this.useSingleButton = await this.preferencesStore.get('use_single_button', false) as boolean
        console.log(`[MePage] Loaded button mode preference: ${this.useSingleButton}`)
      }
    } catch (error) {
      console.error('[MePage] Failed to load button mode preference:', error)
    }
  }

  // 保存按钮模式偏好设置
  private async saveButtonModePreference(useSingle: boolean): Promise<void> {
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.put('use_single_button', useSingle)
        await this.preferencesStore.put('has_set_button_mode', true)
        await this.preferencesStore.flush()
        this.useSingleButton = useSingle
        console.log(`[MePage] Saved button mode preference: ${useSingle}`)
      }
    } catch (error) {
      console.error('[MePage] Failed to save button mode preference:', error)
    }
  }

  // 加载振动偏好设置
  private async loadVibrationPreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        this.vibrationEnabled = await this.preferencesStore.get('vibration_enabled', true) as boolean
        vibratorService.setEnabled(this.vibrationEnabled)
        console.log(`[MePage] Loaded vibration preference: ${this.vibrationEnabled}`)
      }
    } catch (error) {
      console.error('[MePage] Failed to load vibration preference:', error)
    }
  }

  // 保存振动偏好设置
  private async saveVibrationPreference(enabled: boolean): Promise<void> {
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.put('vibration_enabled', enabled)
        await this.preferencesStore.flush()
        this.vibrationEnabled = enabled
        vibratorService.setEnabled(enabled)
        console.log(`[MePage] Saved vibration preference: ${enabled}`)
      }
    } catch (error) {
      console.error('[MePage] Failed to save vibration preference:', error)
    }
  }

  // 获取当前语言的显示名称
  private getCurrentLanguageDisplayName(): string {
    const language = SUPPORTED_LANGUAGES.find(lang => lang.code === this.currentLanguage)
    return language ? language.nativeName : '简体中文'
  }

  // 手电筒相关方法已移除（功能已移至翻译页面）
  // private async initFlashlightService(): Promise<void> { ... }
  // private async toggleFlashlight(): Promise<void> { ... }
  // private async playSOS(): Promise<void> { ... }

  // 刷新语言状态 - 从AppStorage获取最新状态

  // 分享应用 - 使用 HarmonyOS 标准分享框架
  private async shareApp(): Promise<void> {
    try {
      // 获取分享文本
      const isZh = this.currentLanguage.startsWith('zh')
      const shareText = isZh ? (
        '推荐一个超棒的摩尔斯电码学习应用！📟✨\n《摩斯电码通》\n\n📱 摩斯电码通\n🎓 从零开始学习摩尔斯电码\n🎮 趣味练习，边玩边学\n🔦 手电筒闪烁显示摩尔斯码\n🌙 支持深色模式，护眼舒适\n🌏 支持简繁英多语言\n\n立即下载体验：\nhttps://appgallery.huawei.com/app/detail?id=com.douhua.morsecode'
      ) : (
        'Highly recommend this great Morse code learning app! 📟✨\nMorse Code Trainer\n\n📱 Learn Morse Code from scratch\n🎓 Step-by-step lessons for beginners\n🎮 Fun practice modes\n🔦 Flashlight Morse code display\n🌙 Light and Dark themes\n🌏 Multi-language support\n\nTry it now:\nhttps://appgallery.huawei.com/app/detail?id=com.douhua.morsecode'
      )

      // 获取分享标题
      const shareTitle = isZh ? '推荐摩斯电码通' : 'Recommend Morse Code Trainer'

      // 创建分享数据
      const shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.TEXT,
        content: shareText,
        title: shareTitle,
        description: isZh ? '推荐摩尔斯电码学习应用' : 'Recommend Morse Code Learning App'
      })

      // 创建分享控制器
      const controller: systemShare.ShareController = new systemShare.ShareController(shareData)
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext

      // 显示分享面板
      await controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DEFAULT
      })

      console.info('[MePage] Share panel opened successfully')
    } catch (error) {
      const err = error as BusinessError
      console.error(`[MePage] Failed to share app. code: ${err?.code}, message: ${err?.message}`)

      // 如果分享失败，回退到复制到剪贴板
      try {
        const isZh = this.currentLanguage.startsWith('zh')
        const shareText = isZh ? (
          '推荐一个超棒的摩尔斯电码学习应用！📟✨\n《摩斯电码通》\n\n📱 摩斯电码通\n🎓 从零开始学习摩尔斯电码\n🎮 趣味练习，边玩边学\n🔦 手电筒闪烁显示摩尔斯码\n🌙 支持深色模式，护眼舒适\n🌏 支持简繁英多语言\n\n立即下载体验：\nhttps://appgallery.huawei.com/app/detail?id=com.douhua.morsecode'
        ) : (
          'Highly recommend this great Morse code learning app! 📟✨\nMorse Code Trainer\n\n📱 Learn Morse Code from scratch\n🎓 Step-by-step lessons for beginners\n🎮 Fun practice modes\n🔦 Flashlight Morse code display\n🌙 Light and Dark themes\n🌏 Multi-language support\n\nTry it now:\nhttps://appgallery.huawei.com/app/detail?id=com.douhua.morsecode'
        )

        const sysPB = pasteboard.getSystemPasteboard()
        const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, shareText)
        await sysPB.setPasteData(pasteData)

        // 显示复制成功提示
        const message = isZh ? '分享内容已复制到剪贴板' : 'Share content copied to clipboard'
        promptAction.showToast({
          message: message,
          duration: 2000,
          bottom: '80%'
        })
      } catch (toastError) {
        console.error('[MePage] Toast error:', toastError)
      }
    }
  }

  // 打开应用市场进行评分和反馈
  private async openAppGallery(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        bundleName: 'com.huawei.appmarket',
        abilityName: 'com.huawei.appmarket.MainAbility',
        parameters: {
          appId: 'com.douhua.morsecode'
        }
      }

      context.startAbility(want).then(() => {
        // 打开应用市场成功，无需toast提示
      }).catch((error: Error) => {
        console.error('打开应用市场失败:', error)
        this.openAppGalleryByBrowser()
      })
    } catch (error) {
      console.error('打开应用市场异常:', error)
      this.openAppGalleryByBrowser()
    }
  }

  // 通过浏览器打开应用市场页面作为备选方案
  private openAppGalleryByBrowser(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: 'https://appgallery.huawei.com/app/detail?id=com.douhua.morsecode'
      }

      context.startAbility(want).then(() => {
        // 通过浏览器打开成功，无需toast提示
      }).catch((error: Error) => {
        console.error('浏览器打开应用市场失败:', error)
        // 打开失败，无需toast提示
      })
    } catch (error) {
      console.error('备选方案异常:', error)
      // 异常情况，无需toast提示
    }
  }

  // 打开元素周期表应用
  private openPeriodicTableApp(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        bundleName: 'com.huawei.appmarket',
        abilityName: 'com.huawei.appmarket.MainAbility',
        parameters: {
          appId: 'com.douhua.yuansu'
        }
      }

      context.startAbility(want).then(() => {
        // 打开应用市场成功，无需toast提示
      }).catch((error: Error) => {
        console.error('打开应用市场失败:', error)
        this.openPeriodicTableAppByBrowser()
      })
    } catch (error) {
      console.error('打开应用市场异常:', error)
      this.openPeriodicTableAppByBrowser()
    }
  }

  // 通过浏览器打开元素周期表应用页面作为备选方案
  private openPeriodicTableAppByBrowser(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: 'https://appgallery.huawei.com/app/detail?id=com.douhua.yuansu'
      }

      context.startAbility(want).then(() => {
        // 通过浏览器打开成功，无需toast提示
      }).catch((error: Error) => {
        console.error('通过浏览器打开应用市场失败:', error)
        // 打开失败，无需toast提示
      })
    } catch (error) {
      console.error('通过浏览器打开应用市场异常:', error)
      // 异常情况，无需toast提示
    }
  }

  // 打开全能计分器应用
  private openIScoreApp(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        bundleName: 'com.huawei.appmarket',
        abilityName: 'com.huawei.appmarket.MainAbility',
        parameters: {
          appId: 'com.douhua.jifen'
        }
      }

      context.startAbility(want).then(() => {
        // 打开应用市场成功，无需toast提示
      }).catch((error: Error) => {
        console.error('打开应用市场失败:', error)
        this.openIScoreAppByBrowser()
      })
    } catch (error) {
      console.error('打开应用市场异常:', error)
      this.openIScoreAppByBrowser()
    }
  }

  // 通过浏览器打开全能计分器应用页面作为备选方案
  private openIScoreAppByBrowser(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: 'https://appgallery.huawei.com/app/detail?id=com.douhua.jifen'
      }

      context.startAbility(want).then(() => {
        // 通过浏览器打开成功，无需toast提示
      }).catch((error: Error) => {
        console.error('通过浏览器打开应用市场失败:', error)
        // 打开失败，无需toast提示
      })
    } catch (error) {
      console.error('通过浏览器打开应用市场异常:', error)
      // 异常情况，无需toast提示
    }
  }

  // 打开开发助手应用
  private openDevAssistantApp(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        bundleName: 'com.huawei.appmarket',
        abilityName: 'com.huawei.appmarket.MainAbility',
        parameters: {
          appId: 'com.douhua.kaifazhushou'
        }
      }

      context.startAbility(want).then(() => {
        // 打开应用市场成功，无需toast提示
      }).catch((error: Error) => {
        console.error('打开应用市场失败:', error)
        this.openDevAssistantAppByBrowser()
      })
    } catch (error) {
      console.error('打开应用市场异常:', error)
      this.openDevAssistantAppByBrowser()
    }
  }

  // 通过浏览器打开开发助手应用页面作为备选方案
  private openDevAssistantAppByBrowser(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: 'https://appgallery.huawei.com/app/detail?id=com.douhua.kaifazhushou'
      }

      context.startAbility(want).then(() => {
        // 通过浏览器打开成功，无需toast提示
      }).catch((error: Error) => {
        console.error('通过浏览器打开应用市场失败:', error)
        // 打开失败，无需toast提示
      })
    } catch (error) {
      console.error('通过浏览器打开应用市场异常:', error)
      // 异常情况，无需toast提示
    }
  }

  // 打开国旗小百科应用
  private openFlagApp(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        bundleName: 'com.huawei.appmarket',
        abilityName: 'com.huawei.appmarket.MainAbility',
        parameters: {
          appId: 'com.douhua.flag'
        }
      }

      context.startAbility(want).then(() => {
        // 打开应用市场成功，无需toast提示
      }).catch((error: Error) => {
        console.error('打开应用市场失败:', error)
        this.openFlagAppByBrowser()
      })
    } catch (error) {
      console.error('打开应用市场异常:', error)
      this.openFlagAppByBrowser()
    }
  }

  // 通过浏览器打开国旗小百科应用页面作为备选方案
  private openFlagAppByBrowser(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: 'https://appgallery.huawei.com/app/detail?id=com.douhua.flag'
      }

      context.startAbility(want).then(() => {
        // 通过浏览器打开成功，无需toast提示
      }).catch((error: Error) => {
        console.error('通过浏览器打开应用市场失败:', error)
        // 打开失败，无需toast提示
      })
    } catch (error) {
      console.error('通过浏览器打开应用市场异常:', error)
      // 异常情况，无需toast提示
    }
  }

  // 打开财会工具箱应用
  private openCaikuaiApp(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        bundleName: 'com.huawei.appmarket',
        abilityName: 'com.huawei.appmarket.MainAbility',
        parameters: {
          appId: 'com.douhua.caikuai'
        }
      }

      context.startAbility(want).then(() => {
        // 打开应用市场成功，无需toast提示
      }).catch((error: Error) => {
        console.error('打开应用市场失败:', error)
        this.openCaikuaiAppByBrowser()
      })
    } catch (error) {
      console.error('打开应用市场异常:', error)
      this.openCaikuaiAppByBrowser()
    }
  }

  // 通过浏览器打开财会工具箱应用页面作为备选方案
  private openCaikuaiAppByBrowser(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: 'https://appgallery.huawei.com/app/detail?id=com.douhua.caikuai'
      }

      context.startAbility(want).then(() => {
        // 通过浏览器打开成功，无需toast提示
      }).catch((error: Error) => {
        console.error('通过浏览器打开应用市场失败:', error)
        // 打开失败，无需toast提示
      })
    } catch (error) {
      console.error('通过浏览器打开应用市场异常:', error)
      // 异常情况，无需toast提示
    }
  }

  // 打开隐私政策链接
  private openPrivacyPolicy(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: this.privacyLink
      }

      context.startAbility(want).then(() => {
        // 通过浏览器打开成功
      }).catch((error: Error) => {
        console.error('通过浏览器打开隐私政策失败:', error)
      })
    } catch (error) {
      console.error('打开隐私政策异常:', error)
    }
  }

  // 打开Rust从入门到放弃应用
  private openRustApp(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        bundleName: 'com.huawei.appmarket',
        abilityName: 'com.huawei.appmarket.MainAbility',
        parameters: {
          appId: 'com.douhua.rustmaster'
        }
      }

      context.startAbility(want).then(() => {
        // 打开应用市场成功，无需toast提示
      }).catch((error: Error) => {
        console.error('打开应用市场失败:', error)
        this.openRustAppByBrowser()
      })
    } catch (error) {
      console.error('打开应用市场异常:', error)
      this.openRustAppByBrowser()
    }
  }

  // 通过浏览器打开Rust从入门到放弃应用页面作为备选方案
  private openRustAppByBrowser(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: 'https://appgallery.huawei.com/app/detail?id=com.douhua.rustmaster'
      }

      context.startAbility(want).then(() => {
        // 通过浏览器打开成功，无需toast提示
      }).catch((error: Error) => {
        console.error('通过浏览器打开应用市场失败:', error)
        // 打开失败，无需toast提示
      })
    } catch (error) {
      console.error('通过浏览器打开应用市场异常:', error)
      // 异常情况，无需toast提示
    }
  }

  @State private showLanguageDialog: boolean = false

  @Builder ButtonModeSelectorDialog() {
    Column() {
      Row() {
        Text($r('app.string.select_practice_input_mode'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Blank()
        Button() {
          Image($rawfile('ic_close.svg'))
            .width(20)
            .height(20)
            .fillColor('#FFFFFF')
        }
        .width(32)
          .height(32)
          .backgroundColor('rgba(128, 128, 128, 0.2)')
          .borderRadius(16)
          .onClick(() => {
            this.showButtonModeDialog = false
          })
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)
      }
      .width('100%')
        .margin({ bottom: 20 })

      // 双按钮模式选项
      Row() {
        Column() {
          Text($r('app.string.dual_button_mode'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .margin({ bottom: 8 })
          Text($r('app.string.dual_button_mode_desc'))
            .fontSize(12)
            .fontColor('#999999')
        }
        .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

        if (!this.useSingleButton) {
          Circle()
            .width(16)
            .height(16)
            .fill(Color.Transparent)
            .stroke('#FFD700')
            .strokeWidth(2)
        }
      }
      .width('100%')
        .padding(16)
        .backgroundColor('#111111')
        .borderRadius(8)
        .margin({ bottom: 8 })
        .border({
          width: !this.useSingleButton ? 1 : 0.5,
          color: !this.useSingleButton ? '#FFD700' : '#222222',
          radius: 8
        })
        .onClick(() => {
          this.saveButtonModePreference(false)
          this.showButtonModeDialog = false
        })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)

      // 单按钮模式选项
      Row() {
        Column() {
          Text($r('app.string.single_button_mode'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .margin({ bottom: 8 })
          Text($r('app.string.single_button_mode_desc'))
            .fontSize(12)
            .fontColor('#999999')
        }
        .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

        if (this.useSingleButton) {
          Circle()
            .width(16)
            .height(16)
            .fill(Color.Transparent)
            .stroke('#FFD700')
            .strokeWidth(2)
        }
      }
      .width('100%')
        .padding(16)
        .backgroundColor('#111111')
        .borderRadius(8)
        .border({
          width: this.useSingleButton ? 1 : 0.5,
          color: this.useSingleButton ? '#FFD700' : '#222222',
          radius: 8
        })
        .onClick(() => {
          this.saveButtonModePreference(true)
          this.showButtonModeDialog = false
        })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)
    }
    .padding(20)
      .backgroundColor('#2A2A2A')
      .borderRadius(12)
      .width('90%')
      .constraintSize({ maxWidth: 400, maxHeight: '60%' })
  }

  @Builder LanguageSelectorDialog() {
    Column() {
      Row() {
        Text($r('app.string.language_selection_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Blank()
        Button() {
          Image($rawfile('ic_close.svg'))
            .width(20)
            .height(20)
            .fillColor('#FFFFFF')
        }
        .width(32)
          .height(32)
          .backgroundColor('rgba(128, 128, 128, 0.2)')
          .borderRadius(16)
          .onClick(() => {
            this.showLanguageDialog = false
          })
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)
      }
      .width('100%')
        .margin({ bottom: 20 })

      Column() {
        ForEach(SUPPORTED_LANGUAGES, (language: LanguageOption) => {
          Row() {
            Text(language.nativeName)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
              .alignSelf(ItemAlign.Start)

            if (this.currentLanguage === language.code) {
              Circle()
                .width(16)
                .height(16)
                .fill(Color.Transparent)
                .stroke('#FFD700')
                .strokeWidth(2)
            }
          }
          .width('100%')
            .padding(16)
            .backgroundColor('#111111')
            .borderRadius(8)
            .margin({ bottom: 8 })
            .border({
              width: this.currentLanguage === language.code ? 1 : 0.5,
              color: this.currentLanguage === language.code ? '#FFD700' : '#222222',
              radius: 8
            })
            .onClick(async () => {
              console.log(`[LANG_SELECT] User selected language: ${language.code}`)
              console.log(`[LANG_SELECT] Current language before change: ${this.currentLanguage}`)
              await this.setSystemLanguage(language.code)
              console.log(`[LANG_SELECT] Current language after change: ${this.currentLanguage}`)
              this.showLanguageDialog = false
            })
            .hoverEffect(HoverEffect.Scale)
            .focusable(true)
        })
      }
      .width('100%')
    }
    .padding(20)
      .backgroundColor('#2A2A2A')
      .borderRadius(12)
      .width('90%')
      .constraintSize({ maxWidth: 400, maxHeight: '60%' })
  }

  @Builder
  private TitleBar() {
    Row() {
      Text($r('app.string.settings'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
    }
    .height(56)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#000000')
  }

  @Builder LanguageSettingsItem() {
    Row() {
      Column() {
        Text($r('app.string.language'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Start)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

      Image($rawfile('ic_arrow_right.svg'))
        .width(16)
        .height(16)
        .fillColor('#666666')
    }
    .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        this.showLanguageDialog = true
      })
      .hoverEffect(HoverEffect.Scale)
      .focusable(true)
  }


  @Builder RatingSettingsItem() {
    Row() {
      Column() {
        Text($r('app.string.rating_feedback'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Start)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

      Image($rawfile('ic_arrow_right.svg'))
        .width(16)
        .height(16)
        .fillColor('#666666')
    }
    .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        this.openAppGallery()
      })
      .hoverEffect(HoverEffect.Scale)
      .focusable(true)
  }

  @Builder ShareSettingsItem() {
    Row() {
      Column() {
        Text($r('app.string.share_app'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Start)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

      Image($rawfile('ic_arrow_right.svg'))
        .width(16)
        .height(16)
        .fillColor('#666666')
    }
    .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        this.shareApp()
      })
      .hoverEffect(HoverEffect.Scale)
      .focusable(true)
  }

  @Builder PrivacyPolicySettingsItem() {
    Row() {
      Column() {
        Text($r('app.string.privacy_title'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Start)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

      Image($rawfile('ic_arrow_right.svg'))
        .width(16)
        .height(16)
        .fillColor('#666666')
    }
    .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        this.openPrivacyPolicy()
      })
      .hoverEffect(HoverEffect.Scale)
      .focusable(true)
  }

  @Builder ButtonModeSettingsItem() {
    Row() {
      Column() {
        Text($r('app.string.practice_input_mode'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Start)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

      Image($rawfile('ic_arrow_right.svg'))
        .width(16)
        .height(16)
        .fillColor('#666666')
    }
    .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        this.showButtonModeDialog = true
      })
      .hoverEffect(HoverEffect.Scale)
      .focusable(true)
  }

  @Builder VibrationSettingsItem() {
    Row() {
      Column() {
        Text($r('app.string.vibration'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Start)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: this.vibrationEnabled })
        .selectedColor('#FFD700')
        .onChange(async (isOn: boolean) => {
          await this.saveVibrationPreference(isOn)
        })
    }
    .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .hoverEffect(HoverEffect.Scale)
      .focusable(true)
  }

  // 手电筒测试UI已移除（功能已移至翻译页面）
  /*
  @Builder FlashlightTestItem() { ... }
  @Builder SOSTestItem() { ... }
  */

  @Builder OtherAppsSection() {
    // 其他应用部分
    Column() {
      Text($r('app.string.other_apps'))
        .fontSize(14)
        .fontWeight(FontWeight.Normal)
        .fontColor('#999999')
        .margin({ top: 30, bottom: 12, left: 16 })
        .alignSelf(ItemAlign.Start)

      // 全能计分器应用卡片
      Row() {
        Image($rawfile('appicon_jifen.png'))
          .width(48)
          .height(48)
          .borderRadius(8)
          .margin({ right: 16 })

        Column() {
          Text(this.currentLanguage.startsWith('zh') ? '全能计分器' : 'iScore')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Start)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

        Image($rawfile('ic_arrow_right.svg'))
          .width(16)
          .height(16)
          .fillColor('#666666')
      }
      .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#111111')
        .borderRadius(12)
        .border({ width: 1, color: '#222222' })
        .margin({ bottom: 8 })
        .onClick(() => {
          this.openIScoreApp()
        })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)

      // 元素周期表应用卡片
      Row() {
        Image($r('app.media.appicon_yuansu'))
          .width(48)
          .height(48)
          .borderRadius(8)
          .margin({ right: 16 })

        Column() {
          Text($r('app.string.periodic_table_app'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Start)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

        Image($rawfile('ic_arrow_right.svg'))
          .width(16)
          .height(16)
          .fillColor('#666666')
      }
      .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#111111')
        .borderRadius(12)
        .border({ width: 1, color: '#222222' })
        .margin({ bottom: 8 })
        .onClick(() => {
          this.openPeriodicTableApp()
        })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)

      // 国旗小百科应用卡片
      Row() {
        Image($rawfile('appicon_flag.png'))
          .width(48)
          .height(48)
          .borderRadius(8)
          .margin({ right: 16 })

        Column() {
          Text(this.currentLanguage.startsWith('zh') ? '国旗小百科' : 'Flag Wiki')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Start)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

        Image($rawfile('ic_arrow_right.svg'))
          .width(16)
          .height(16)
          .fillColor('#666666')
      }
      .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#111111')
        .borderRadius(12)
        .border({ width: 1, color: '#222222' })
        .margin({ bottom: 8 })
        .onClick(() => {
          this.openFlagApp()
        })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)

      // 开发助手应用卡片
      Row() {
        Image($rawfile('appicon_devassistant.png'))
          .width(48)
          .height(48)
          .borderRadius(8)
          .margin({ right: 16 })

        Column() {
          Text(this.currentLanguage.startsWith('zh') ? '独立开发助手' : 'Dev Assistant')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Start)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

        Image($rawfile('ic_arrow_right.svg'))
          .width(16)
          .height(16)
          .fillColor('#666666')
      }
      .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#111111')
        .borderRadius(12)
        .border({ width: 1, color: '#222222' })
        .margin({ bottom: 8 })
        .onClick(() => {
          this.openDevAssistantApp()
        })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)

      // 财会工具箱应用卡片
      Row() {
        Image($rawfile('appicon_caikuai.png'))
          .width(48)
          .height(48)
          .borderRadius(8)
          .margin({ right: 16 })

        Column() {
          Text(this.currentLanguage.startsWith('zh') ? '财会工具箱' : 'Accounting Tools')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Start)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

        Image($rawfile('ic_arrow_right.svg'))
          .width(16)
          .height(16)
          .fillColor('#666666')
      }
      .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#111111')
        .borderRadius(12)
        .border({ width: 1, color: '#222222' })
        .margin({ bottom: 8 })
        .onClick(() => {
          this.openCaikuaiApp()
        })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)

      // Rust从入门到放弃应用卡片
      Row() {
        Image($rawfile('appicon_rust.png'))
          .width(48)
          .height(48)
          .borderRadius(8)
          .margin({ right: 16 })

        Column() {
          Text(this.currentLanguage.startsWith('zh') ? 'Rust 从入门到放弃' : 'Rust Master')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Start)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

        Image($rawfile('ic_arrow_right.svg'))
          .width(16)
          .height(16)
          .fillColor('#666666')
      }
      .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#111111')
        .borderRadius(12)
        .border({ width: 1, color: '#222222' })
        .margin({ bottom: 8 })
        .onClick(() => {
          this.openRustApp()
        })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)
    }
    .width('100%')
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ maxWidth: 400 })
  }


  build() {
    Column() {
      this.TitleBar()

      Stack() {
        Scroll() {
          Column() {
            // 头部 - 应用信息（黑色背景，图标置顶）
            Column() {
              Image($r('app.media.startIcon'))
                .width(80)
                .height(80)
                .borderRadius(20)
                .margin({ bottom: 16 })
                .shadow({
                  radius: 8,
                  color: 'rgba(255, 255, 255, 0.3)',
                  offsetX: 0,
                  offsetY: 2
                })

              Text($r('app.string.app_name'))
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .margin({ bottom: 4 })

              Row() {
                Text($r('app.string.version'))
                  .fontSize(14)
                  .fontColor('#B0B0B0')
                Text(` ${this.appVersion}`)
                  .fontSize(14)
                  .fontColor('#B0B0B0')
              }
            }
            .width('100%')
              .padding({ top: 20, bottom: 40 })
              .alignItems(HorizontalAlign.Center)

            // 设置项（黑色背景卡片 + 分割线，无图标）
            Column() {
              // 盒子容器
              Column() {
                // 练习输入模式设置
                this.ButtonModeSettingsItem()
                Divider().strokeWidth(1).color('#222222')

                // 振动反馈设置
                this.VibrationSettingsItem()
                Divider().strokeWidth(1).color('#222222')

                // 手电筒测试功能已移至翻译页面
                // this.FlashlightTestItem()
                // Divider().strokeWidth(1).color('#222222')

                // SOS测试功能已移至翻译页面
                // this.SOSTestItem()
                // Divider().strokeWidth(1).color('#222222')

                // 语言切换条目
                this.LanguageSettingsItem()
                Divider().strokeWidth(1).color('#222222')

                this.RatingSettingsItem()
                Divider().strokeWidth(1).color('#222222')

                this.ShareSettingsItem()
                Divider().strokeWidth(1).color('#222222')

                this.PrivacyPolicySettingsItem()
              }
              .width('100%')
                .backgroundColor('#111111')
                .borderRadius(12)
                .border({ width: 1, color: '#222222' })
                .padding({ top: 4, bottom: 4 })
                .constraintSize({ maxWidth: 400 })

              this.OtherAppsSection()
            }
            .width('100%')
              .padding({ left: 20, right: 20 })
              .alignItems(HorizontalAlign.Center)

            // 底部版权信息 - 现在在滚动内容的底部
            Column() {
              // QQ群信息 - 仅在中文环境下显示
              if (this.currentLanguage.startsWith('zh')) {
                Row() {
                  Text('QQ群：825096333 ')
                    .fontSize(12)
                    .fontColor('#999999')

                  Image($rawfile('ic_copy.svg'))
                    .width(16)
                    .height(16)
                    .margin({ left: 4 })
                }
                .width('100%')
                  .justifyContent(FlexAlign.Center)
                  .alignItems(VerticalAlign.Center)
                  .padding({ bottom: 20 })
                  .onClick(async () => {
                    try {
                      const sysPB = pasteboard.getSystemPasteboard()
                      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, '825096333')
                      await sysPB.setPasteData(pasteData)
                      promptAction.showToast({
                        message: $r('app.string.qq_group_number_copied'),
                        duration: 2000
                      })
                    } catch (error) {
                      console.error('[MePage] Failed to copy QQ group number:', error)
                    }
                  })
              }

              Text($r('app.string.copyright'))
                .fontSize(12)
                .fontColor('#999999')
            }
            .width('100%')
              .padding({ top: 40, bottom: 20 })
              .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
            .backgroundColor('#000000')
        }
        .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .scrollable(ScrollDirection.Vertical)
          .scrollBarColor('#000000')
          .scrollBarWidth(0)
          .backgroundColor('#000000')

        // 语言选择对话框
        if (this.showLanguageDialog) {
          Stack() {
            // 半透明背景
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor('rgba(0, 0, 0, 0.5)')
              .onClick(() => {
                this.showLanguageDialog = false
              })

            // 对话框内容 - 使用Column居中
            Column() {
              this.LanguageSelectorDialog()
            }
            .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
            .height('100%')
        }

        // 按钮模式选择对话框
        if (this.showButtonModeDialog) {
          Stack() {
            // 半透明背景
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor('rgba(0, 0, 0, 0.5)')
              .onClick(() => {
                this.showButtonModeDialog = false
              })

            // 对话框内容 - 使用Column居中
            Column() {
              this.ButtonModeSelectorDialog()
            }
            .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
            .height('100%')
        }
      }
      .width('100%')
        .height('100%')
        .layoutWeight(1)
    }
    .width('100%')
      .height('100%')
      .backgroundColor('#000000')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
