import { router } from '@kit.ArkUI'

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
    Column() {
      Row() {
        Column() {
          Text(item.label)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Start)
          
          Text(item.desc)
            .fontSize(14)
            .fontColor('#CCCCCC')
            .textAlign(TextAlign.Start)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('>')
          .fontSize(20)
          .fontColor('#CCCCCC')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    }
    .width('100%')
    .backgroundColor('#1A1A1A')
    .borderRadius(12)
    .border({ width: 1, color: '#333333' })
    .onClick(() => {
      this.openPractice(item.label)
    })
  }

  build() {
    Column() {
      // 标题
      Text('选择练习难度')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .margin({ top: 40, bottom: 40 })

      // 难度选项
      Column() {
        ForEach(this.difficulties, (item: DifficultyItem, index: number) => {
          this.DifficultyCard(item)
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .justifyContent(FlexAlign.Center)
  }
}
