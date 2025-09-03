import router from '@ohos.router'
import window from '@ohos.window'

@Entry
@Component
struct KnowledgeLessonPage {
  @State title: string = '摩斯密码基础知识'
  @State content: string = '摩斯密码是一种以"点（·）和划（-）"为基本元素的字符编码系统。通过不同的点划组合来表示字母、数字和符号。'
  @State customSections: string[] = []

  aboutToAppear() {
    // Set status bar color
    window.getLastWindow(getContext(this)).then((windowClass) => {
      windowClass.setWindowSystemBarProperties({
        statusBarColor: '#1A1A1A',
        isStatusBarLightIcon: false
      })
    })
  }

  @Builder
  TitleBar() {
    Row() {
      Button() {
        Image($rawfile('ic_back.svg'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        router.back()
      })

      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank().width(40) // Balance the back button
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#1A1A1A')
  }

  @Builder
  ContentCard() {
    Column() {
      Text(this.content)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .lineHeight(24)
        .textAlign(TextAlign.Start)
        .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#2A2A2A')
    .border({ width: 1, color: '#333333' })
    .borderRadius(12)
  }

  @Builder
  CustomSections() {
    if (this.customSections.length > 0) {
      Column() {
        ForEach(this.customSections, (section: string, index: number) => {
          Column() {
            Text(section)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .lineHeight(24)
              .textAlign(TextAlign.Start)
              .width('100%')
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#2A2A2A')
          .border({ width: 1, color: '#333333' })
          .borderRadius(12)
          .margin({ top: index > 0 ? 20 : 0 })
        })
      }
    }
  }

  @Builder
  CompleteButton() {
    Button() {
      Text('完成学习')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
    }
    .width('100%')
    .height(48)
    .backgroundColor('#FFD700')
    .borderRadius(12)
    .onClick(() => {
      router.back()
    })
  }

  build() {
    Column() {
      this.TitleBar()

      Scroll() {
        Column() {
          // Main content
          this.ContentCard()

          // Custom sections
          this.CustomSections()

          Blank().height(40)

          // Complete button
          this.CompleteButton()
        }
        .padding(16)
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1A1A1A')
  }
}
