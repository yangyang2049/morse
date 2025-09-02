@Entry
@Component
export struct LessonPage {
  // Simple, typed lesson structure
  private sectionTitles: string[] = ['什么是摩斯电码', '基本规则']
  private sectionContents: string[][] = [
    [
      '摩斯电码用点（·）和划（-）表示字符',
      '最早用于电报通信，现常用于短波、紧急信号等',
      'SOS: ··· --- ···'
    ],
    [
      '点与划之间有短间隔，字母之间有中等间隔',
      '单词之间使用斜杠 / 分隔',
      '大小写不影响编码'
    ]
  ]

  @Builder
  private TitleBar() {
    Row() {
      Text('课程')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
    }
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.Black)
  }

  @Builder
  private SectionCard(title: string, items: string[], index: number) {
    Column() {
      // Big faded index number
      Text(`${index + 1}`)
        .fontSize(72)
        .fontWeight(FontWeight.Bold)
        .fontColor('#80808019')
        .align(Alignment.BottomEnd)
        .margin({ right: 8, bottom: 8 })

      Column() {
        Text(title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ bottom: 16 })

        // Bullet list
        Column() {
          ForEach(items, (line: string, i: number) => {
            Row() {
              Text('• ').fontColor('#FFFFFFB3')
              Text(line).layoutWeight(1)
            }
            .margin({ bottom: i < items.length - 1 ? 8 : 0 })
          }, (line: string) => `${index}_${line}`)
        }
      }
      .padding(16)
    }
    .backgroundColor('#1A1A1A')
    .border({ width: 1, color: '#333333' })
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  build() {
    Column() {
      this.TitleBar()

      // Content
      Scroll() {
        Column() {
          ForEach(this.sectionTitles, (t: string, idx: number) => {
            this.SectionCard(t, this.sectionContents[idx], idx)
          }, (t: string, idx?: number) => `${t}_${idx}`)

          // Test CTA (placeholder)
          Column() {
            Text('基础知识测试')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFD700')
              .margin({ bottom: 8 })
            Text('完成课程后进行小测验巩固所学。')
              .fontColor('#FFFFFFB3')
              .margin({ bottom: 16 })
            Button('开始测试')
              .height(44)
              .backgroundColor('#FFD700')
              .fontColor(Color.Black)
              .borderRadius(8)
          }
          .padding(16)
          .backgroundColor('#1A1A1A')
          .border({ width: 1, color: '#333333' })
          .borderRadius(12)
          .margin({ left: 16, right: 16, top: 8, bottom: 16 })
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
