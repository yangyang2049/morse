import { router } from '@kit.ArkUI'
import window from '@ohos.window'

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
      this.sections = new Map([
        ['摩斯密码基础', [
          '摩斯密码是以"点（·）和划（-）"为基本元素的字符编码系统。',
          '通过不同的点划组合来表示字母、数字和符号。',
          '每个字符都有唯一的摩斯密码表示。'
        ]],
        ['字符构成规律', [
          '点（·）：短信号，通常持续1个单位时间',
          '划（-）：长信号，通常持续3个单位时间',
          '字符间隔：3个单位时间',
          '单词间隔：7个单位时间'
        ]],
        ['时序规则', [
          '1:3:7比例是摩斯密码的核心规则',
          '点=1单位，划=3单位，字符间隔=3单位，单词间隔=7单位',
          '这个精确的时序确保了信息传输的准确性'
        ]],
        ['应用场景', [
          '军事通信：部队间的秘密通信',
          '航空通信：飞行员与地面控制塔通信',
          '航海通信：船舶间通信',
          '紧急求救：SOS信号'
        ]]
      ])
    } else if (this.testType === 'chinese') {
      this.sections = new Map([
        ['中文摩尔斯电码基础', [
          '中文摩尔斯电码是专门为中文汉字设计的编码系统。',
          '通过点（·）和划（-）的组合表示中文字符。',
          '结合了传统摩尔斯电码原理和中文语言特点。'
        ]],
        ['编码特点', [
          '中文编码通常比英文更长',
          '每个汉字都有唯一的摩尔斯电码表示',
          '编码长度增加是为了确保字符的唯一性'
        ]],
        ['历史发展', [
          '1920年代：初步制定中文摩尔斯电码标准',
          '国际电信联盟（ITU）参与制定',
          '经过多次优化形成现代标准'
        ]],
        ['应用场景', [
          '军事通信：部队间的秘密通信',
          '航空通信：飞行员与地面控制塔通信',
          '航海通信：船舶间通信'
        ]]
      ])
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
  buildDefaultSection(title: string, contents: string[]) {
    Column() {
      ForEach(contents, (content: string, index: number) => {
        Column() {
          this.buildBulletLine(content)
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
          .opacity(0.1)
          .align(Alignment.BottomEnd)
          .margin({ right: 8, bottom: 8 })

        // Main content
        Column() {
          Text(title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ bottom: 24 })
            .alignSelf(ItemAlign.Start)

          Scroll() {
            this.buildDefaultSection(title, contents)
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
        .width('100%')
        .height('100%')
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
      Row() {
        Text('📋').fontSize(24).margin({ right: 8 })
        Text(this.testTitle)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF8C00')
          .alignSelf(ItemAlign.Center)
      }
      .margin({ bottom: 32 })

      Text(`测试你对${this.title}的掌握程度`)
        .fontSize(16)
        .fontColor('#FF8C00')
        .margin({ bottom: 32 })

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
      .margin({ bottom: 32 })
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

      Blank().height(24)
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