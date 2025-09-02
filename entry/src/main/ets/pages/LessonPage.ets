import { router } from '@kit.ArkUI'
import window from '@ohos.window'
import { LessonData } from '../data/LessonData'

@Entry
@Component
export struct LessonPage {
  @State title: string = '摩斯密码基础课程'
  @State sections: Map<string, string[]> = new Map()
  @State testType: string = 'intro'
  @State testTitle: string = '基础知识测试'
  @State testCompletedKey: string = 'intro_test_completed'
  @State lessonCompletedKey: string = 'intro_lesson_completed'
  @State currentPageIndex: number = 0

  aboutToAppear() {
    // Set status bar color
    window.getLastWindow(getContext(this)).then((windowClass) => {
      windowClass.setWindowSystemBarProperties({
        statusBarColor: '#1A1A1A',
        isStatusBarLightIcon: false
      })
    })

    // Initialize sections based on test type
    this.initializeSections()
  }

  initializeSections() {
    if (this.testType === 'intro') {
      this.sections = LessonData.introSections
    } else if (this.testType === 'chinese') {
      this.sections = LessonData.chineseSections
    }
  }

  @Builder
  TitleBar() {
    Row() {
      Button() {
        Text('返回')
          .fontSize(16)
          .fontColor(Color.White)
      }
      .width(48)
      .height(48)
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

      Button()
        .width(48)
        .height(48)
        .backgroundColor(Color.Transparent)
        .enabled(false)
    }
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#1A1A1A')
  }

  @Builder
  buildBulletLine(text: string) {
    Row() {
      Text('• ')
        .fontColor('#FFFFFFB3')
      Text(text)
        .layoutWeight(1)
        .fontColor('#FFFFFF')
    }
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  buildSingleLine(text: string) {
    Text(text)
      .fontColor('#FFFFFF')
      .textAlign(TextAlign.Start)
      .width('100%')
  }

  @Builder
  buildDefaultSection(title: string, contents: string[]) {
    Column() {
      ForEach(contents, (content: string, index: number) => {
        Column() {
          if (contents.length === 1) {
            this.buildSingleLine(content)
          } else {
            this.buildBulletLine(content)
          }
          if (index < contents.length - 1) {
            Blank().height(8)
          }
        }
      })
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
    .width('100%')
    .align(Alignment.TopStart)
  }

  @Builder
  buildSectionCard(title: string, contents: string[], index: number) {
    Column() {
      Stack() {
        // Big faded number at bottom right
        Text(`${index + 1}`)
          .fontSize(80)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .opacity(0.25)
          .position({ x: '100%', y: '100%' })
          .translate({ x: '-100%', y: '-100%' })
          .margin({ right: 0, bottom: -10 })

        // Main content
        Column() {
          Text(title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ bottom: 32 })
            .alignSelf(ItemAlign.Start)

          Scroll() {
            this.buildDefaultSection(title, contents)
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .align(Alignment.TopStart)
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
        .width('100%')
        .height('100%')
        .padding({ top: 0 })
      }
    }
    .width(320)
    .height(480)
    .padding(16)
    .backgroundColor('#1A1A1A')
    .border({ width: 1, color: '#333333' })
    .borderRadius(12)
    .margin({ right: 16 })
  }

  @Builder
  buildTestCard() {
    Column() {
      Stack() {
        // Big faded number at bottom right
        Text('测')
          .fontSize(80)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .opacity(0.25)
          .position({ x: '100%', y: '100%' })
          .translate({ x: '-100%', y: '-100%' })
          .margin({ right: 0, bottom: -10 })

        // Main content
        Column() {
          Row() {
            Text('📋').fontSize(24).margin({ right: 8 })
            Text(this.testTitle)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF8C00')
              .alignSelf(ItemAlign.Center)
          }
          .margin({ bottom: 16 })

          Text(`测试你对${this.title}的掌握程度`)
            .fontSize(16)
            .fontColor('#FF8C00')
            .margin({ bottom: 16 })

          Text('测试内容')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF8C00')
            .margin({ bottom: 8 })
            .alignSelf(ItemAlign.Start)

          Column() {
            Text('• 2道判断题（每题20分）').fontSize(14).fontColor(Color.Black).margin({ bottom: 4 })
            Text('• 3道选择题（每题20分）').fontSize(14).fontColor(Color.Black).margin({ bottom: 4 })
            Text('• 需要100分才能通过').fontSize(14).fontColor(Color.Black)
          }
          .margin({ bottom: 16 })
          .alignItems(HorizontalAlign.Start)

          Blank().layoutWeight(1)

          Button() {
            Row() {
              Text('▶').fontSize(16).fontColor(Color.White).margin({ right: 8 })
              Text('开始测试')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
          }
          .width('100%')
          .height(48)
          .backgroundColor('#FF8C00')
          .borderRadius(8)
          .onClick(() => {
            // Navigate to quiz page
            router.pushUrl({
              url: 'pages/LessonQuizPage',
              params: {
                testType: this.testType,
                pageTitle: this.testTitle,
                testCompletedKey: this.testCompletedKey
              }
            })
          })

          Blank().height(16)
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
        .width('100%')
        .height('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
    .width(320)
    .height(480)
    .padding(16)
    .backgroundColor('#FFF8DC')
    .border({ width: 1, color: '#FF8C00' })
    .borderRadius(12)
  }

  build() {
    Column() {
      this.TitleBar()

      // PageView style with horizontal scrolling cards
      Scroll() {
        Row() {
          // Section cards
          ForEach(Array.from(this.sections.keys()), (title: string, index: number) => {
            this.buildSectionCard(title, this.sections.get(title) || [], index)
          })

          // Test card
          this.buildTestCard()
        }
        .alignItems(VerticalAlign.Top)
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1A1A1A')
  }
}