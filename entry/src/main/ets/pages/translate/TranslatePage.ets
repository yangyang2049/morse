import { MorseCodeData } from '../../models/MorseCode'
import { PinyinService } from '../../services/PinyinService'
import { promptAction } from '@kit.ArkUI'
import { i18nService } from '../../services/I18nService'
// 本地化字符串接口
interface LocalizedStrings {
  translate: string
  text_to_morse: string
  morse_to_text: string
  input_text_placeholder: string
  input_morse_placeholder: string
  output_text_placeholder: string
  output_morse_placeholder: string
  copied: string
}

@Component
export struct TranslatePage {
  @State isTextToMorse: boolean = true
  @State textInput: string = ''
  @State morseInput: string = ''
  private readonly boxFontSize: number = 16
  private readonly pillRadius: number = 20
  // 使用 StorageLink 监听语言变化
  @StorageLink('currentLanguage') currentLanguage: string = 'zh-CN'
  // 语言变化计数器，用于强制UI刷新
  @State langTick: number = 0
  // 缓存本地化字符串
  @State strings: LocalizedStrings = {
    translate: '',
    text_to_morse: '',
    morse_to_text: '',
    input_text_placeholder: '',
    input_morse_placeholder: '',
    output_text_placeholder: '',
    output_morse_placeholder: '',
    copied: ''
  }
  private languageChangeListener: ((lang: string) => void) | null = null

  aboutToAppear() {
    // System bar colors are set globally in EntryAbility
    // Preload pinyin dictionary for Chinese → pinyin conversion
    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()
    if (hostContext) {
      PinyinService.load(hostContext)
    }

    // 添加语言变化监听器
    this.languageChangeListener = (lang: string) => {
      console.log(`[TranslatePage] Language changed to: ${lang}`)
      // 更新缓存的本地化字符串
      this.strings = this.computeStrings()
      // 触发UI强制刷新
      this.langTick++
    }
    
    // 启动语言变化监听
    this.startLanguageWatcher()
    
    // 初始化本地化字符串
    this.strings = this.computeStrings()
  }

  aboutToDisappear() {
    // 清理语言变化监听器
    if (this.languageChangeListener) {
      this.languageChangeListener = null
    }
  }

  // 启动语言变化监听器
  private startLanguageWatcher(): void {
    let lastLanguage = this.currentLanguage
    const checkLanguageChange = () => {
      if (this.currentLanguage !== lastLanguage) {
        console.log(`[TranslatePage] Language changed from ${lastLanguage} to ${this.currentLanguage}`)
        lastLanguage = this.currentLanguage
        if (this.languageChangeListener) {
          this.languageChangeListener(this.currentLanguage)
        }
      }
      // 继续监听
      setTimeout(checkLanguageChange, 100)
    }
    checkLanguageChange()
  }

  // 计算本地化字符串
  private computeStrings(): LocalizedStrings {
    return {
      translate: i18nService.t('translate'),
      text_to_morse: i18nService.t('text_to_morse'),
      morse_to_text: i18nService.t('morse_to_text'),
      input_text_placeholder: i18nService.t('input_text_placeholder'),
      input_morse_placeholder: i18nService.t('input_morse_placeholder'),
      output_text_placeholder: i18nService.t('output_text_placeholder'),
      output_morse_placeholder: i18nService.t('output_morse_placeholder'),
      copied: i18nService.t('copied')
    }
  }


  private getOutput(): string {
    if (this.isTextToMorse) {
      return MorseCodeData.textToMorse(this.textInput, (char: string) => {
        // 显示中文字符不在拼音表中的提示
        promptAction.showToast({
          message: i18nService.isChinese() ? `"${char}" 不在拼音表中` : `"${char}" not in pinyin table`,
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

  // 获取输入/输出框的高度
  private getBoxHeight(): number | string {
    return '25%'
  }

  @Builder
  private TitleBar() {
    Row() {
      // 隐藏的langTick触发器
      Text(this.langTick.toString())
        .opacity(0)
        .width(0)
        .height(0)
      
      Text(this.strings.translate || i18nService.t('translate'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
    }
    .height(56)
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#000000')
  }

  @Builder
  private ModeToggle() {
    Row() {
      // 文本 → 电码
      Button(this.strings.text_to_morse || i18nService.t('text_to_morse'))
        .onClick(() => { this.isTextToMorse = true })
        .backgroundColor(this.isTextToMorse ? '#FFD700' : '#1A1A1A')
        .fontColor(this.isTextToMorse ? '#000000' : '#B0B0B0')
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .margin({ right: 8 })
        .border({ width: 1, color: '#333333' })

      // 电码 → 文本
      Button(this.strings.morse_to_text || i18nService.t('morse_to_text'))
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
        TextArea({ text: this.textInput, placeholder: this.strings.input_text_placeholder || i18nService.t('input_text_placeholder') })
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
        TextArea({ text: this.morseInput, placeholder: this.strings.input_morse_placeholder || i18nService.t('input_morse_placeholder') })
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
        (this.isTextToMorse ? (this.strings.output_text_placeholder || i18nService.t('output_text_placeholder')) : (this.strings.output_morse_placeholder || i18nService.t('output_morse_placeholder'))) })
        .layoutWeight(1)
        .fontSize(this.boxFontSize)
        .margin(12)
        .backgroundColor(Color.Transparent)
        .fontColor('#FFFFFF')
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
          promptAction.showToast({
            message: this.strings.copied || i18nService.t('copied'),
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
