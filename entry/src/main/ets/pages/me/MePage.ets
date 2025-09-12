import { promptAction } from '@kit.ArkUI'
import { common, Want } from '@kit.AbilityKit'
import pasteboard from '@ohos.pasteboard'
import { i18nService, LanguageOption } from '../../services/I18nService'

@Component
export struct MePage {
  @State appVersion: string = '1.0.1'
  // 使用 StorageLink 监听语言变化，触发UI重新渲染
  @StorageLink('currentLanguage') currentLanguage: string = 'zh-CN'
  @StorageLink('languageRefreshTrigger') refreshTrigger: number = 0

  aboutToAppear() {
    this.loadAppInfo()
  }

  private loadAppInfo() {
    this.appVersion = '1.0.1'
  }

  // 使用说明
  private showInstructions() {
    promptAction.showDialog({
      title: i18nService.t('instructions_title'),
      message: i18nService.t('instructions_content'),
      buttons: [
        {
          text: i18nService.t('got_it'),
          color: '#0A59F7'
        }
      ],
      alignment: DialogAlignment.Center
    }).then((result) => {
      console.log('用户确认了使用说明')
    })
  }

  // 评分和反馈
  private showRating() {
    this.openAppGallery()
  }

  // 分享应用
  private shareApp(): void {
    try {
      const shareText = i18nService.t('share_text')

      const sysPB = pasteboard.getSystemPasteboard()
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, shareText)
      sysPB.setPasteData(pasteData)

      promptAction.showToast({
        message: i18nService.t('share_copied'),
        duration: 2000
      })
    } catch (error) {
      console.error('复制到剪贴板失败:', error)
      promptAction.showToast({
        message: i18nService.t('copy_failed'),
        duration: 2000
      })
    }
  }

  // 打开应用市场进行评分和反馈
  private openAppGallery(): void {
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
        promptAction.showToast({
          message: i18nService.t('opening_app_gallery'),
          duration: 1500
        })
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
        promptAction.showToast({
          message: $r('app.string.opened_via_browser'),
          duration: 2000
        })
      }).catch((error: Error) => {
        console.error('浏览器打开应用市场失败:', error)
        promptAction.showToast({
          message: $r('app.string.cannot_open_app_gallery'),
          duration: 3000
        })
      })
    } catch (error) {
      console.error('备选方案异常:', error)
      promptAction.showToast({
        message: $r('app.string.cannot_open_app_gallery'),
        duration: 3000
      })
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
        promptAction.showToast({
          message: $r('app.string.opened_via_browser'),
          duration: 2000
        })
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
        promptAction.showToast({
          message: $r('app.string.opened_via_browser'),
          duration: 2000
        })
      }).catch((error: Error) => {
        console.error('通过浏览器打开应用市场失败:', error)
        promptAction.showToast({
          message: $r('app.string.cannot_open_app_gallery'),
          duration: 3000
        })
      })
    } catch (error) {
      console.error('通过浏览器打开应用市场异常:', error)
      promptAction.showToast({
        message: $r('app.string.cannot_open_app_gallery'),
        duration: 3000
      })
    }
  }

  @State private showLanguageDialog: boolean = false

  @Builder LanguageSelectorDialog() {
    Column() {
      Row() {
        Text(i18nService.t('language_selection_title'))
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
        ForEach(i18nService.getSupportedLanguages(), (language: LanguageOption) => {
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
            await i18nService.setLanguage(language.code)
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
    .constraintSize({ maxWidth: 480, maxHeight: '60%' })
  }

  @Builder SettingsItem(title: Resource | string, onClick: () => void) {
    Row() {
      Column() {
        Text(title)
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
    .height(52)
    .padding({ left: 16, right: 16 })
    .onClick(onClick)
  }

  build() {
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

        Text(i18nService.t('app_name'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ bottom: 4 })

        Row() {
          Text(i18nService.t('version'))
            .fontSize(14)
            .fontColor('#B0B0B0')
          Text(` ${this.appVersion}`)
            .fontSize(14)
            .fontColor('#B0B0B0')
        }
        }
        .width('100%')
        .padding({ top: 60, bottom: 40 })
        .alignItems(HorizontalAlign.Center)

        // 设置项（黑色背景卡片 + 分割线，无图标）
        Column() {
        // 盒子容器
        Column() {
          // 语言切换条目
          this.SettingsItem(i18nService.t('language'), () => {
            this.showLanguageDialog = true
          })
          Divider().strokeWidth(1).color('#222222')

          this.SettingsItem(i18nService.t('instructions'), () => {
            this.showInstructions()
          })
          Divider().strokeWidth(1).color('#222222')

          this.SettingsItem(i18nService.t('rating_feedback'), () => {
            this.openAppGallery()
          })
          Divider().strokeWidth(1).color('#222222')

          this.SettingsItem(i18nService.t('share_app'), () => {
            this.shareApp()
          })
        }
        .width('100%')
        .backgroundColor('#111111')
        .borderRadius(12)
        .border({ width: 1, color: '#222222' })
        .padding({ top: 4, bottom: 4 })
        .constraintSize({ maxWidth: 400 })

        // 其他应用部分
        Column() {
          Text(i18nService.t('other_apps'))
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
              Text(i18nService.t('periodic_table_app'))
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
      .width('100%')
      .padding({ left: 20, right: 20 })
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      // 底部
      Column() {
        Text(i18nService.t('copyright'))
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ bottom: 20 })
      .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000000')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .id(`me_page_${this.refreshTrigger}`)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .scrollable(ScrollDirection.Vertical)
      .scrollBarColor('#000000')
      .scrollBarWidth(0)

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
    }
    .width('100%')
    .height('100%')
  }
}
