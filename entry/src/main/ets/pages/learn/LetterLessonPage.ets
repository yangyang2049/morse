import { MorseCode, MorseCodeData } from '../../models/MorseCode'
import { router } from '@kit.ArkUI'
import { LetterLessonViewModel } from '../../viewmodel/LetterLessonViewModel'
import { LessonData } from '../../data/LessonData'
import { audioService } from '../../services/AudioService'
import { vibratorService } from '../../services/VibratorService'
import preferences from '@ohos.data.preferences'

@Entry
@Component
export struct LetterLessonPage {
  @State viewModel: LetterLessonViewModel = new LetterLessonViewModel()
  private readonly pillRadius: number = 20
  @State useSingleButton: boolean = false
  @State showButtonModeDialog: boolean = false
  @State vibrationEnabled: boolean = true
  private preferencesStore: preferences.Preferences | null = null
  private pressStartTime: number = 0
  private longPressThreshold: number = 300
  private longPressTimer: number | null = null

  async aboutToAppear() {
    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()

    // 从路由参数获取课程数据
    const params = router.getParams() as Record<string, Object>
    const lessonId = (params['lessonId'] as string) || ''
    const title = (params['title'] as string) || '练习'

    console.log(`[LetterLessonPage] Received lessonId: ${lessonId}, title: ${title}`)

    // 根据lessonId设置课程数据
    const codes = this.setupLessonData(lessonId)

    // 初始化ViewModel
    if (hostContext) {
      this.viewModel.init(hostContext, lessonId, title, codes)
    }

    // 初始化偏好设置存储并加载输入模式
    await this.initPreferences()
    await this.loadButtonModePreference()
    await this.loadLongPressThresholdPreference()
    await this.loadVibrationPreference()
  }

  aboutToDisappear() {
    this.viewModel.destroy()
  }

  // 初始化偏好设置存储
  private async initPreferences(): Promise<void> {
    try {
      const context = getContext(this)
      this.preferencesStore = await preferences.getPreferences(context, 'practice_preferences')
      console.log('[LetterLessonPage] Preferences store initialized')
    } catch (error) {
      console.error('[LetterLessonPage] Failed to initialize preferences:', error)
    }
  }

