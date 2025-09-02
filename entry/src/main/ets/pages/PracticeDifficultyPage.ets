import { router } from '@kit.ArkUI'
import { PracticePage } from './tabs/PracticePage'

@Component
export struct PracticeDifficultyPage {
  @State selectedDifficulty: string = ''

  @Builder
  private DifficultyCard(label: string, description: string, difficulty: string) {
    Column() {
      Row() {
        Text(label)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .layoutWeight(1)

        Text('›')
          .fontSize(24)
          .fontColor(Color.White)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      Text(description)
        .fontSize(14)
        .fontColor('#FFFFFFB3')
        .alignSelf(ItemAlign.Start)
        .padding({ left: 16, right: 16, bottom: 16 })
    }
    .width('100%')
    .backgroundColor('#1A1A1A')
    .borderRadius(12)
    .onClick(() => {
      this.selectedDifficulty = difficulty
      // Navigate to practice page with selected difficulty
      router.pushUrl({
        url: 'pages/PracticePage',
        params: { difficulty: difficulty }
      })
    })
  }

  build() {
    Column() {
      // Title
      Text('选择练习难度')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .margin({ top: 40, bottom: 40 })

      // Difficulty options
      Column() {
        this.DifficultyCard('简单', '仅字母', '简单')
        
        Blank().height(12)
        
        this.DifficultyCard('中等', '字母 + 数字', '中等')
        
        Blank().height(12)
        
        this.DifficultyCard('困难', '全部字符', '困难')
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      Blank().layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .padding({ left: 16, right: 16 })
  }
}
