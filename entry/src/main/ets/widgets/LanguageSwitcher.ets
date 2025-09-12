import { i18nService, LanguageOption } from '../services/I18nService'
import { promptAction } from '@kit.ArkUI'

/**
 * 语言切换器组件
 * 提供语言选择对话框和切换功能
 */
@Component
export struct LanguageSwitcher {
  // 监听当前语言变化
  @StorageLink('currentLanguage') currentLanguage: string = 'zh-CN'
  
  // 控制对话框显示
  @State private showLanguageDialog: boolean = false
  
  // 支持的语言列表
  private supportedLanguages: LanguageOption[] = i18nService.getSupportedLanguages()

  build() {
    Row() {
      Column() {
        Text(i18nService.t('language'))
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
    .onClick(() => {
      this.showLanguageDialog = true
    })
    .bindSheet($$this.showLanguageDialog, this.LanguageSelectionSheet(), {
      height: 280,
      showClose: true,
      dragBar: false,
      onDisappear: () => {
        this.showLanguageDialog = false
      }
    })
  }

  /**
   * 语言选择底部弹窗
   */
  @Builder
  LanguageSelectionSheet() {
    Column({ space: 0 }) {
      // 标题
      Text(i18nService.t('language_selection_title'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 20, bottom: 8 })
      
      // 描述
      Text(i18nService.t('language_selection_content'))
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })
      
      // 语言选项列表
      Column({ space: 0 }) {
        ForEach(this.supportedLanguages, (language: LanguageOption, index: number) => {
          this.LanguageOptionItem(language, index === 0)
        })
      }
      .width('100%')
      .backgroundColor($r('app.color.background_secondary'))
      .borderRadius(12)
      .margin({ left: 20, right: 20 })
      
      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
  }

  /**
   * 语言选项条目
   */
  @Builder
  LanguageOptionItem(language: LanguageOption, isFirst: boolean) {
    Row() {
      Column({ space: 4 }) {
        Text(language.nativeName)
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
        
        Text(language.name)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 选中状态指示器
      if (this.currentLanguage === language.code) {
        Image($rawfile('ic_check.svg'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.accent'))
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor(Color.Transparent)
    .borderRadius(isFirst ? { topLeft: 12, topRight: 12 } : 0)
    .onClick(() => {
      this.switchLanguage(language.code)
    })
    
    // 分割线（除了最后一项）
    if (language.code !== this.supportedLanguages[this.supportedLanguages.length - 1].code) {
      Divider()
        .color($r('app.color.divider'))
        .strokeWidth(0.5)
        .margin({ left: 16, right: 16 })
    }
  }

  /**
   * 切换语言
   * @param languageCode 目标语言代码
   */
  private async switchLanguage(languageCode: string): Promise<void> {
    try {
      if (languageCode === this.currentLanguage) {
        this.showLanguageDialog = false
        return
      }

      // 切换语言
      await i18nService.setLanguage(languageCode)
      
      // 关闭对话框
      this.showLanguageDialog = false
      
      // 显示成功提示
      promptAction.showToast({
        message: i18nService.t('language_switched'),
        duration: 2000
      })
      
    } catch (error) {
      console.error('[LanguageSwitcher] Failed to switch language:', error)
      
      // 显示错误提示
      promptAction.showToast({
        message: i18nService.t('language_switch_failed'),
        duration: 2000
      })
    }
  }
}

/**
 * 简单的语言切换按钮组件
 * 用于快速切换中英文
 */
@Component
export struct SimpleLanguageSwitcher {
  @StorageLink('currentLanguage') currentLanguage: string = 'zh-CN'

  build() {
    Button() {
      Row({ space: 6 }) {
        Image($rawfile('ic_translate.svg'))
          .width(18)
          .height(18)
          .fillColor($r('app.color.text_primary'))
        
        Text(i18nService.isChinese() ? 'EN' : '中')
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
      }
    }
    .backgroundColor($r('app.color.background_secondary'))
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .borderRadius(16)
    .onClick(() => {
      this.toggleLanguage()
    })
  }

  /**
   * 快速切换中英文
   */
  private async toggleLanguage(): Promise<void> {
    try {
      const targetLang = i18nService.isChinese() ? 'en-US' : 'zh-CN'
      await i18nService.setLanguage(targetLang)
      
      promptAction.showToast({
        message: i18nService.t('language_switched'),
        duration: 1500
      })
    } catch (error) {
      console.error('[SimpleLanguageSwitcher] Failed to toggle language:', error)
      
      promptAction.showToast({
        message: i18nService.t('language_switch_failed'),
        duration: 2000
      })
    }
  }
}
