import { LearnPage } from './learn/LearnPage'
import { PracticeDifficultyPage } from './practice/PracticeDifficultyPage'
import { TranslatePage } from './translate/TranslatePage'
import { CodeTablePage } from './codetable/CodeTablePage'
import { MePage } from './me/MePage'
import { WatchIndexPage } from './WatchIndexPage'
import { audioService } from '../services/AudioService'
import { Context } from '@kit.AbilityKit'
import deviceInfo from '@ohos.deviceInfo'
import preferences from '@ohos.data.preferences'
import { DeviceHelper } from '../utils/DeviceHelper'
// Window system bar properties are managed globally in EntryAbility

@Entry
@Component
  struct Index {
  @State currentIndex: number = 0
  @State isTablet: boolean = false
  @State isWearable: boolean = false

  @StorageLink('currentLanguage') currentLanguage: string = ''

  @StorageLink('languageRefreshTrigger') languageRefreshTrigger: number = 0

  @State pageRebuildKey: number = 0

  private preferencesStore: preferences.Preferences | null = null

  async aboutToAppear() {
    // 检查设备类型
    this.checkDeviceType()

    // 初始化偏好设置并加载上次的标签页
    await this.initPreferences()
    await this.loadLastTabIndex()

    this.initAudioService()

    this.watchLanguageChanges()
  }


  // 初始化偏好设置
  private async initPreferences(): Promise<void> {
    try {
      const context = getContext(this)
      this.preferencesStore = await preferences.getPreferences(context, 'app_preferences')
      console.log('[INDEX] Preferences initialized successfully')
    } catch (error) {
      console.error('[INDEX] Failed to initialize preferences:', error)
    }
  }

  // 加载上次使用的标签页索引
  private async loadLastTabIndex(): Promise<void> {
    try {
      if (this.preferencesStore) {
        const lastIndex = await this.preferencesStore.get('last_tab_index', 0) as number
        this.currentIndex = lastIndex
        console.log(`[INDEX] Loaded last tab index: ${lastIndex}`)
      }
    } catch (error) {
      console.error('[INDEX] Failed to load last tab index:', error)
    }
  }

  // 保存当前标签页索引
  private async saveCurrentTabIndex(index: number): Promise<void> {
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.put('last_tab_index', index)
        await this.preferencesStore.flush()
        console.log(`[INDEX] Saved tab index: ${index}`)
      }
    } catch (error) {
      console.error('[INDEX] Failed to save tab index:', error)
    }
  }

  // 检查设备类型
  private checkDeviceType() {
    try {
      this.isWearable = DeviceHelper.isWearable()
      this.isTablet = DeviceHelper.isTablet()
      console.log(`[INDEX] Device type: ${DeviceHelper.getDeviceType()}, isWearable: ${this.isWearable}, isTablet: ${this.isTablet}`)
    } catch (error) {
      console.error('[INDEX] Error getting device type:', error)
      this.isWearable = false
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


  @Builder TabBuilder(targetIndex: number, selectedImg: Resource, normalImg: Resource, titleKey: string) {
    Column() {
      Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
        .size({ width: 24, height: 24 })

      Text($r(titleKey))
        .fontSize(10)
        .fontColor('#FFD700')
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .margin({ top: 2 })
    }
    .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
  }

  build() {
    // 根据设备类型显示不同的首页
    if (this.isWearable) {
      // 手表设备：显示 watch 版本的首页（使用 ArcSwiper）
      WatchIndexPage()
    } else {
      // 手机/平板设备：显示原来的首页（使用 Tabs）
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
        .tabBar(this.TabBuilder(0, $rawfile('ic_learn.svg'), $rawfile('ic_learn_light.svg'), 'learn'))

        TabContent() {
          // 使用pageRebuildKey强制重建页面，确保语言切换时页面完全刷新
          if (this.pageRebuildKey >= 0) {
            PracticeDifficultyPage()
          }
        }
        .tabBar(this.TabBuilder(1, $rawfile('ic_train.svg'), $rawfile('ic_train_light.svg'), 'practice'))

        TabContent() {
          // 使用pageRebuildKey强制重建页面，确保语言切换时页面完全刷新
          if (this.pageRebuildKey >= 0) {
            TranslatePage()
          }
        }
        .tabBar(this.TabBuilder(2, $rawfile('ic_translate.svg'), $rawfile('ic_translate_light.svg'), 'translate'))

        TabContent() {
          // 使用pageRebuildKey强制重建页面，确保语言切换时页面完全刷新
          if (this.pageRebuildKey >= 0) {
            CodeTablePage()
          }
        }
        .tabBar(this.TabBuilder(3, $rawfile('ic_table.svg'), $rawfile('ic_table_light.svg'), 'code_table'))

        TabContent() {
          // 使用pageRebuildKey强制重建页面，确保语言切换时页面完全刷新
          if (this.pageRebuildKey >= 0) {
            MePage()
          }
        }
        .tabBar(this.TabBuilder(4, $rawfile('ic_me.svg'), $rawfile('ic_me_light.svg'), 'me'))
      }
      .vertical(this.isTablet)
        .scrollable(false)
        .barMode(BarMode.Fixed)
        .barBackgroundColor(Color.Black)
        .animationDuration(400)
        .onChange((index: number) => {
          this.currentIndex = index
          // 保存当前标签页索引
          this.saveCurrentTabIndex(index)
        })
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
  }
}
