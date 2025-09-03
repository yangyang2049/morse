import { router } from '@kit.ArkUI'
import window from '@ohos.window'

interface DifficultyItem {
  label: string
  desc: string
}

@Entry
@Component
export struct PracticeDifficultyPage {
  private difficulties: DifficultyItem[] = [
    { label: '简单', desc: '仅字母' },
    { label: '中等', desc: '字母 + 数字' },
    { label: '困难', desc: '全部字符' }
  ]

  aboutToAppear() {
    // Set status bar color
    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()
    if (hostContext) {
      window.getLastWindow(hostContext).then((windowClass) => {
        windowClass.setWindowSystemBarProperties({
          statusBarColor: '#000000',
          statusBarContentColor: '#FFFFFF'
        })
      })
    }
  }

  private openPractice(difficulty: string): void {
    console.error(`[PracticeDifficulty] opening practice page with difficulty=${difficulty}`)
    router.pushUrl({
      url: 'pages/PracticePage',
      params: {
        difficulty: difficulty
      }
    })
  }

  @Builder
  private DifficultyCard(item: DifficultyItem) {
    // 居中文本的卡片项
    Column() {
      // 内容垂直居中对齐
      Column() {
        Text(item.label)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)

        Text(item.desc)
          .fontSize(12)
          .fontColor('#CCCCCC')
          .textAlign(TextAlign.Center)
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .padding({ left: 16, right: 16, top: 18, bottom: 18 })
    }
    .width('100%')
    .backgroundColor('#1A1A1A')
    .borderRadius(14)
    .border({ width: 1, color: '#333333' })
    .onClick(() => this.openPractice(item.label))
  }

  @Builder
  private TitleBar() {
    // 顶部标题栏
    Row() {
      Text('练习')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
    }
    .height(52)
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#000000')
  }

  build() {
    Column() {
      this.TitleBar()

      // 内容区域
      Column() {
        // 条目列表，条目之间留出合理的间距
        ForEach(this.difficulties, (item: DifficultyItem, index: number) => {
          Column() {
            this.DifficultyCard(item)
            if (index < this.difficulties.length - 1) {
              Blank().height(16)
            }
          }
          .width('100%')
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20 })
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
