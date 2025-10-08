import { MorseCodeData } from '../../models/MorseCode'
import { PinyinService } from '../../services/PinyinService'
import { promptAction } from '@kit.ArkUI'
import { resourceManager, i18n } from '@kit.LocalizationKit'
import { pasteboard } from '@kit.BasicServicesKit'
import { AudioService } from '../../services/AudioService'

@Component
export struct TranslatePage {
  @State isTextToMorse: boolean = true
  @State textInput: string = ''
  @State morseInput: string = ''
  private readonly boxFontSize: number = 16
  private readonly pillRadius: number = 20
  @State currentLanguage: string = 'zh-CN'
  // 资源管理器
  private resourceMgr: resourceManager.ResourceManager | null = null
  // 音频服务
  private audioService: AudioService = AudioService.getInstance()
  @State isPlaying: boolean = false

  async aboutToAppear(): Promise<void> {
    // 初始化资源管理器
    try {
      this.resourceMgr = getContext(this).resourceManager
    } catch (error) {
      console.error('[TranslatePage] Failed to get resource manager:', error)
    }

    // 获取当前系统语言
    this.currentLanguage = this.getCurrentLanguage()

    // System bar colors are set globally in EntryAbility
    // Preload pinyin dictionary for Chinese → pinyin conversion
    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()
    if (hostContext) {
      PinyinService.load(hostContext)

      // 初始化音频服务
      try {
        await this.audioService.init(hostContext)
      } catch (error) {
        console.error('[TranslatePage] Failed to init audio service:', error)
      }
    }
  }

  aboutToDisappear() {
    // 停止音频播放
    this.audioService.stopAudio()
  }

  // 获取当前系统语言
  private getCurrentLanguage(): string {
    try {
      const currentLocale = i18n.System.getSystemLocale()
      // 将系统locale转换为我们的语言代码格式
      if (currentLocale.startsWith('zh')) {
        return 'zh-CN'
      } else if (currentLocale.startsWith('en')) {
        return 'en-US'
      }
      return 'zh-CN' // 默认中文
    } catch (error) {
      console.error('[TranslatePage] Failed to get current language:', error)
      return 'zh-CN' // 默认中文
    }
  }

  // 获取系统资源字符串
  private async getStringResource(key: string): Promise<string> {
    try {
      if (this.resourceMgr) {
        // 使用资源ID获取字符串
        const resourceId = await this.resourceMgr.getStringByName(key)
        return resourceId
      }
      return key
    } catch (error) {
      console.error(`[TranslatePage] Failed to get string resource for key: ${key}`, error)
      return key
    }
  }


