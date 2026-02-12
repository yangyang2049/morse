import router from '@ohos.router'
import { promptAction } from '@kit.ArkUI'
import { common, Want } from '@kit.AbilityKit'
import pasteboard from '@ohos.pasteboard'
import { resourceManager, i18n } from '@kit.LocalizationKit'
import { BusinessError } from '@kit.BasicServicesKit'
import preferences from '@ohos.data.preferences'
import { systemShare } from '@kit.ShareKit'
import { uniformTypeDescriptor } from '@kit.ArkData'
import { vibratorService } from '../../services/VibratorService'
import { MorseCodeData } from '../../models/MorseCode'
import { PinyinService } from '../../services/PinyinService'
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
  @State appVersion: string = '2.1.0'
  @StorageLink('currentLanguage') currentLanguage: string = this.getInitialLanguage()
  @State useSingleButton: boolean = false // 是否使用单按钮模式
  @State showKeySettingsDialog: boolean = false // 按键设置（单双键 + 长按阈值）对话框
  @State keySettingsSingleButton: boolean = false // 对话框内选择的单键与否，默认双键
  @State keySettingsSliderValue: number = 300
  @State vibrationEnabled: boolean = true // 振动反馈开关
  @State isMorseCodeExpanded: boolean = false // 摩斯码是否展开
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
      const context = getContext(this) as common.UIAbilityContext
      // 加载拼音服务
      await PinyinService.load(context)
    } catch (error) {
      console.error('[MePage] Failed to get resource manager:', error)
    }

    // 初始化偏好设置存储
    await this.initPreferences()
    // 加载按钮模式偏好设置
    await this.loadButtonModePreference()
    // 加载按键设置（长按时间）
    await this.loadLongPressThresholdPreference()
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
    this.appVersion = '2.1.0'
  }

  // 初始化偏好设置存储
  private async initPreferences(): Promise<void> {
    try {
      const context = getContext(this)
      this.preferencesStore = await preferences.getPreferences(context, 'practice_settings')
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

  // 通知其他页面（如翻译页 Tab）按键设置已变更，便于其从 practice_settings 重载
  private notifyPracticeSettingsChanged(): void {
    const v = (AppStorage.get<number>('practice_settings_version') as number) ?? 0
    AppStorage.setOrCreate('practice_settings_version', v + 1)
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

  // 加载长按时间偏好（按键设置）
  private async loadLongPressThresholdPreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        const v = await this.preferencesStore.get('long_press_threshold', 300) as number
        this.keySettingsSliderValue = v
      }
    } catch (error) {
      console.error('[MePage] Failed to load long press threshold:', error)
    }
  }

  // 保存长按时间偏好
  private async saveLongPressThresholdPreference(threshold: number): Promise<void> {
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.put('long_press_threshold', threshold)
        await this.preferencesStore.flush()
        this.keySettingsSliderValue = threshold
      }
    } catch (error) {
      console.error('[MePage] Failed to save long press threshold:', error)
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
    return language ? language.nativeName : SUPPORTED_LANGUAGES[0].nativeName
  }

  // 手电筒相关方法已移除（功能已移至翻译页面）
  // private async initFlashlightService(): Promise<void> { ... }
  // private async toggleFlashlight(): Promise<void> { ... }
  // private async playSOS(): Promise<void> { ... }

  // 刷新语言状态 - 从AppStorage获取最新状态

  // 分享应用 - 使用 HarmonyOS 标准分享框架
  private async shareApp(): Promise<void> {
    try {
      if (!this.resourceMgr) {
        return
      }
      const shareText = await this.resourceMgr.getStringByName('share_text')
      const shareTitle = await this.resourceMgr.getStringByName('share_title')
      const shareDescription = await this.resourceMgr.getStringByName('share_description')

      const shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.TEXT,
        content: shareText,
        title: shareTitle,
        description: shareDescription
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
        if (!this.resourceMgr) {
          return
        }
        const shareText = await this.resourceMgr.getStringByName('share_text')
        const sysPB = pasteboard.getSystemPasteboard()
        const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, shareText)
        await sysPB.setPasteData(pasteData)

        const message = await this.resourceMgr.getStringByName('share_copied')
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

  @Builder WechatGroupSettingsItem() {
    Row() {
      Column() {
        Text($r('app.string.join_group_title'))
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
        router.pushUrl({ url: 'pages/WechatGroupDetailPage' })
      })
      .hoverEffect(HoverEffect.Scale)
      .focusable(true)
  }

  @Builder KeySettingsSettingsItem() {
    Row() {
      Column() {
        Text($r('app.string.key_settings'))
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
        this.keySettingsSingleButton = this.useSingleButton
        this.showKeySettingsDialog = true
      })
      .hoverEffect(HoverEffect.Scale)
      .focusable(true)
  }

  @Builder KeySettingsDialog() {
    Column() {
      Row() {
        Text($r('app.string.key_settings'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Blank()
        Button() {
          Image($rawfile('ic_close.svg'))
            .width(20)
            .height(20)
            .fillColor(Color.White)
        }
        .width(32)
          .height(32)
          .backgroundColor('rgba(128, 128, 128, 0.2)')
          .borderRadius(16)
          .onClick(() => {
            this.showKeySettingsDialog = false
          })
      }
      .width('100%')
        .margin({ bottom: 20 })

      // 双键
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

        if (!this.keySettingsSingleButton) {
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
          width: !this.keySettingsSingleButton ? 1 : 0.5,
          color: !this.keySettingsSingleButton ? '#FFD700' : '#222222',
          radius: 8
        })
        .onClick(() => {
          this.keySettingsSingleButton = false
        })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)

      // 单键
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

        if (this.keySettingsSingleButton) {
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
          width: this.keySettingsSingleButton ? 1 : 0.5,
          color: this.keySettingsSingleButton ? '#FFD700' : '#222222',
          radius: 8
        })
        .onClick(() => {
          this.keySettingsSingleButton = true
        })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)

      // 单键时显示长按阈值
      if (this.keySettingsSingleButton) {
        Row() {
          Column() {
            Text($r('app.string.long_press_time'))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .margin({ bottom: 8 })
            Text(`${this.keySettingsSliderValue}ms`)
              .fontSize(14)
              .fontColor('#FFD700')
          }
          .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
          .padding(16)
          .backgroundColor('#111111')
          .borderRadius(8)
          .margin({ bottom: 8 })

        Slider({
          value: this.keySettingsSliderValue,
          min: 100,
          max: 600,
          step: 25,
          style: SliderStyle.OutSet
        })
          .blockColor('#FFD700')
          .trackColor('#333333')
          .selectedColor('#FFD700')
          .trackThickness(6)
          .blockSize({ width: 20, height: 20 })
          .onChange((value: number) => {
            this.keySettingsSliderValue = value
          })
          .margin({ bottom: 20 })
      }

      Button($r('app.string.confirm'))
        .width('100%')
        .height(48)
        .backgroundColor('#FFD700')
        .borderRadius(8)
        .fontColor(Color.Black)
        .fontWeight(FontWeight.Bold)
        .onClick(async () => {
          await this.saveButtonModePreference(this.keySettingsSingleButton)
          await this.saveLongPressThresholdPreference(this.keySettingsSliderValue)
          this.useSingleButton = this.keySettingsSingleButton
          this.showKeySettingsDialog = false
          this.notifyPracticeSettingsChanged()
        })
    }
    .padding(20)
      .backgroundColor('#2A2A2A')
      .borderRadius(12)
      .width('90%')
      .constraintSize({ maxWidth: 400 })
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

  // 获取拼音摩斯码
  private getPinyinMorseCode(): string {
    // 写死的摩斯码
    return '-·-- ··/··· ···· ·- -· --·/-·-- ·· -· --·/-·-- --- -· --·/-·-· ·- -·/-·-- ··-/···· --- -· --·/-- · -· --·/-·- ·- ··/··-· ·-/--·· ···· ·/·--- ··/·-·· ··/·--- ··/···· ··- ·-/-· ··/-·· ·/-··- ·· ·-/--·· ·- ··/- ··/-·-- ·- -·/·--- ·· ·- -· --·/--·· ···· ··-/·-·· ··/·-- ---/-- · -·/·--- ·· ·/··· ··- ---/--· ··- ·- -·/··-· ·- -· --·/·--- ··/·-·· ··/·--- ·· -·'
  }

  // 复制摩斯码到剪贴板
  private async copyMorseCode(content: string): Promise<void> {
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, content)
      const systemPasteboard = pasteboard.getSystemPasteboard()
      await systemPasteboard.setData(pasteData)

      if (this.resourceMgr) {
        const message = await this.resourceMgr.getStringByName('copied')
        const uiContext = this.getUIContext()
        if (uiContext) {
          uiContext.getPromptAction().showToast({
            message: message,
            duration: 2000
          })
        }
      }
    } catch (error) {
      console.error('[MePage] Failed to copy morse code:', error)
    }
  }

  @Builder
  MorseCodeFootnote() {
    // 只在中文语言时显示
    if (this.currentLanguage.startsWith('zh')) {
      Column() {
        if (this.isMorseCodeExpanded) {
          Text(this.getPinyinMorseCode())
            .fontSize(11)
            .fontColor('#666666')
            .fontFamily('monospace')
            .lineHeight(16)
            .width('100%')
            .padding({ top: 16, bottom: 8, left: 16, right: 16 })
        } else {
          Text(this.getPinyinMorseCode())
            .fontSize(11)
            .fontColor('#666666')
            .fontFamily('monospace')
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .lineHeight(16)
            .width('100%')
            .padding({ top: 16, bottom: 8, left: 16, right: 16 })
        }

        // 展开/收起按钮和复制按钮
        Row() {
          Row() {
            Text(this.isMorseCodeExpanded ? $r('app.string.collapse') : $r('app.string.expand'))
              .fontSize(12)
              .fontColor('#999999')
            
            Image($rawfile('ic_arrow_right.svg'))
              .width(12)
              .height(12)
              .fillColor('#999999')
              .rotate({ angle: this.isMorseCodeExpanded ? 90 : 0 })
          }
          .onClick(() => {
            this.isMorseCodeExpanded = !this.isMorseCodeExpanded
          })
          
          Blank()
          
          if (this.isMorseCodeExpanded) {
            Button() {
              Image($rawfile('ic_copy.svg'))
                .width(14)
                .height(14)
            }
            .type(ButtonType.Normal)
            .backgroundColor(Color.Transparent)
            .width(32)
            .height(32)
            .onClick(() => {
              this.copyMorseCode(this.getPinyinMorseCode())
            })
          }
        }
        .width('100%')
          .padding({ left: 16, right: 16, bottom: 8 })
          .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
        .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder OtherAppsSection() {
    // 其他应用部分
    Column() {
      Text($r('app.string.other_apps'))
        .fontSize(14)
        .fontWeight(FontWeight.Normal)
        .fontColor('#999999')
        .margin({ top: 30, bottom: 12, left: 16 })
        .alignSelf(ItemAlign.Start)

      // 财会工具箱应用卡片（首位）
      Row() {
        Image($rawfile('appicon_caikuai.png'))
          .width(48)
          .height(48)
          .borderRadius(8)
          .margin({ right: 16 })

        Column() {
          Text($r('app.string.app_name_caikuai'))
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
        .margin({ bottom: 8 })
        .onClick(() => {
          this.openCaikuaiApp()
        })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)

      // 独立开发助手应用卡片
      Row() {
        Image($rawfile('appicon_devassistant.png'))
          .width(48)
          .height(48)
          .borderRadius(8)
          .margin({ right: 16 })

        Column() {
          Text($r('app.string.app_name_dev_assistant'))
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
        .margin({ bottom: 8 })
        .onClick(() => {
          this.openDevAssistantApp()
        })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)

      // 码上学（Rust Master）应用卡片，图标与名称来自 rustmaster 项目
      Row() {
        Image($rawfile('appicon_rustmaster.png'))
          .width(48)
          .height(48)
          .borderRadius(8)
          .margin({ right: 16 })

        Column() {
          Text($r('app.string.app_name_rustmaster'))
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
        .margin({ bottom: 8 })
        .onClick(() => {
          this.openRustApp()
        })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)

      // 脚注 - 拼音摩斯码
      this.MorseCodeFootnote()
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
                // 振动反馈设置（首位）
                this.VibrationSettingsItem()
                Divider().strokeWidth(1).color('#222222')

                // 按键设置（单双键 + 长按阈值）
                this.KeySettingsSettingsItem()
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
                if (this.currentLanguage.startsWith('zh')) {
                  Divider().strokeWidth(1).color('#222222')
                  this.WechatGroupSettingsItem()
                }
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
              // 手表版已上线提示
              Text($r('app.string.watch_version_available'))
                .fontSize(14)
                .fontColor('#AAAAAA')
                .padding({ bottom: 16 })

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

        // 按键设置对话框（单双键 + 长按阈值）
        if (this.showKeySettingsDialog) {
          Stack() {
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor('rgba(0, 0, 0, 0.5)')
              .onClick(() => {
                this.showKeySettingsDialog = false
              })
            Column() {
              this.KeySettingsDialog()
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
