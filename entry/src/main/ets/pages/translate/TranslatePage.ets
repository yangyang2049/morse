import { MorseCodeData } from '../../models/MorseCode'
import { PinyinService } from '../../services/PinyinService'
import { promptAction } from '@kit.ArkUI'
import { resourceManager } from '@kit.LocalizationKit'
import { pasteboard } from '@kit.BasicServicesKit'
import { AudioService } from '../../services/AudioService'
import { flashlightService } from '../../services/FlashlightService'
import { common, Context } from '@kit.AbilityKit'
import preferences from '@ohos.data.preferences'
import { LocalizationHelper } from '../../utils/LocalizationHelper'

@Component
export struct TranslatePage {
  @State isTextToMorse: boolean = true
  @State textInput: string = ''
  @State morseInput: string = ''
  private readonly boxFontSize: number = 16
  private readonly pillRadius: number = 20
  @State currentLanguage: string = LocalizationHelper.DEFAULT_LANGUAGE
  // 资源管理器
  private resourceMgr: resourceManager.ResourceManager | null = null
  // 音频服务
  private audioService: AudioService = AudioService.getInstance()
  @State isPlaying: boolean = false
  // 手电筒服务
  @State flashlightInitialized: boolean = false
  @State isPlayingFlashlight: boolean = false
  @State useSingleButton: boolean = false
  @StorageLink('practice_settings_version') @Watch('onPracticeSettingsVersionChanged') practiceSettingsVersion: number = 0

  private pressStartTime: number = 0
  private longPressThreshold: number = 300
  private longPressTimer: number | null = null
  private practiceStore: preferences.Preferences | null = null

  async aboutToAppear(): Promise<void> {
    // 初始化资源管理器
    try {
      this.resourceMgr = getContext(this).resourceManager
    } catch (error) {
      console.error('[TranslatePage] Failed to get resource manager:', error)
    }

    // 获取当前系统语言
    this.currentLanguage = this.getCurrentLanguage()

    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()
    if (hostContext) {
      try {
        await PinyinService.load(hostContext)
      } catch (error) {
        console.error('[TranslatePage] Failed to load pinyin dictionary:', error)
      }

      try {
        await this.audioService.init(hostContext)
      } catch (error) {
        console.error('[TranslatePage] Failed to init audio service:', error)
      }

      // 从 practice_settings 读取单/双键与长按阈值，与课程页、练习页一致（改一处改全局）
      try {
        const context = hostContext as Context
        this.practiceStore = await preferences.getPreferences(context, 'practice_settings')
        await this.loadButtonModePreference(this.practiceStore)
        await this.loadLongPressThresholdPreference(this.practiceStore)
      } catch (error) {
        console.error('[TranslatePage] Failed to load practice_settings:', error)
      }
    }
  }

  onPageShow(): void {
    if (this.practiceStore) {
      this.loadButtonModePreference(this.practiceStore)
      this.loadLongPressThresholdPreference(this.practiceStore)
    }
  }

  onPracticeSettingsVersionChanged(): void {
    if (this.practiceStore) {
      this.reloadPracticeSettingsFromStore()
    }
  }

  private reloadPracticeSettingsFromStore(): void {
    this.loadButtonModePreference(this.practiceStore)
    this.loadLongPressThresholdPreference(this.practiceStore)
  }

  private async loadButtonModePreference(store: preferences.Preferences | null): Promise<void> {
    try {
      if (store) {
        const hasSetPreference = await store.get('has_set_button_mode', false) as boolean
        if (hasSetPreference) {
          this.useSingleButton = await store.get('use_single_button', false) as boolean
        } else {
          this.useSingleButton = false
        }
      }
    } catch (error) {
      console.error('[TranslatePage] Failed to load button mode preference:', error)
    }
  }

  private async loadLongPressThresholdPreference(store: preferences.Preferences | null): Promise<void> {
    try {
      if (store) {
        this.longPressThreshold = await store.get('long_press_threshold', 300) as number
      }
    } catch (error) {
      console.error('[TranslatePage] Failed to load long press threshold:', error)
    }
  }