  private getOutput(): string {
    if (this.isTextToMorse) {
      return MorseCodeData.textToMorse(this.textInput, (char: string) => {
        // 显示中文字符不在拼音表中的提示
        const isChinese = this.currentLanguage.startsWith('zh')
        promptAction.showToast({
          message: isChinese ? `"${char}" 不在拼音表中` : `"${char}" not in pinyin table`,
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

  // 播放摩尔斯电码声音
  private async playMorseSound() {
    if (this.isPlaying) {
      // 如果正在播放，停止播放
      this.audioService.stopAudio()
      this.isPlaying = false
      return
    }

    let contentToPlay = ''

    if (this.isTextToMorse) {
      // 文本转摩尔斯：播放转换后的摩尔斯电码（使用标准点）
      contentToPlay = MorseCodeData.textToMorseForPlay(this.textInput)
    } else {
      // 摩尔斯转文本：播放输入的摩尔斯电码
      contentToPlay = this.morseInput
    }

    if (contentToPlay.length === 0) {
      // 没有内容可播放
      try {
        promptAction.showToast({
          message: this.currentLanguage.startsWith('zh') ? '没有内容可播放' : 'No content to play',
          duration: 1500,
          bottom: '80%'
        })
      } catch (error) {
        console.error('[TranslatePage] Failed to show toast:', error)
      }
      return
    }

    try {
      this.isPlaying = true
      await this.audioService.playMorseSequence(contentToPlay)
    } catch (error) {
      console.error('[TranslatePage] Failed to play morse sound:', error)
      try {
        promptAction.showToast({
          message: this.currentLanguage.startsWith('zh') ? '播放失败' : 'Playback failed',
          duration: 1500,
          bottom: '80%'
        })
      } catch (toastError) {
        console.error('[TranslatePage] Failed to show error toast:', toastError)
      }
    } finally {
      this.isPlaying = false
    }
  }

  // 获取输入/输出框的高度
  private getBoxHeight(): number | string {
    return '25%'
  }

  @Builder
  private TitleBar() {
    Row() {
      Text($r('app.string.translate'))
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
      Button($r('app.string.text_to_morse'))
        .onClick(() => { this.isTextToMorse = true })
        .backgroundColor(this.isTextToMorse ? '#FFD700' : '#1A1A1A')
        .fontColor(this.isTextToMorse ? '#000000' : '#B0B0B0')
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .margin({ right: 8 })
        .border({ width: 1, color: '#333333' })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)

      // 电码 → 文本
      Button($r('app.string.morse_to_text'))
        .onClick(() => { this.isTextToMorse = false })
        .backgroundColor(!this.isTextToMorse ? '#FFD700' : '#1A1A1A')
        .fontColor(!this.isTextToMorse ? '#000000' : '#B0B0B0')
        .borderRadius(16)
        .padding({ left: 14, right: 14 })
        .border({ width: 1, color: '#333333' })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)
    }
    .justifyContent(FlexAlign.Center)
      .padding(12)
  }

  @Builder
  private InputArea() {
    RelativeContainer() {
      // 输入框
      if (this.isTextToMorse) {
        TextArea({ text: this.textInput, placeholder: $r('app.string.input_text_placeholder') })
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
        TextArea({ text: this.morseInput, placeholder: $r('app.string.input_morse_placeholder') })
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
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)
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
      TextArea({
        text: this.getOutput().length > 0 ? this.getOutput() :
          (this.isTextToMorse ? $r('app.string.output_text_placeholder') : $r('app.string.output_morse_placeholder'))
      })
        .layoutWeight(1)
        .fontSize(this.boxFontSize)
        .margin(12)
        .backgroundColor(Color.Transparent)
        .fontColor('#FFFFFF')
        .enabled(false)
        .maxLines(6)
        .id('output_area')

      // 操作按钮区域（右下角浮动，仅当有输出时显示）
      if (this.getOutput().length > 0) {
        Column() {
          // 播放按钮（仅在文本转摩尔斯模式下显示）
          if (this.isTextToMorse) {
            Button() {
              Image($rawfile(this.isPlaying ? 'ic_pause.svg' : 'ic_play.svg'))
                .width(20)
                .height(20)
            }
            .width(36)
              .height(36)
              .backgroundColor(Color.Transparent)
              .borderRadius(18)
              .onClick(() => {
                this.playMorseSound()
              })
              .hoverEffect(HoverEffect.Scale)
              .focusable(true)
          }

          // 复制按钮
          Button() {
            Image($rawfile('ic_copy.svg'))
              .width(20)
              .height(20)
          }
          .width(36)
            .height(36)
            .backgroundColor(Color.Transparent)
            .borderRadius(18)
            .onClick(() => {
              // 复制输出内容到剪贴板
              const outputText = this.getOutput()
              const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, outputText)
              const systemPasteboard = pasteboard.getSystemPasteboard()
              systemPasteboard.setData(pasteData)

              promptAction.showToast({
                message: $r('app.string.copied'),
                duration: 1500,
                bottom: '80%'
              })
            })
            .hoverEffect(HoverEffect.Scale)
            .focusable(true)
        }
        .alignRules({
          top: { anchor: 'output_area', align: VerticalAlign.Top },
          right: { anchor: 'output_area', align: HorizontalAlign.End }
        })
          .margin({ right: -4, top: 8 })
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
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)
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
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)
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
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)
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
          .onClick(async () => {
            this.addDot()
            // 播放点音
            if (this.morseInput.length > 0) {
              try {
                await this.audioService.playDit()
              } catch (error) {
                console.error('[TranslatePage] Failed to play dit:', error)
              }
            }
          })
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)
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
          .onClick(async () => {
            this.addDash()
            // 播放划音
            if (this.morseInput.length > 0) {
              try {
                await this.audioService.playDah()
              } catch (error) {
                console.error('[TranslatePage] Failed to play dah:', error)
              }
            }
          })
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)
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
