import { LearnPage } from './learn/LearnPage'
import { PracticeDifficultyPage } from './practice/PracticeDifficultyPage'
import { TranslatePage } from './translate/TranslatePage'
import { CodeTablePage } from './codetable/CodeTablePage'
import { audioService } from '../services/AudioService'
import { Context } from '@kit.AbilityKit'
// Window system bar properties are managed globally in EntryAbility

@Entry
@Component
struct Index {
  @State currentIndex: number = 0

  aboutToAppear() {
    // System bar colors are set globally in EntryAbility
    
    // 初始化音频服务
    this.initAudioService()
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
        .size({ width: 24, height: 24 })
        .fillColor(this.currentIndex === targetIndex ? Color.White : '#aaaaaa')
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: new TabsController(), index: this.currentIndex }) {
      TabContent() {
        LearnPage()
      }
      .tabBar(this.TabBuilder(0, $rawfile('ic_learn.svg'), $rawfile('ic_learn.svg')))

      TabContent() {
        PracticeDifficultyPage()
      }
      .tabBar(this.TabBuilder(1, $rawfile('ic_train.svg'), $rawfile('ic_train.svg')))

      TabContent() {
        TranslatePage()
      }
      .tabBar(this.TabBuilder(2, $rawfile('ic_translate.svg'), $rawfile('ic_translate.svg')))

      TabContent() {
        CodeTablePage()
      }
      .tabBar(this.TabBuilder(3, $rawfile('ic_table.svg'), $rawfile('ic_table.svg')))
    }
    .vertical(false)
    .barMode(BarMode.Fixed)
    .barWidth('100%')
    .barHeight(56)
    .barBackgroundColor(Color.Black)
    .animationDuration(400)
    .onChange((index: number) => {
      this.currentIndex = index
      console.error(`[INDEX] Tab changed to index: ${index}`)
    })
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