  aboutToDisappear() {
    // 停止音频播放
    this.audioService.stopAudio()

    // 停止手电筒播放
    if (this.isPlayingFlashlight) {
      flashlightService.stopPlaying()
      this.isPlayingFlashlight = false
    }
  }

  // 获取当前应用语言（与冷启动 /「我」页一致）
  private getCurrentLanguage(): string {
    return LocalizationHelper.getCurrentLanguage()
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

  private handleSingleButtonPress(): void {
    this.pressStartTime = Date.now()
    this.longPressTimer = setTimeout(() => {
      this.handleLongPress()
    }, this.longPressThreshold)
  }

  private async handleSingleButtonRelease(): Promise<void> {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer)
      this.longPressTimer = null
    }
    const pressDuration = Date.now() - this.pressStartTime
    if (pressDuration < this.longPressThreshold) {
      this.addDot()
      try {
        await this.audioService.playDit()
      } catch (error) {
        console.error('[TranslatePage] Failed to play dit:', error)
      }
    }
  }

  private async handleLongPress(): Promise<void> {
    this.addDash()
    try {
      await this.audioService.playDah()
    } catch (error) {
      console.error('[TranslatePage] Failed to play dah:', error)
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

  // 播放摩尔斯码手电筒
  private async playMorseFlashlight(): Promise<void> {
    // 如果正在播放，则停止
    if (this.isPlayingFlashlight) {
      flashlightService.stopPlaying()
      this.isPlayingFlashlight = false
      return
    }

    // 如果未初始化，先初始化（这里会请求权限）
    if (!this.flashlightInitialized) {
      try {
        console.info('[TranslatePage] Initializing flashlight service on first use...')
        const uiContext = this.getUIContext()
        const hostContext = uiContext.getHostContext()

        if (!hostContext) {
          throw new Error('Failed to get host context')
        }

        await flashlightService.init(hostContext as common.BaseContext)
        this.flashlightInitialized = true
        console.info('[TranslatePage] Flashlight service initialized successfully')
      } catch (error) {
        console.error('[TranslatePage] Failed to init flashlight service:', error)
        this.flashlightInitialized = false

        try {
          promptAction.showToast({
            message: this.currentLanguage.startsWith('zh') ?
              '手电筒初始化失败' :
              'Failed to initialize flashlight',
            duration: 2000,
            bottom: '80%'
          })
        } catch (toastError) {
          console.error('[TranslatePage] Failed to show toast:', toastError)
        }
        return
      }
    }

    let contentToPlay = ''
    if (this.isTextToMorse) {
      contentToPlay = MorseCodeData.textToMorseForPlay(this.textInput)
    } else {
      contentToPlay = this.morseInput
    }

    if (contentToPlay.length === 0) {
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
      this.isPlayingFlashlight = true
      await flashlightService.playMorseCode(contentToPlay)
    } catch (error) {
      console.error('[TranslatePage] Failed to play morse flashlight:', error)
      try {
        promptAction.showToast({
          message: this.currentLanguage.startsWith('zh') ? '手电筒播放失败' : 'Flashlight playback failed',
          duration: 2000,
          bottom: '80%'
        })
      } catch (toastError) {
        console.error('[TranslatePage] Failed to show toast:', toastError)
      }
    } finally {
      this.isPlayingFlashlight = false
    }
  }

  // 播放SOS信号（保留但未在UI中使用）
  private async playSOS(): Promise<void> {
    if (this.isPlayingFlashlight) {
      flashlightService.stopPlaying()
      this.isPlayingFlashlight = false
      return
    }

    // 如果未初始化，先初始化（这里会请求权限）
    if (!this.flashlightInitialized) {
      try {
        console.info('[TranslatePage] Initializing flashlight service for SOS...')
        const uiContext = this.getUIContext()
        const hostContext = uiContext.getHostContext()

        if (!hostContext) {
          throw new Error('Failed to get host context')
        }

        await flashlightService.init(hostContext as common.BaseContext)
        this.flashlightInitialized = true
        console.info('[TranslatePage] Flashlight service initialized successfully')
      } catch (error) {
        console.error('[TranslatePage] Failed to init flashlight service:', error)
        this.flashlightInitialized = false

        try {
          promptAction.showToast({
            message: this.currentLanguage.startsWith('zh') ?
              '手电筒初始化失败' :
              'Failed to initialize flashlight',
            duration: 2000,
            bottom: '80%'
          })
        } catch (toastError) {
          console.error('[TranslatePage] Failed to show toast:', toastError)
        }
        return
      }
    }

    try {
      this.isPlayingFlashlight = true
      await flashlightService.playSOS()
      try {
        promptAction.showToast({
          message: 'SOS',
          duration: 1500,
          bottom: '80%'
        })
      } catch (toastError) {
        console.error('[TranslatePage] Failed to show toast:', toastError)
      }
    } catch (error) {
      console.error('[TranslatePage] Failed to play SOS:', error)
    } finally {
      this.isPlayingFlashlight = false
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
        .backgroundColor(this.isTextToMorse ? '#FFD700' : 'rgba(255, 255, 255, 0.08)')
        .fontColor(this.isTextToMorse ? '#000000' : '#FFD700')
        .fontSize(14)
        .fontWeight(this.isTextToMorse ? FontWeight.Bold : FontWeight.Medium)
        .borderRadius(16)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .margin({ right: 8 })
        .border({ width: 0 })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)

      // 电码 → 文本
      Button($r('app.string.morse_to_text'))
        .onClick(() => { this.isTextToMorse = false })
        .backgroundColor(!this.isTextToMorse ? '#FFD700' : 'rgba(255, 255, 255, 0.08)')
        .fontColor(!this.isTextToMorse ? '#000000' : '#FFD700')
        .fontSize(14)
        .fontWeight(!this.isTextToMorse ? FontWeight.Bold : FontWeight.Medium)
        .borderRadius(16)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .border({ width: 0 })
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
          .margin({ right: -12, bottom: 8 })
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

            // 手电筒按钮
            Button() {
              Text(this.isPlayingFlashlight ? '⏸' : '🔦')
                .fontSize(20)
            }
            .width(36)
              .height(36)
              .backgroundColor(Color.Transparent)
              .borderRadius(18)
              .margin({ top: 4 })
              .onClick(() => {
                this.playMorseFlashlight()
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
            .margin({ top: 4 })
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
          .margin({ right: -12, top: 8 })
          .zIndex(1)
      }
    }
    .height(this.getBoxHeight())
      .backgroundColor('#1A1A1A')
      .borderRadius(12)
      .margin({ left: 12, right: 12, bottom: 12 })
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
          .borderRadius(8)
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
          .borderRadius(8)
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
          .borderRadius(8)
          .onClick(() => this.deleteLast())
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)
          .layoutWeight(1)
      }
      .padding({ left: 20, right: 20 })

      Blank().height(12)

      // 主要的点和划按钮：单按钮（短按点、长按划）或双按钮
      if (this.useSingleButton) {
        Row() {
          Column() {
            Circle({ width: 20, height: 20 })
              .fill('#444444')
          }
          .width('100%')
          .height(80)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#FFD700')
          .borderRadius(this.pillRadius)
          .onTouch((event) => {
            if (event.type === 0) {
              this.handleSingleButtonPress()
            } else if (event.type === 1) {
              this.handleSingleButtonRelease()
            }
          })
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)
          .layoutWeight(1)
        }
        .padding({ left: 20, right: 20 })
      } else {
        Row() {
          Button() {
            Circle({ width: 20, height: 20 })
              .fill('#444444')
          }
          .height(80)
            .backgroundColor('#FFD700')
            .borderRadius(this.pillRadius)
            .onClick(async () => {
              this.addDot()
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
              .fill('#444444')
          }
          .height(80)
            .backgroundColor('#FFD700')
            .borderRadius(this.pillRadius)
            .onClick(async () => {
              this.addDash()
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
        .padding({ left: 20, right: 20 })
      }
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
