import { LearnPage } from './learn/LearnPage'
import { PracticeDifficultyPage } from './practice/PracticeDifficultyPage'
import { TranslatePage } from './translate/TranslatePage'
import { CodeTablePage } from './codetable/CodeTablePage'
import { MePage } from './me/MePage'
import { audioService } from '../services/AudioService'
import { common, Context } from '@kit.AbilityKit'
import preferences from '@ohos.data.preferences'
import { DeviceHelper } from '../utils/DeviceHelper'
import { showCommentDialogIfNeeded } from '../utils/AppGalleryCommentHelper'
import { SystemBarHelper } from '../utils/SystemBarHelper'

@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  @State isTablet: boolean = false

  @StorageLink('currentLanguage') currentLanguage: string = ''

  @StorageLink('languageRefreshTrigger') languageRefreshTrigger: number = 0

  @State pageRebuildKey: number = 0

  private preferencesStore: preferences.Preferences | null = null

  async aboutToAppear() {
    SystemBarHelper.applyDarkFromUIContext(this.getUIContext())
    this.checkDeviceType()
    await this.initPreferences()
    await this.loadLastTabIndex()
    this.initAudioService()
    this.watchLanguageChanges()
  }

  onPageShow(): void {
    // 从二级页返回时系统栏可能被重置，先恢复深色栏
    SystemBarHelper.applyDarkFromUIContext(this.getUIContext())
    // 从课程页返回首页时尝试拉起应用内评分（条件不满足则静默）
    this.tryShowAppGalleryComment()
  }

  private tryShowAppGalleryComment(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      if (context) {
        void showCommentDialogIfNeeded(context)
      }
    } catch (error) {
      console.error('[INDEX] tryShowAppGalleryComment failed:', error)
    }
  }

  private async initPreferences(): Promise<void> {
    try {
      const context = getContext(this)
      this.preferencesStore = await preferences.getPreferences(context, 'app_preferences')
      console.log('[INDEX] Preferences initialized successfully')
    } catch (error) {
      console.error('[INDEX] Failed to initialize preferences:', error)
    }
  }

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

  private checkDeviceType() {
    try {
      this.isTablet = DeviceHelper.isTablet()
      console.log(`[INDEX] Device type: ${DeviceHelper.getDeviceType()}, isTablet: ${this.isTablet}`)
    } catch (error) {
      console.error('[INDEX] Error getting device type:', error)
      this.isTablet = false
    }
  }

  private watchLanguageChanges() {
    let lastTrigger = this.languageRefreshTrigger
    const checkLanguageChange = () => {
      if (this.languageRefreshTrigger !== lastTrigger) {
        console.log('[INDEX] Language changed, rebuilding all pages')
        lastTrigger = this.languageRefreshTrigger
        this.pageRebuildKey++
      }
      setTimeout(checkLanguageChange, 100)
    }
    checkLanguageChange()
  }

  private async initAudioService() {
    try {
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
    Tabs({
      barPosition: this.isTablet ? BarPosition.Start : BarPosition.End,
      controller: new TabsController(),
      index: this.currentIndex
    }) {
      TabContent() {
        if (this.pageRebuildKey >= 0) {
          LearnPage()
        }
      }
      .tabBar(this.TabBuilder(0, $rawfile('ic_learn.svg'), $rawfile('ic_learn_light.svg'), 'learn'))

      TabContent() {
        if (this.pageRebuildKey >= 0) {
          PracticeDifficultyPage()
        }
      }
      .tabBar(this.TabBuilder(1, $rawfile('ic_train.svg'), $rawfile('ic_train_light.svg'), 'practice'))

      TabContent() {
        if (this.pageRebuildKey >= 0) {
          TranslatePage()
        }
      }
      .tabBar(this.TabBuilder(2, $rawfile('ic_translate.svg'), $rawfile('ic_translate_light.svg'), 'translate'))

      TabContent() {
        if (this.pageRebuildKey >= 0) {
          CodeTablePage()
        }
      }
      .tabBar(this.TabBuilder(3, $rawfile('ic_table.svg'), $rawfile('ic_table_light.svg'), 'code_table'))

      TabContent() {
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
        this.saveCurrentTabIndex(index)
      })
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
