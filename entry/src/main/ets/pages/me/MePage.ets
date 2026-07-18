import { promptAction } from '@kit.ArkUI'
import { common, Want } from '@kit.AbilityKit'
import pasteboard from '@ohos.pasteboard'
import { resourceManager } from '@kit.LocalizationKit'
import { BusinessError } from '@kit.BasicServicesKit'
import preferences from '@ohos.data.preferences'
import { systemShare } from '@kit.ShareKit'
import { uniformTypeDescriptor } from '@kit.ArkData'
import { vibratorService } from '../../services/VibratorService'
import {
  showCommentDialogManual
} from '../../utils/AppGalleryCommentHelper'
import { LocalizationHelper } from '../../utils/LocalizationHelper'

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

const MORSE_APP_ID = 'com.douhua.morsecode'
const MORSE_APP_DETAIL_URL = `https://appgallery.huawei.com/app/detail?id=${MORSE_APP_ID}`
const MORSE_APP_REVIEW_STORE_URI = `store://appgallery.huawei.com/app/detail?id=${MORSE_APP_ID}&action=write-review`
const MORSE_APP_REVIEW_LINK = `${MORSE_APP_DETAIL_URL}&action=write-review`

@Component
export struct MePage {
  @State appVersion: string = '3.0.0'
  @StorageLink('currentLanguage') currentLanguage: string = this.getInitialLanguage()
  @State useSingleButton: boolean = false // 是否使用单按钮模式
  @State showKeySettingsDialog: boolean = false // 按键设置（单双键 + 长按阈值）对话框
  @State keySettingsSingleButton: boolean = false // 对话框内选择的单键与否，默认双键
  @State keySettingsSliderValue: number = 300
  @State vibrationEnabled: boolean = true // 振动反馈开关
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
    // 加载按键设置（长按时间）
    await this.loadLongPressThresholdPreference()
    // 加载振动偏好设置
    await this.loadVibrationPreference()

    this.loadAppInfo()
  }

  // 获取初始语言（与冷启动一致：默认英文，按系统语言映射）
  private getInitialLanguage(): string {
    return LocalizationHelper.detectPreferredLanguage()
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
      LocalizationHelper.applyAppPreferredLanguage(languageCode)

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

  private loadAppInfo() {
    this.appVersion = '3.0.0'
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

  // 打开应用市场进行评分和反馈：优先应用内评论弹窗，失败时跳转写评论页
  private async openAppGallery(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const shownInApp = await showCommentDialogManual(context)
      if (shownInApp) {
        return
      }
      await this.openAppGalleryWriteReview(context)
    } catch (error) {
      console.error('[MePage] 打开评分入口异常:', error)
      this.openAppGalleryByBrowser()
    }
  }

  private async openAppGalleryWriteReview(context: common.UIAbilityContext): Promise<void> {
    try {
      const want: Want = {
        action: 'ohos.want.action.appdetail',
        uri: MORSE_APP_REVIEW_STORE_URI
      }
      await context.startAbility(want)
    } catch (error) {
      console.error('[MePage] Deep Linking 打开应用市场写评论页失败:', error)
      await this.openAppGalleryWriteReviewByLink(context)
    }
  }

  private async openAppGalleryWriteReviewByLink(context: common.UIAbilityContext): Promise<void> {
    try {
      await context.openLink(MORSE_APP_REVIEW_LINK, { appLinkingOnly: false })
    } catch (error) {
      console.error('[MePage] App Linking 打开应用市场写评论页失败:', error)
      this.openAppGalleryByBrowser()
    }
  }

  // 通过浏览器打开应用市场写评论页作为备选方案
  private openAppGalleryByBrowser(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: MORSE_APP_REVIEW_LINK
      }

      context.startAbility(want).then(() => {
        // 通过浏览器打开成功，无需toast提示
      }).catch((error: Error) => {
        console.error('浏览器打开应用市场失败:', error)
      })
    } catch (error) {
      console.error('备选方案异常:', error)
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

                // 语言切换条目
                this.LanguageSettingsItem()
                Divider().strokeWidth(1).color('#222222')

                this.RatingSettingsItem()
                Divider().strokeWidth(1).color('#222222')

                this.ShareSettingsItem()
              }
              .width('100%')
                .backgroundColor('#111111')
                .borderRadius(12)
                .border({ width: 1, color: '#222222' })
                .padding({ top: 4, bottom: 4 })
                .constraintSize({ maxWidth: 400 })
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
