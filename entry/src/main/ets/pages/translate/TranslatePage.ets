import { MorseCodeData } from '../../models/MorseCode'
import { PinyinService } from '../../services/PinyinService'
// System bar colors are set globally in EntryAbility
import { promptAction } from '@kit.ArkUI'

@Component
export struct TranslatePage {
  @State isTextToMorse: boolean = true
  @State textInput: string = ''
  @State morseInput: string = ''
  private readonly boxFontSize: number = 16
  private readonly pillRadius: number = 20
  private screenHeight: number = 0

  aboutToAppear() {
    // System bar colors are set globally in EntryAbility
    // Preload pinyin dictionary for Chinese → pinyin conversion
    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()
    if (hostContext) {
      PinyinService.load(hostContext)
    }
  }

  private getOutput(): string {
    if (this.isTextToMorse) {
      return MorseCodeData.textToMorse(this.textInput, (char: string) => {
        // 显示中文字符不在拼音表中的提示
        promptAction.showToast({
          message: `"${char}" 不在拼音表中`,
          duration: 2000,
          bottom: '80%'
        })
      })
    } else {
      return MorseCodeData.morseToText(this.morseInput)
    }
  }

  // 添加点
  private addDot() {
    this.morseInput += '.'
  }

  // 添加划
  private addDash() {
    this.morseInput += '-'
  }

  // 添加斜杠（单词/句子分隔符）
  private addSlash() {
    this.morseInput += '/'
  }

  // 添加空格
  private addSpace() {
    this.morseInput += ' '
  }

  // 删除最后一个字符
  private deleteLast() {
    if (this.morseInput.length > 0) {
      this.morseInput = this.morseInput.slice(0, -1)
    }
  }

  // 清除所有输入
  private clearAll() {
    this.morseInput = ''
  }

