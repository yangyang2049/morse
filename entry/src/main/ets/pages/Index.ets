import { LearnPage } from './tabs/LearnPage'
import { PracticeDifficultyPage } from './PracticeDifficultyPage'
import { TranslatePage } from './tabs/TranslatePage'
import { CodeTablePage } from './tabs/CodeTablePage'
import window from '@ohos.window'

@Entry
@Component
struct Index {
  @State currentIndex: number = 0

  aboutToAppear() {
    // Set status bar color
    window.getLastWindow(getContext(this)).then((windowClass) => {
      windowClass.setWindowSystemBarProperties({
        statusBarColor: '#000000',
        statusBarContentColor: '#FFFFFF'
      })
    })
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
    })
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}