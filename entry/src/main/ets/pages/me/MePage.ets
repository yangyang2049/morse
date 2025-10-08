import { promptAction } from '@kit.ArkUI'
import { common, Want } from '@kit.AbilityKit'
import pasteboard from '@ohos.pasteboard'
import { resourceManager, i18n } from '@kit.LocalizationKit'
import { BusinessError } from '@kit.BasicServicesKit'
import preferences from '@ohos.data.preferences'

// 语言选项接口
interface LanguageOption {
  code: string
  nativeName: string
}

// 支持的语言列表
const SUPPORTED_LANGUAGES: LanguageOption[] = [
  { code: 'zh-CN', nativeName: '中文' },
  { code: 'en-US', nativeName: 'English' }
]

@Component
export struct MePage {
  @State appVersion: string = '1.1.0'
  @StorageLink('currentLanguage') currentLanguage: string = this.getInitialLanguage()
  @State useSingleButton: boolean = false // 是否使用单按钮模式
  @State showButtonModeDialog: boolean = false // 是否显示按钮模式选择对话框
  // 资源管理器
  private resourceMgr: resourceManager.ResourceManager | null = null
  private preferencesStore: preferences.Preferences | null = null

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

    this.loadAppInfo()
  }

  // 获取初始语言
  private getInitialLanguage(): string {
    try {
      const currentLocale = i18n.System.getSystemLocale()
      console.log(`[MePage] System locale: ${currentLocale}`)
      // 将系统locale转换为我们的语言代码格式
      if (currentLocale.startsWith('zh')) {
        return 'zh-CN'
      } else if (currentLocale.startsWith('en')) {
        return 'en-US'
      }
      return 'zh-CN' // 默认中文
    } catch (error) {
      console.error('[MePage] Failed to get initial language:', error)
      return 'zh-CN' // 默认中文
    }
  }

  aboutToDisappear() {
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
        return 'zh-CN'
      } else if (currentLocale.startsWith('en')) {
        return 'en-US'
      }
      return 'zh-CN' // 默认中文
    } catch (error) {
      console.error('[MePage] Failed to get current language:', error)
      return 'zh-CN' // 默认中文
    }
  }

  private loadAppInfo() {
    this.appVersion = '1.1.0'
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

  // 获取当前语言的显示名称
  private getCurrentLanguageDisplayName(): string {
    const language = SUPPORTED_LANGUAGES.find(lang => lang.code === this.currentLanguage)
    return language ? language.nativeName : '中文'
  }

  // 刷新语言状态 - 从AppStorage获取最新状态

  // 分享应用
  private async shareApp(): Promise<void> {
    try {
      const shareText = await this.getStringResource('share_text')

      const sysPB = pasteboard.getSystemPasteboard()
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, shareText)
      await sysPB.setPasteData(pasteData)

      // 分享成功，无需toast提示
    } catch (error) {
      console.error('[MePage] Failed to share app:', error)
      // 复制失败，无需toast提示
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
        .onClick(() => {
          this.openPeriodicTableApp()
        })
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