  // 获取输入/输出框的高度
  private getBoxHeight(): number | string {
    return '25%'
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
    RelativeContainer() {
      // 输入框
      if (this.isTextToMorse) {
        TextArea({ text: this.textInput, placeholder: '在此输入文本，如: Hello World' })
          .layoutWeight(1)
          .fontSize(this.boxFontSize)
          .fontColor(Color.White)
          .placeholderColor(Color.White)
          .caretColor(Color.White)
          .margin(12)
          .maxLines(6)
          .onChange((v: string) => { this.textInput = v })
          .id('text_input_area')
      } else {
        TextArea({ text: this.morseInput, placeholder: '在此输入电码，如: ··· --- ···' })
          .layoutWeight(1)
          .fontSize(this.boxFontSize)
          .fontColor(Color.White)
          .placeholderColor(Color.White)
          .caretColor(Color.White)
          .margin(12)
          .maxLines(6)
          .onChange((v: string) => { this.morseInput = v })
          .id('morse_input_area')
      }

      // 清除按钮（右下角浮动）
      if ((this.isTextToMorse && this.textInput.length > 0) || (!this.isTextToMorse && this.morseInput.length > 0)) {
        Button() {
          Image($rawfile('ic_clear.svg'))
            .width(20)
            .height(20)
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .borderRadius(18)
        .alignRules({
          bottom: { anchor: this.isTextToMorse ? 'text_input_area' : 'morse_input_area', align: VerticalAlign.Bottom },
          right: { anchor: this.isTextToMorse ? 'text_input_area' : 'morse_input_area', align: HorizontalAlign.End }
        })
        .margin({ right: -4, bottom: 8 })
        .onClick(() => {
          if (this.isTextToMorse) {
            this.textInput = ''
          } else {
            this.morseInput = ''
          }
          // 清除输入后，输出也会自动更新为空
        })
        .zIndex(1)
      }
    }
    .height(this.getBoxHeight())
    .backgroundColor('#1A1A1A')
    .borderRadius(12)
    .margin({ left: 12, right: 12 })
    .border({ width: 1, color: '#333333' })
  }

  @Builder
  private OutputArea() {
    RelativeContainer() {
      // 输出框
      TextArea({ text: this.getOutput().length > 0 ? this.getOutput() : 
        (this.isTextToMorse ? '电码将在此显示' : '文本将在此显示，中文电码基于拼音转换') })
        .layoutWeight(1)
        .fontSize(this.boxFontSize)
        .margin(12)
        .backgroundColor(Color.Transparent)
        .fontColor('#FFFFFF')
        .fontFamily(this.isTextToMorse ? 'monospace' : '')
        .enabled(false)
        .maxLines(6)
        .id('output_area')

      // 复制按钮（右下角浮动，仅当有输出时显示）
      if (this.getOutput().length > 0) {
        Button() {
          Image($rawfile('ic_copy.svg'))
            .width(20)
            .height(20)
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .borderRadius(18)
        .alignRules({
          bottom: { anchor: 'output_area', align: VerticalAlign.Bottom },
          right: { anchor: 'output_area', align: HorizontalAlign.End }
        })
        .margin({ right: -4, bottom: 8 })
        .onClick(() => {
          // 复制到剪贴板
          promptAction.showToast({
            message: '已复制到剪贴板',
            duration: 1500,
            bottom: '80%'
          })
        })
        .zIndex(1)
      }
    }
    .height(this.getBoxHeight())
    .backgroundColor('#1A1A1A')
    .borderRadius(12)
    .margin({ left: 12, right: 12, bottom: 12 })
    .border({ width: 1, color: '#333333' })
  }

  @Builder
  private BottomKeys() {
    Column() {
      // 小按钮行
      Row() {
        // 斜杠按钮 (第一个) - 单词/句子分隔符
        Button() {
          Text('/')
            .fontSize(18)
            .fontColor('#FFD700')
            .fontWeight(FontWeight.Bold)
        }
        .height(40)
        .backgroundColor('#1A1A1A')
        .borderRadius(0)
        .border({ width: 1, color: '#333333' })
        .onClick(() => this.addSlash())
        .layoutWeight(1)

        Blank().width(8)

        // 空格按钮 (第二个)
        Button() {
          Text('⎵')
            .fontSize(16)
            .fontColor('#FFD700')
            .fontWeight(FontWeight.Bold)
        }
        .height(40)
        .backgroundColor('#1A1A1A')
        .borderRadius(0)
        .border({ width: 1, color: '#333333' })
        .onClick(() => this.addSpace())
        .layoutWeight(1)

        Blank().width(8)

        // 删除按钮 (第三个)
        Button() {
          Text('⌫')
            .fontSize(16)
            .fontColor('#FFD700')
            .fontWeight(FontWeight.Bold)
        }
        .height(40)
        .backgroundColor('#1A1A1A')
        .borderRadius(0)
        .border({ width: 1, color: '#333333' })
        .onClick(() => this.deleteLast())
        .layoutWeight(1)
      }
      .padding({ left: 20, right: 20 })

      Blank().height(12)

      // 主要的点和划按钮
      Row() {
        Button() {
          Circle({ width: 20, height: 20 })
            .fill('#FFD700')
        }
        .height(80)
        .backgroundColor('#1A1A1A')
        .borderRadius(this.pillRadius)
        .border({ width: 1, color: '#333333' })
        .onClick(() => this.addDot())
        .layoutWeight(1)

        Blank().width(20)

        Button() {
          Rect({ width: 40, height: 12 })
            .fill('#FFD700')
        }
        .height(80)
        .backgroundColor('#1A1A1A')
        .borderRadius(this.pillRadius)
        .border({ width: 1, color: '#333333' })
        .onClick(() => this.addDash())
        .layoutWeight(1)
      }
      .padding({ left: 20, right: 20, bottom: 60 })
    }
  }

  build() {
    Column() {
      this.TitleBar()
      
      // 内容区域 - 响应式宽度，最大480vp
      Column() {
        this.ModeToggle()
        this.InputArea()
        Blank().height(12)
        this.OutputArea()
        
        // 在电码→文本模式下显示底部按钮
        if (!this.isTextToMorse) {
          Blank().layoutWeight(1)
          this.BottomKeys()
        }
      }
      .width('100%')
      .constraintSize({ maxWidth: 480 })
      .padding({ left: 20, right: 20 })
      .layoutWeight(1)
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
