import { MorseCodeData } from '../../models/MorseCode'
import window from '@ohos.window'

@Component
export struct TranslatePage {
  @State isTextToMorse: boolean = true
  @State textInput: string = ''
  @State morseInput: string = ''

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

  private getOutput(): string {
    if (this.isTextToMorse) {
      return MorseCodeData.textToMorse(this.textInput)
    } else {
      return MorseCodeData.morseToText(this.morseInput)
    }
  }

  @Builder
  private TitleBar() {
    Row() {
      Text('翻译')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
    }
    .height(52)
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#000000')
  }

  @Builder
  private ModeToggle() {
    Row() {
      // 文本 → 电码
      Button('文本 → 电码')
        .onClick(() => { this.isTextToMorse = true })
        .backgroundColor(this.isTextToMorse ? '#FFD700' : '#1A1A1A')
        .fontColor(this.isTextToMorse ? '#000000' : '#B0B0B0')
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .margin({ right: 8 })
        .border({ width: 1, color: '#333333' })

      // 电码 → 文本
      Button('电码 → 文本')
        .onClick(() => { this.isTextToMorse = false })
        .backgroundColor(!this.isTextToMorse ? '#FFD700' : '#1A1A1A')
        .fontColor(!this.isTextToMorse ? '#000000' : '#B0B0B0')
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .border({ width: 1, color: '#333333' })
    }
    .justifyContent(FlexAlign.Center)
    .padding(12)
  }

  @Builder
  private InputArea() {
    Column() {
      if (this.isTextToMorse) {
        TextArea({ placeholder: '在此输入文本，如: Hello World' })
          .height(180)
          .fontSize(24)
          .fontColor(Color.White)
          .placeholderColor(Color.White)
          .caretColor(Color.White)
          .margin(12)
          .onChange((v: string) => { this.textInput = v })
      } else {
        TextArea({ placeholder: '在此输入电码，如: ··· --- ···' })
          .height(180)
          .fontSize(24)
          .fontColor(Color.White)
          .placeholderColor(Color.White)
          .caretColor(Color.White)
          .margin(12)
          .onChange((v: string) => { this.morseInput = v })
      }

      if (this.isTextToMorse) {
        // Quick input row (styled chips)
        Scroll() {
          Row() {
            Button('SOS')
              .onClick(() => { this.textInput = 'SOS' })
              .backgroundColor('#1A1A1A')
              .fontColor('#FFFFFFCC')
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .border({ width: 1, color: '#333333' })
              .margin({ right: 6 })

            Button('Hello')
              .onClick(() => { this.textInput = 'Hello' })
              .backgroundColor('#1A1A1A')
              .fontColor('#FFFFFFCC')
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .border({ width: 1, color: '#333333' })
              .margin({ right: 6 })

            Button('World')
              .onClick(() => { this.textInput = 'World' })
              .backgroundColor('#1A1A1A')
              .fontColor('#FFFFFFCC')
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .border({ width: 1, color: '#333333' })
              .margin({ right: 6 })

            Button('Test')
              .onClick(() => { this.textInput = 'Test' })
              .backgroundColor('#1A1A1A')
              .fontColor('#FFFFFFCC')
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .border({ width: 1, color: '#333333' })
              .margin({ right: 6 })

            Button('中国')
              .onClick(() => { this.textInput = '中国' })
              .backgroundColor('#1A1A1A')
              .fontColor('#FFFFFFCC')
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .border({ width: 1, color: '#333333' })
              .margin({ right: 6 })

            Button('你好')
              .onClick(() => { this.textInput = '你好' })
              .backgroundColor('#1A1A1A')
              .fontColor('#FFFFFFCC')
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .border({ width: 1, color: '#333333' })
              .margin({ right: 6 })
          }
          .padding({ left: 12, right: 12, bottom: 8 })
        }.scrollable(ScrollDirection.Horizontal)
      }
    }
    .backgroundColor('#1A1A1A')
    .borderRadius(12)
    .margin({ left: 12, right: 12 })
    .border({ width: 1, color: '#333333' })
  }

  @Builder
  private OutputArea() {
    Column() {
      TextArea({ text: this.getOutput().length > 0 ? this.getOutput() : '输出将在此显示' })
        .height(180)
        .fontSize(24)
        .margin(12)
        .backgroundColor(Color.Transparent)
        .fontColor('#FFFFFF')
        .fontFamily(this.isTextToMorse ? 'monospace' : '')
        .enabled(false)
    }
    .backgroundColor('#1A1A1A')
    .borderRadius(12)
    .margin({ left: 12, right: 12, bottom: 12 })
    .border({ width: 1, color: '#333333' })
  }

  build() {
    Column() {
      this.TitleBar()
      this.ModeToggle()
      this.InputArea()
      Blank().height(16)
      this.OutputArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
