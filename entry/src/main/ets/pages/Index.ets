import { LearnPage } from './learn/LearnPage'
import { PracticeDifficultyPage } from './practice/PracticeDifficultyPage'
import { TranslatePage } from './translate/TranslatePage'
import { CodeTablePage } from './codetable/CodeTablePage'
import { MePage } from './me/MePage'
import { audioService } from '../services/AudioService'
import { Context } from '@kit.AbilityKit'
import deviceInfo from '@ohos.deviceInfo'
import { i18n } from '@kit.LocalizationKit'
// Window system bar properties are managed globally in EntryAbility

@Entry
@Component
  struct Index {
  @State currentIndex: number = 0
  @State isTablet: boolean = false

  @StorageLink('currentLanguage') currentLanguage: string = this.getInitialLanguage()

  @StorageLink('languageRefreshTrigger') languageRefreshTrigger: number = 0

  @State pageRebuildKey: number = 0

  aboutToAppear() {
    // 检查是否为平板设备
    this.checkDeviceType()

    this.initAudioService()

    this.watchLanguageChanges()
  }

  // 获取初始语言
  private getInitialLanguage(): string {
    try {
      const currentLocale = i18n.System.getSystemLocale()
      console.log(`[INDEX] System locale: ${currentLocale}`)
      // 将系统locale转换为我们的语言代码格式
      if (currentLocale.startsWith('zh')) {
        return 'zh-CN'
      } else if (currentLocale.startsWith('en')) {
        return 'en-US'
      }
      return 'zh-CN' // 默认中文
    } catch (error) {
      console.error('[INDEX] Failed to get initial language:', error)
      return 'zh-CN' // 默认中文
    }
  }

  // 检查设备类型
  private checkDeviceType() {
    try {
      const deviceType = deviceInfo.deviceType
      this.isTablet = deviceType === 'tablet'
      console.log(`[INDEX] Device type: ${deviceType}, isTablet: ${this.isTablet}`)
    } catch (error) {
      console.error('[INDEX] Error getting device type:', error)
      this.isTablet = false
    }
  }

  // 监听语言变化
  private watchLanguageChanges() {
    // 使用watcher监听languageRefreshTrigger的变化
    let lastTrigger = this.languageRefreshTrigger
    const checkLanguageChange = () => {
      if (this.languageRefreshTrigger !== lastTrigger) {
        console.log('[INDEX] Language changed, rebuilding all pages')
        lastTrigger = this.languageRefreshTrigger
        // 递增页面重建键，强制所有页面重新构建
        this.pageRebuildKey++
      }
      // 继续监听
      setTimeout(checkLanguageChange, 100)
    }
    checkLanguageChange()
  }

  // 初始化音频服务
  private async initAudioService() {
    try {
      // 获取当前页面的Context
      const context = getContext(this) as Context
      await audioService.init(context)
      console.log('[INDEX] AudioService initialized successfully')
    } catch (error) {
      console.error('[INDEX] Failed to initialize AudioService:', error)
    }
  }


  @Builder TabBuilder(targetIndex: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
        .size({ width: 28, height: 28 })
    }
    .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
  }

  build() {
    Tabs({
      barPosition: this.isTablet ? BarPosition.Start : BarPosition.End,
      controller: new TabsController(),
      index: this.currentIndex
    }) {
      TabContent() {
        // 使用pageRebuildKey强制重建页面，确保语言切换时页面完全刷新
        if (this.pageRebuildKey >= 0) {
          LearnPage()
        }
      }
      .tabBar(this.TabBuilder(0, $rawfile('ic_learn.svg'), $rawfile('ic_learn_light.svg')))

      TabContent() {
        // 使用pageRebuildKey强制重建页面，确保语言切换时页面完全刷新
        if (this.pageRebuildKey >= 0) {
          PracticeDifficultyPage()
        }
      }
      .tabBar(this.TabBuilder(1, $rawfile('ic_train.svg'), $rawfile('ic_train_light.svg')))

      TabContent() {
        // 使用pageRebuildKey强制重建页面，确保语言切换时页面完全刷新
        if (this.pageRebuildKey >= 0) {
          TranslatePage()
        }
      }
      .tabBar(this.TabBuilder(2, $rawfile('ic_translate.svg'), $rawfile('ic_translate_light.svg')))

      TabContent() {
        // 使用pageRebuildKey强制重建页面，确保语言切换时页面完全刷新
        if (this.pageRebuildKey >= 0) {
          CodeTablePage()
        }
      }
      .tabBar(this.TabBuilder(3, $rawfile('ic_table.svg'), $rawfile('ic_table_light.svg')))

      TabContent() {
        // 使用pageRebuildKey强制重建页面，确保语言切换时页面完全刷新
        if (this.pageRebuildKey >= 0) {
          MePage()
        }
      }
      .tabBar(this.TabBuilder(4, $rawfile('ic_me.svg'), $rawfile('ic_me_light.svg')))
    }
    .vertical(this.isTablet)
      .scrollable(false)
      .barMode(BarMode.Fixed)
      .barBackgroundColor(Color.Black)
      .animationDuration(400)
      .onChange((index: number) => {
        this.currentIndex = index
      })
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