  // 加载按钮模式偏好设置
  private async loadButtonModePreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        this.useSingleButton = await this.preferencesStore.get('use_single_button', false) as boolean
        console.log(`[LetterLessonPage] Loaded button mode preference: ${this.useSingleButton}`)
      }
    } catch (error) {
      console.error('[LetterLessonPage] Failed to load button mode preference:', error)
    }
  }

  // 保存按钮模式偏好设置
  private async saveButtonModePreference(useSingle: boolean): Promise<void> {
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.put('use_single_button', useSingle)
        await this.preferencesStore.put('has_set_button_mode', true)
        await this.preferencesStore.flush()
        this.useSingleButton = useSingle
        console.log(`[LetterLessonPage] Saved button mode preference: ${useSingle}`)
      }
    } catch (error) {
      console.error('[LetterLessonPage] Failed to save button mode preference:', error)
    }
  }

  // 加载长按时间偏好设置
  private async loadLongPressThresholdPreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        this.longPressThreshold = await this.preferencesStore.get('long_press_threshold', 300) as number
        console.log(`[LetterLessonPage] Loaded long press threshold: ${this.longPressThreshold}`)
      }
    } catch (error) {
      console.error('[LetterLessonPage] Failed to load long press threshold:', error)
    }
  }

  // 加载振动偏好设置
  private async loadVibrationPreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        this.vibrationEnabled = await this.preferencesStore.get('vibration_enabled', true) as boolean
        vibratorService.setEnabled(this.vibrationEnabled)
        console.log(`[LetterLessonPage] Loaded vibration preference: ${this.vibrationEnabled}`)
      }
    } catch (error) {
      console.error('[LetterLessonPage] Failed to load vibration preference:', error)
    }
  }

  // 保存振动偏好设置
  private async saveVibrationPreference(enabled: boolean): Promise<void> {
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.put('vibration_enabled', enabled)
        await this.preferencesStore.flush()
        this.vibrationEnabled = enabled
        vibratorService.setEnabled(enabled)
        console.log(`[LetterLessonPage] Saved vibration preference: ${enabled}`)
      }
    } catch (error) {
      console.error('[LetterLessonPage] Failed to save vibration preference:', error)
    }
  }

  // 单按钮模式处理
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
      this.viewModel.addDot()
      if (this.viewModel.soundEnabled) {
        await audioService.playDit()
      }
    }
  }

  private async handleLongPress(): Promise<void> {
    this.viewModel.addDash()
    if (this.viewModel.soundEnabled) {
      await audioService.playDah()
    }
  }

  // 判断是否为单词课程
  private isWordLesson(): boolean {
    const lessonId = this.viewModel.lessonId
    // lessonId 可能是字符串ID（如 'word_lesson_0'）或数字字符串（如 '19'）
    if (lessonId.startsWith('word_lesson_')) {
      return true
    }
    // 检查数字编号：单词课程编号为 19-21
    const lessonNumber = parseInt(lessonId) || 0
    return lessonNumber >= 19 && lessonNumber <= 21
  }

  private setupLessonData(lessonId: string): MorseCode[] {
    console.log(`[LetterLessonPage] setupLessonData: lessonId=${lessonId}`)

    const lessonNumber = parseInt(lessonId) || 0

    // 根据课程编号确定课程类型和内容
    if (lessonNumber >= 3 && lessonNumber <= 11) {
      // 字母课程 (3-11)
      const lessonIndex = lessonNumber - 3
      const alphabetGroups = LessonData.getAlphabetGroups()
      if (lessonIndex < alphabetGroups.length) {
        const targetLetters = alphabetGroups[lessonIndex]
        return MorseCodeData.englishAlphabet.filter(code =>
          targetLetters.includes(code.character)
        )
      } else {
        return MorseCodeData.englishAlphabet.slice(0, 3)
      }
    } else if (lessonNumber >= 12 && lessonNumber <= 15) {
      // 数字课程 (12-15)
      const lessonIndex = lessonNumber - 12
      const numberGroups = LessonData.getNumberGroups()
      if (lessonIndex < numberGroups.length) {
        const targetNumbers = numberGroups[lessonIndex]
        return MorseCodeData.numbers.filter(code =>
          targetNumbers.includes(code.character)
        )
      } else {
        return MorseCodeData.numbers.slice(0, 3)
      }
    } else if (lessonNumber >= 16 && lessonNumber <= 18) {
      // 符号课程 (16-18)
      const lessonIndex = lessonNumber - 16
      const punctuationGroups = LessonData.getPunctuationGroups()
      if (lessonIndex < punctuationGroups.length) {
        const targetPunctuation = punctuationGroups[lessonIndex]
        return MorseCodeData.punctuation.filter(code =>
          targetPunctuation.includes(code.character)
        )
      } else {
        return MorseCodeData.punctuation.slice(0, 3)
      }
    } else if (lessonNumber >= 19 && lessonNumber <= 21) {
      // 单词课程 (19-21)
      const lessonIndex = lessonNumber - 19
      const wordGroups = LessonData.getWordGroups()
      if (lessonIndex < wordGroups.length) {
        const targetWords = wordGroups[lessonIndex]
        // 为每个单词预计算摩斯电码（使用标准点/划表示）
        return targetWords.map(word => new MorseCode(
          word,
          // textToMorse 输出包含“·”，转换为标准“.”以与其他课程保持一致
          MorseCodeData.textToMorse(word).replace(/·/g, '.'),
          ''
        ))
      } else {
        // 默认单词集
        const fallback = ['THE', 'AND', 'FOR']
        return fallback.map(word => new MorseCode(
          word,
          MorseCodeData.textToMorse(word).replace(/·/g, '.'),
          ''
        ))
      }
    } else {
      // 默认返回字母课程
      return MorseCodeData.englishAlphabet.slice(0, 3)
    }
  }


  @Builder
  private TitleBar() {
    Column() {
      Row() {
        Button() {
          Image($rawfile('ic_back.svg'))
            .width(20)
            .height(20)
            .fillColor(Color.White)
        }
        .width(48)
          .height(48)
          .backgroundColor(Color.Transparent)
          .borderRadius(24)
          .onClick(() => {
            router.back()
          })
          .onHover((isHovered: boolean) => {
            // 悬浮时显示视觉反馈
          })
          .onFocus(() => {
            // 获得焦点时的视觉反馈
          })
          .onBlur(() => {
            // 失去焦点时的视觉反馈
          })
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)

        Blank().width(20)

        Scroll() {
          Row() {
            ForEach(this.viewModel.codes, (code: MorseCode, index: number) => {
              Text(code.character)
                .fontSize(this.isWordLesson() ? 12 : 18)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.viewModel.getLetterStatusColor(index))
                .margin({ right: 8 })
            })
          }
          .justifyContent(FlexAlign.Center)
        }
        .layoutWeight(1)
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)

        Blank().width(20)

        Button() {
          Image($rawfile('ic_settings.svg'))
            .width(22).height(22)
        }
        .backgroundColor(Color.Transparent)
          .borderRadius(24)
          .onClick(() => {
            this.viewModel.showSettingsDialog = true
          })
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)
      }
      .height(56)
        .padding({ left: 16, right: 16 })
    }
    .width('100%')
      .backgroundColor(Color.Black)
  }

  @Builder
  private ProgressCircle() {
    Stack({ alignContent: Alignment.Center }) {
      Circle({ width: 220, height: 220 })
        .fill(Color.Transparent)
        .strokeWidth(8)
        .stroke('#333333')

      Circle({ width: 220, height: 220 })
        .fill(Color.Transparent)
        .strokeWidth(8)
        .stroke(this.viewModel.getProgressColor())
        .strokeDashArray([this.viewModel.getProgressVisualLength(), this.viewModel.getCircumference() - this.viewModel.getProgressVisualLength()])
        .strokeDashOffset(this.viewModel.getCircumference() / 4)
        .strokeLineCap(LineCapStyle.Round)
        .opacity(this.viewModel.progressVisual > 0 ? 1 : 0)

      Circle({ width: 200, height: 200 })
        .fill(this.viewModel.getProgressColor())

      Text(this.viewModel.codes[this.viewModel.currentIndex]?.character || '')
        .fontSize(this.isWordLesson() ? 20 : 80)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .textAlign(TextAlign.Center)
        .width('100%')
    }
  }

  @Builder
  private MorseDisplay() {
    Column() {
      if (this.viewModel.shouldShowHint(this.viewModel.currentIndex)) {
        // 用图形化方式显示摩尔斯码
        // 用图形化方式显示摩尔斯码
        Row() {
          ForEach((this.viewModel.codes[this.viewModel.currentIndex]?.morse || '').split(''), (char: string) => {
            if (char === '.') {
              Circle({ width: this.isWordLesson() ? 6.4 : 8, height: this.isWordLesson() ? 6.4 : 8 })
                .fill(Color.White)
                .margin({ right: this.isWordLesson() ? 6.4 : 8 })
            } else if (char === '-') {
              Rect({ width: this.isWordLesson() ? 12.8 : 16, height: this.isWordLesson() ? 3.2 : 4 })
                .fill(Color.White)
                .margin({ right: this.isWordLesson() ? 6.4 : 8 })
            } else if (char === ' ') {
              // 字母间空格 - 单词课程中显示
              if (this.isWordLesson()) {
                Blank().width(3.2).height(1)
              }
            }
          })
        }
        .justifyContent(FlexAlign.Center)
      } else {
        Image($rawfile('ic_eye.svg'))
          .width(28)
          .height(28)
          .fillColor(Color.White)
      }
    }
    .height(80)
      .width('95%')
      .margin({ left: 24, right: 24 })
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor('#1A1A1A')
      .borderRadius(this.pillRadius)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        // 点击提示框本身进行显隐切换
        this.viewModel.showMorseCode = !this.viewModel.showMorseCode
      })
      .hoverEffect(HoverEffect.Scale)
      .focusable(true)
  }


  @Builder
  private InputDisplay() {
    Column() {
      if (this.viewModel.userInput.trim().length > 0) {
        // 用图形化方式显示用户输入
        // 用图形化方式显示用户输入
        Row() {
          ForEach(this.viewModel.userInput.split(''), (char: string) => {
            if (char === '.') {
              Circle({ width: this.isWordLesson() ? 6.4 : 8, height: this.isWordLesson() ? 6.4 : 8 })
                .fill(
                  this.viewModel.showResult && this.viewModel.isCorrect ? Color.Green :
                    this.viewModel.showResult && !this.viewModel.isCorrect ? Color.Red : '#FFD700'
                )
                .margin({ right: this.isWordLesson() ? 6.4 : 8 })
            } else if (char === '-') {
              Rect({ width: this.isWordLesson() ? 12.8 : 16, height: this.isWordLesson() ? 3.2 : 4 })
                .fill(
                  this.viewModel.showResult && this.viewModel.isCorrect ? Color.Green :
                    this.viewModel.showResult && !this.viewModel.isCorrect ? Color.Red : '#FFD700'
                )
                .margin({ right: this.isWordLesson() ? 6.4 : 8 })
            } else if (char === ' ') {
              // 字母间空格
              if (this.isWordLesson()) {
                Blank().width(3.2).height(1)
              }
            }
          })
        }
        .justifyContent(FlexAlign.Center)
      }
    }
    .height(60)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private BottomKeys() {
    if (this.useSingleButton) {
      // 单按钮模式：一个按钮，短按输入点，长按输入划
      Row() {
        Blank().layoutWeight(1)

        Button() {
          Text('·')
            .fontSize(24)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold)
        }
        .height(120)
          .width(120)
          .backgroundColor('#FFD700')
          .borderRadius(60)
          .onTouch((event) => {
            if (event.type === TouchType.Down) {
              this.handleSingleButtonPress()
            } else if (event.type === TouchType.Up) {
              this.handleSingleButtonRelease()
            }
          })
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)

        Blank().layoutWeight(1)
      }
      .width('100%')
        .padding({ left: 20, right: 20, bottom: 60 })
    } else {
      // 双按钮模式
      Row() {
        if (this.isWordLesson()) {
          // 单词课程：三个按钮（点、空格、划）
          Button() {
            Circle({ width: 20, height: 20 })
              .fill('#FFD700')
          }
          .height(80)
            .backgroundColor('#1A1A1A')
            .borderRadius(this.pillRadius)
            .border({ width: 1, color: '#333333' })
            .onClick(async () => {
              this.viewModel.addDot()
              if (this.viewModel.soundEnabled) {
                await audioService.playDit()
              }
            })
            .hoverEffect(HoverEffect.Scale)
            .focusable(true)
            .layoutWeight(1)

          Blank().width(8)

          // 短空格按钮
          Button() {
            Text('⎵')
              .fontSize(16)
              .fontColor('#FFD700')
              .fontWeight(FontWeight.Bold)
          }
          .height(80)
            .width(60)
            .backgroundColor('#1A1A1A')
            .borderRadius(12)
            .border({ width: 1, color: '#333333' })
            .onClick(async () => {
              this.viewModel.addSpace()
              if (this.viewModel.soundEnabled) {
                await audioService.playSpace()
              }
            })
            .hoverEffect(HoverEffect.Scale)
            .focusable(true)

          Blank().width(8)

          Button() {
            Rect({ width: 40, height: 12 })
              .fill('#FFD700')
          }
          .height(80)
            .backgroundColor('#1A1A1A')
            .borderRadius(this.pillRadius)
            .border({ width: 1, color: '#333333' })
            .onClick(async () => {
              this.viewModel.addDash()
              if (this.viewModel.soundEnabled) {
                await audioService.playDah()
              }
            })
            .hoverEffect(HoverEffect.Scale)
            .focusable(true)
            .layoutWeight(1)
        } else {
          // 其他课程：两个按钮（点、划），平均分配宽度
          Button() {
            Circle({ width: 20, height: 20 })
              .fill('#FFD700')
          }
          .height(80)
            .backgroundColor('#1A1A1A')
            .borderRadius(this.pillRadius)
            .border({ width: 1, color: '#333333' })
            .onClick(async () => {
              this.viewModel.addDot()
              if (this.viewModel.soundEnabled) {
                await audioService.playDit()
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
              this.viewModel.addDash()
              if (this.viewModel.soundEnabled) {
                await audioService.playDah()
              }
            })
            .hoverEffect(HoverEffect.Scale)
            .focusable(true)
            .layoutWeight(1)
        }
      }
      .padding({ left: 20, right: 20, bottom: 60 })
    }
  }

  @Builder
  private CompletionDialog() {
    // 全屏覆盖层，用于居中显示对话框
    Column() {
      Blank().layoutWeight(1)

      // 对话框内容
      Column() {
        Column()

        {
          Text('✓')
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }.width(80)
          .height(80)
          .backgroundColor(Color.Green)
          .borderRadius(40)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .shadow({ radius: 20, color: 'rgba(0, 255, 0, 0.3)', offsetX: 0, offsetY: 8 })

        Blank().height(24)

        Text($r('app.string.congratulations_completed'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)

        Blank().height(24)

        Row() {
          Column() {
            Text(`${this.viewModel.codes.length}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text($r('app.string.letters'))
              .fontSize(10)
              .fontColor('#B0B0B0')
          }
          .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.Center)

          Blank().width(1).height(40).backgroundColor('#333333')

          Column() {
            Text(`${this.viewModel.codes.length * this.viewModel.REQUIRED_PRACTICE_COUNT}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text($r('app.string.practice_count'))
              .fontSize(10)
              .fontColor('#B0B0B0')
          }
          .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.Center)
        }
        .width('100%')
          .padding(20)
          .backgroundColor('#1A1A1A')
          .border({ width: 1, color: '#333333' })
          .borderRadius(12)

        Blank().height(24)

        Row() {
          Button() {
            Text($r('app.string.back'))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .layoutWeight(1)
            .height(44)
            .backgroundColor(Color.Transparent)
            .border({ width: 2, color: Color.White })
            .borderRadius(8)
            .onClick(async () => {
              this.viewModel.closeCompletionDialog()
              // 课程已经在最后一个字母完成时标记了，这里不需要重复标记
              router.back()
            })
            .hoverEffect(HoverEffect.Scale)
            .focusable(true)

          Blank().width(12)

          Button() {
            Text($r('app.string.practice_again'))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .layoutWeight(1)
            .height(44)
            .backgroundColor(Color.Green)
            .borderRadius(8)
            .onClick(async () => {
              this.viewModel.closeCompletionDialog()
              // 课程已经在最后一个字母完成时标记了，这里不需要重复标记
              this.viewModel.restartLesson()
            })
            .hoverEffect(HoverEffect.Scale)
            .focusable(true)
        }
        .width('100%')
      }
      .width(360)
        .padding(20)
        .backgroundColor('#2A2A2A')
        .border({ width: 2, color: Color.Green })
        .borderRadius(16)
        .shadow({ radius: 24, color: 'rgba(0,0,0,0.4)', offsetX: 0, offsetY: 12 })
        .margin({ left: 20, right: 20 })

      Blank().layoutWeight(1)
    }
    .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private SettingsDialog() {

    Column() {
      Blank().layoutWeight(1)

      Column() {
        Text($r('app.string.settings'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)

        Blank().height(16)

        // 声音
        Row() {
          Text($r('app.string.sound'))
            .fontSize(16)
            .fontColor('#FFFFFF')
          Blank().layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.viewModel.soundEnabled })
            .selectedColor('#FFD700')
            .onChange((isOn: boolean) => {
              this.viewModel.soundEnabled = isOn
            })
        }
        .height(44)
          .padding({ left: 4, right: 4 })

        Blank().height(12)

        // 振动反馈
        Row() {
          Text($r('app.string.vibration'))
            .fontSize(16)
            .fontColor('#FFFFFF')
          Blank().layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.vibrationEnabled })
            .selectedColor('#FFD700')
            .onChange(async (isOn: boolean) => {
              await this.saveVibrationPreference(isOn)
            })
        }
        .height(44)
          .padding({ left: 4, right: 4 })

        Blank().height(12)

        // 输入模式设置
        Row() {
          Text($r('app.string.practice_input_mode'))
            .fontSize(16)
            .fontColor('#FFFFFF')
          Blank().layoutWeight(1)
          Text(this.useSingleButton ? $r('app.string.single_button_mode') : $r('app.string.dual_button_mode'))
            .fontSize(14)
            .fontColor('#B0B0B0')
            .margin({ right: 8 })
          Image($rawfile('ic_arrow_right.svg'))
            .width(16)
            .height(16)
            .fillColor('#666666')
        }
        .height(44)
          .padding({ left: 4, right: 4 })
          .onClick(() => {
            this.showButtonModeDialog = true
          })
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)

        Blank().height(12)

        // 练习次数 (3-5) - 单行布局，系统步进器不可用时使用 +/-
        Row() {
          Text($r('app.string.practice_count'))
            .fontSize(16)
            .fontColor('#FFFFFF')
          Blank().layoutWeight(1)

          Button() {
            Text('-').fontSize(18).fontColor(Color.White)
          }
          .height(36)
            .width(44)
            .backgroundColor('#333333')
            .borderRadius(8)
            .onClick(() => {
              const next = Math.max(3, Math.min(5, this.viewModel.REQUIRED_PRACTICE_COUNT - 1))
              this.viewModel.REQUIRED_PRACTICE_COUNT = next
              // 修正当前进度显示
              const count = this.viewModel.practiceCount.get(this.viewModel.currentIndex) || 0
              this.viewModel.progressVisual = Math.min(count / this.viewModel.REQUIRED_PRACTICE_COUNT, 1)
            })
            .hoverEffect(HoverEffect.Scale)
            .focusable(true)

          Blank().width(12)

          Text(`${this.viewModel.REQUIRED_PRACTICE_COUNT}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFD700')

          Blank().width(12)

          Button() {
            Text('+').fontSize(18).fontColor(Color.White)
          }
          .height(36)
            .width(44)
            .backgroundColor('#333333')
            .borderRadius(8)
            .onClick(() => {
              const next = Math.max(3, Math.min(5, this.viewModel.REQUIRED_PRACTICE_COUNT + 1))
              this.viewModel.REQUIRED_PRACTICE_COUNT = next
              const count = this.viewModel.practiceCount.get(this.viewModel.currentIndex) || 0
              this.viewModel.progressVisual = Math.min(count / this.viewModel.REQUIRED_PRACTICE_COUNT, 1)
            })
            .hoverEffect(HoverEffect.Scale)
            .focusable(true)
        }
        .height(44)
          .alignItems(VerticalAlign.Center)

        Blank().height(20)

        Button() {
          Text($r('app.string.close'))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Black)
        }
        .height(44)
          .width('100%')
          .backgroundColor('#FFD700')
          .borderRadius(8)
          .onClick(() => { this.viewModel.showSettingsDialog = false })
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)
      }
      .width(320)
        .padding(20)
        .backgroundColor('#2A2A2A')
        .border({ width: 1, color: '#333333' })
        .borderRadius(12)
        .shadow({ radius: 24, color: 'rgba(0,0,0,0.4)', offsetX: 0, offsetY: 12 })

      Blank().layoutWeight(1)
    }
    .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private ButtonModeSelectorDialog() {
    Column() {
      Row() {
        Text($r('app.string.select_practice_input_mode'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Blank()
        Button() {
          Image($rawfile('ic_close.svg'))
            .width(20)
            .height(20)
            .fillColor('#FFFFFF')
        }
        .width(32)
          .height(32)
          .backgroundColor('rgba(128, 128, 128, 0.2)')
          .borderRadius(16)
          .onClick(() => {
            this.showButtonModeDialog = false
          })
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)
      }
      .width('100%')
        .margin({ bottom: 20 })

      // 双按钮模式选项
      Row() {
        Column() {
          Text($r('app.string.dual_button_mode'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .margin({ bottom: 8 })
          Text($r('app.string.dual_button_mode_desc'))
            .fontSize(12)
            .fontColor('#999999')
        }
        .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

        if (!this.useSingleButton) {
          Circle()
            .width(16)
            .height(16)
            .fill(Color.Transparent)
            .stroke('#FFD700')
            .strokeWidth(2)
        }
      }
      .width('100%')
        .padding(16)
        .backgroundColor('#111111')
        .borderRadius(8)
        .margin({ bottom: 8 })
        .border({
          width: !this.useSingleButton ? 1 : 0.5,
          color: !this.useSingleButton ? '#FFD700' : '#222222',
          radius: 8
        })
        .onClick(() => {
          this.saveButtonModePreference(false)
          this.showButtonModeDialog = false
        })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)

      // 单按钮模式选项
      Row() {
        Column() {
          Text($r('app.string.single_button_mode'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .margin({ bottom: 8 })
          Text($r('app.string.single_button_mode_desc'))
            .fontSize(12)
            .fontColor('#999999')
        }
        .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

        if (this.useSingleButton) {
          Circle()
            .width(16)
            .height(16)
            .fill(Color.Transparent)
            .stroke('#FFD700')
            .strokeWidth(2)
        }
      }
      .width('100%')
        .padding(16)
        .backgroundColor('#111111')
        .borderRadius(8)
        .border({
          width: this.useSingleButton ? 1 : 0.5,
          color: this.useSingleButton ? '#FFD700' : '#222222',
          radius: 8
        })
        .onClick(() => {
          this.saveButtonModePreference(true)
          this.showButtonModeDialog = false
        })
        .hoverEffect(HoverEffect.Scale)
        .focusable(true)
    }
    .padding(20)
      .backgroundColor('#2A2A2A')
      .borderRadius(12)
      .width('90%')
      .constraintSize({ maxWidth: 400, maxHeight: '60%' })
  }

  @Builder
  private OverlayCover() {
    Stack() {
      // 半透明遮罩，阻止穿透点击
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          if (this.showButtonModeDialog) {
            this.showButtonModeDialog = false
          } else if (this.viewModel.showSettingsDialog) {
            this.viewModel.showSettingsDialog = false
          }
        })

      // 完成对话框（最底层）
      if (this.viewModel.showCompletionDialog) {
        this.CompletionDialog()
      }

      // 设置对话框（中间层）
      if (this.viewModel.showSettingsDialog) {
        this.SettingsDialog()
      }

      // 输入模式选择对话框（最上层，显示在设置对话框之上）
      if (this.showButtonModeDialog) {
        Column() {
          this.ButtonModeSelectorDialog()
        }
        .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .zIndex(100) // 确保显示在最上层
      }
    }
    .width('100%')
      .height('100%')
  }

  build() {
    Stack() {
      Column() {
        this.TitleBar()

        // 内容区域 - 响应式宽度，最大480vp
        Column() {
          Blank().height(20)

          Column() {
            this.ProgressCircle()
            Blank().height(60)
            this.MorseDisplay()
            Blank().height(20)
            this.InputDisplay()
          }
          .layoutWeight(1)
            .justifyContent(FlexAlign.Center)

          this.BottomKeys()
        }
        .width('100%')
          .constraintSize({ maxWidth: 480 })
          .padding({ left: 20, right: 20 })
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
        .height('100%')

      if (this.viewModel.showCompletionDialog || this.viewModel.showSettingsDialog || this.showButtonModeDialog) {
        this.OverlayCover()
      }
    }
    .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
