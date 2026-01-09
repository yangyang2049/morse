import router from '@ohos.router'
import { MorseCodeData, MorseCode } from '../../models/MorseCode'
import { audioService } from '../../services/AudioService'
import { vibratorService } from '../../services/VibratorService'
import vibrator from '@ohos.vibrator'
import { BusinessError } from '@kit.BasicServicesKit'
import preferences from '@ohos.data.preferences'
import { Context } from '@kit.AbilityKit'
import { promptAction, ArcButton, ArcButtonOptions, ArcButtonPosition, ArcButtonStyleMode, ColorMetrics } from '@kit.ArkUI'
import { LocalizationHelper } from '../../utils/LocalizationHelper'
import { FavoritesStore } from '../../store/FavoritesStore'

type PracticeMode = 'text_to_code' | 'code_to_text'

@Entry
@Component
struct PracticeDetailPage {
  @State mode: PracticeMode = 'text_to_code'
  @State practiceChar: string = ''
  @State practiceAnswer: string = ''
  @State showAnswer: boolean = false
  @State useSingleButton: boolean = false
  @State longPressThreshold: number = 300
  @State candidateChars: string[] = []
  @State selectedChar: string = ''
  @State showMorseCode: boolean = true
  @State showCandidateGrid: boolean = true
  @State isCorrectFeedback: boolean = false
  @State showHint: boolean = false
  @State isContentVisible: boolean = true
  @State showGuideDialog: boolean = false
  @State vibrationEnabled: boolean = true
  
  private pressStartTime: number = 0
  private longPressTimer: number | null = null
  private autoCheckTimer: number | null = null
  private hintTimer: number | null = null
  private preferencesStore: preferences.Preferences | null = null
  private allCodes: MorseCode[] = []
  
  private nextQuestionTimer: number | null = null
  private selectCharTimers: number[] = []
  private checkAnswerTimers: number[] = []
  private isTransitioning: boolean = false

  async aboutToAppear() {
    // 初始化偏好设置存储
    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        this.preferencesStore = await preferences.getPreferences(context, 'practice_settings')
        await this.loadButtonModePreference()
        await this.loadLongPressThresholdPreference()
        await this.loadVibrationPreference()
      }
    } catch (error) {
      console.error('[PracticeDetailPage] Failed to initialize preferences:', error)
    }

    const params = router.getParams() as Record<string, Object>
    if (params) {
      this.mode = (params['mode'] as PracticeMode) || 'text_to_code'
    }

    // 加载所有代码
    this.allCodes = [
      ...MorseCodeData.englishAlphabet,
      ...MorseCodeData.numbers
    ]

    // 如果是代码转文本模式，先设置题目，然后生成候选字符
    if (this.mode === 'code_to_text') {
      if (this.allCodes.length > 0) {
        const randomIndex = Math.floor(Math.random() * this.allCodes.length)
        this.practiceChar = this.allCodes[randomIndex].character
        this.generateCandidates()
        this.showMorseCode = true
        this.showCandidateGrid = true
      }
      // 检查并显示 code to text 模式的 toast 提示
      await this.checkAndShowCodeToTextGuide()
    } else {
      this.nextQuestion()
      // 检查并显示 text to code 模式的引导对话框
      await this.checkAndShowTextToCodeGuide()
    }
  }

  aboutToDisappear() {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer)
      this.longPressTimer = null
    }
    if (this.autoCheckTimer) {
      clearTimeout(this.autoCheckTimer)
      this.autoCheckTimer = null
    }
    if (this.hintTimer) {
      clearTimeout(this.hintTimer)
      this.hintTimer = null
    }
    if (this.nextQuestionTimer) {
      clearTimeout(this.nextQuestionTimer)
      this.nextQuestionTimer = null
    }
    this.selectCharTimers.forEach(id => clearTimeout(id))
    this.selectCharTimers = []
    this.checkAnswerTimers.forEach(id => clearTimeout(id))
    this.checkAnswerTimers = []
  }

  private toggleHint(): void {
    this.showHint = true
    if (this.hintTimer) {
      clearTimeout(this.hintTimer)
    }
    this.hintTimer = setTimeout(() => {
      this.showHint = false
      this.hintTimer = null
    }, 2000)
  }

  // 加载按钮模式偏好
  private async loadButtonModePreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        const hasSetPreference = await this.preferencesStore.get('has_set_button_mode', false) as boolean
        if (hasSetPreference) {
          this.useSingleButton = await this.preferencesStore.get('use_single_button', false) as boolean
        } else {
          // 默认使用单键模式
          this.useSingleButton = true
        }
      }
    } catch (error) {
      console.error('[PracticeDetailPage] Failed to load button mode preference:', error)
    }
  }

  // 加载长按时间偏好
  private async loadLongPressThresholdPreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        this.longPressThreshold = await this.preferencesStore.get('long_press_threshold', 300) as number
      }
    } catch (error) {
      console.error('[PracticeDetailPage] Failed to load long press threshold:', error)
    }
  }

  // 加载震动偏好设置
  private async loadVibrationPreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        this.vibrationEnabled = await this.preferencesStore.get('vibration_enabled', true) as boolean
      }
    } catch (error) {
      console.error('[PracticeDetailPage] Failed to load vibration preference:', error)
    }
  }

  // 检查并显示 text to code 模式的引导对话框
  private async checkAndShowTextToCodeGuide(): Promise<void> {
    try {
      if (this.preferencesStore) {
        const hasShownGuide = await this.preferencesStore.get('has_shown_watch_practice_text_to_code_guide', false) as boolean
        if (!hasShownGuide) {
          // 延迟显示，确保页面已加载
          setTimeout(() => {
            this.showGuideDialog = true
          }, 500)
        }
      }
    } catch (error) {
      console.error('[PracticeDetailPage] Failed to check text to code guide:', error)
    }
  }

  // 保存 text to code 引导已显示的状态
  private async saveTextToCodeGuideShown(): Promise<void> {
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.put('has_shown_watch_practice_text_to_code_guide', true)
        await this.preferencesStore.flush()
        console.log('[PracticeDetailPage] Saved text to code guide shown status')
      }
    } catch (error) {
      console.error('[PracticeDetailPage] Failed to save text to code guide shown status:', error)
    }
  }

  // 检查并显示 code to text 模式的 toast 提示
  private async checkAndShowCodeToTextGuide(): Promise<void> {
    try {
      if (this.preferencesStore) {
        const hasShownGuide = await this.preferencesStore.get('has_shown_watch_practice_code_to_text_guide', false) as boolean
        if (!hasShownGuide) {
          // 延迟显示 toast，确保页面已加载
          setTimeout(() => {
            try {
              promptAction.showToast({
                message: LocalizationHelper.getString('watch_guide_text_practice_code_to_text'),
                duration: 3000,
                bottom: '45%'
              })
              // 保存已显示状态
              this.saveCodeToTextGuideShown()
            } catch (error) {
              console.error('[PracticeDetailPage] Failed to show code to text guide toast:', error)
            }
          }, 500)
        }
      }
    } catch (error) {
      console.error('[PracticeDetailPage] Failed to check code to text guide:', error)
    }
  }

  // 保存 code to text 引导已显示的状态
  private async saveCodeToTextGuideShown(): Promise<void> {
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.put('has_shown_watch_practice_code_to_text_guide', true)
        await this.preferencesStore.flush()
        console.log('[PracticeDetailPage] Saved code to text guide shown status')
      }
    } catch (error) {
      console.error('[PracticeDetailPage] Failed to save code to text guide shown status:', error)
    }
  }

  // 引导对话框 Builder
  @Builder
  private GuideDialog() {
    Column() {
      Text(LocalizationHelper.getString('watch_guide_title'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ bottom: 16 })

      Text(LocalizationHelper.getString('watch_guide_text_practice_text_to_code'))
        .fontSize(14)
        .fontColor('#CCCCCC')
        .textAlign(TextAlign.Center)
        .width('100%')
        .lineHeight(20)
        .margin({ bottom: 24 })

      Button(LocalizationHelper.getString('watch_guide_button_got_it'))
        .fontSize(16)
        .fontColor('#000000')
        .backgroundColor('#FFD700')
        .borderRadius(8)
        .width('100%')
        .height(44)
        .onClick(async () => {
          await this.saveTextToCodeGuideShown()
          this.showGuideDialog = false
        })
    }
    .padding(24)
    .backgroundColor('#2A2A2A')
    .borderRadius(12)
    .width('85%')
    .constraintSize({ maxWidth: 400 })
  }

  // 下一题
  private nextQuestion(): void {
    if (this.isTransitioning) return

    this.isCorrectFeedback = false
    this.showHint = false
    this.isContentVisible = false
    this.isTransitioning = true
    
    if (this.hintTimer) {
      clearTimeout(this.hintTimer)
      this.hintTimer = null
    }

    if (this.nextQuestionTimer) {
      clearTimeout(this.nextQuestionTimer)
    }

    this.nextQuestionTimer = setTimeout(() => {
      if (this.allCodes.length > 0) {
        const randomIndex = Math.floor(Math.random() * this.allCodes.length)
        this.practiceChar = this.allCodes[randomIndex].character
        
        if (this.mode === 'code_to_text') {
          this.selectedChar = ''
          this.generateCandidates()
          this.showMorseCode = true
          this.showCandidateGrid = true
        } else {
          this.practiceAnswer = ''
          this.showAnswer = false
        }
      }
      
      this.isContentVisible = true
      this.isTransitioning = false
      this.nextQuestionTimer = null
    }, 300)
  }

  // 生成候选字符（6个选项：1个正确答案 + 5个随机错误选项）
  private generateCandidates(): void {
    if (!this.practiceChar || this.allCodes.length === 0) {
      this.candidateChars = []
      return
    }

    const candidates: string[] = [this.practiceChar]
    const availableChars = this.allCodes.filter(code => code.character !== this.practiceChar)
    
    const count = Math.min(5, availableChars.length)
    for (let i = 0; i < count; i++) {
      const randomIndex = Math.floor(Math.random() * availableChars.length)
      candidates.push(availableChars[randomIndex].character)
      availableChars.splice(randomIndex, 1)
    }
    
    this.candidateChars = candidates.sort(() => Math.random() - 0.5)
  }

  // 获取正确答案
  private getCorrectMorse(): string {
    const code = this.allCodes.find(c => c.character === this.practiceChar)
    return code ? code.morse.replace(/\./g, '·') : ''
  }

  // 选择字符（代码转文本模式）
  private selectChar(char: string): void {
    if (this.selectedChar || this.isTransitioning) {
      return // 已经选择过了或正在过渡
    }
    
    this.selectedChar = char
    this.practiceAnswer = char
    
    const isCorrect = char === this.practiceChar
    
    // 清理之前的定时器
    this.selectCharTimers.forEach(id => clearTimeout(id))
    this.selectCharTimers = []
    
    if (isCorrect) {
      FavoritesStore.getInstance().tryRemoveFromMistakes(this.practiceChar)
      this.isCorrectFeedback = true
      // 正确：成功振动
      const t1 = setTimeout(() => {
        if (vibratorService.isVibrationEnabled()) {
          vibrator.vibrate(50, () => {})
        }
      }, 0)
      this.selectCharTimers.push(t1)

      const t2 = setTimeout(() => {
        if (vibratorService.isVibrationEnabled()) {
          vibrator.vibrate(50, () => {})
        }
      }, 100)
      this.selectCharTimers.push(t2)

      // 延迟后切换到下一题
      const t3 = setTimeout(() => {
        this.nextQuestion()
      }, 300)
      this.selectCharTimers.push(t3)
    } else {
      FavoritesStore.getInstance().addToMistakes(this.practiceChar)
      // 错误：错误振动
      if (vibratorService.isVibrationEnabled()) {
        vibrator.vibrate(250, () => {})
      }
      // 延迟后切换到下一题
      const t4 = setTimeout(() => {
        this.nextQuestion()
      }, 1500)
      this.selectCharTimers.push(t4)
    }
  }

  // 检查答案
  private checkAnswer(): void {
    if (this.mode === 'text_to_code') {
      const code = this.allCodes.find(c => c.character === this.practiceChar)
      if (!code) {
        return
      }

      const correctMorse = code.morse.replace(/\./g, '·')
      const isCorrect = this.practiceAnswer.trim() === correctMorse

      // 清理之前的定时器
      this.checkAnswerTimers.forEach(id => clearTimeout(id))
      this.checkAnswerTimers = []

      if (isCorrect) {
        FavoritesStore.getInstance().tryRemoveFromMistakes(this.practiceChar)
        // 正确：自动切换到下一题
        if (this.autoCheckTimer) {
          clearTimeout(this.autoCheckTimer)
          this.autoCheckTimer = null
        }
        this.isCorrectFeedback = true
        // 成功振动
        const t1 = setTimeout(() => {
          if (vibratorService.isVibrationEnabled()) {
          vibrator.vibrate(50, () => {})
        }
        }, 0)
        this.checkAnswerTimers.push(t1)

        const t2 = setTimeout(() => {
          if (vibratorService.isVibrationEnabled()) {
          vibrator.vibrate(50, () => {})
        }
        }, 100)
        this.checkAnswerTimers.push(t2)

        // 延迟后切换到下一题
        const t3 = setTimeout(() => {
          this.nextQuestion()
        }, 300)
        this.checkAnswerTimers.push(t3)
      } else {
        FavoritesStore.getInstance().addToMistakes(this.practiceChar)
        // 错误：显示toast，清除输入
        if (this.autoCheckTimer) {
          clearTimeout(this.autoCheckTimer)
          this.autoCheckTimer = null
        }
        // 错误振动
        if (vibratorService.isVibrationEnabled()) {
          vibrator.vibrate(250, () => {})
        }
        try {
          promptAction.showToast({
            message: LocalizationHelper.getString('watch_try_again'),
            duration: 1000,
            bottom: '45%'
          })
        } catch (error) {
          console.error('[PracticeDetailPage] Failed to show toast:', error)
        }
        // 清除输入，让用户重新输入
        const t4 = setTimeout(() => {
          this.practiceAnswer = ''
        }, 1500)
        this.checkAnswerTimers.push(t4)
      }
    }
  }

  // 单键模式：按下
  private handleSingleButtonPress(): void {
    this.pressStartTime = Date.now()
    this.longPressTimer = setTimeout(() => {
      this.handleLongPress()
    }, this.longPressThreshold)
  }

  // 单键模式：释放
  private async handleSingleButtonRelease(): Promise<void> {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer)
      this.longPressTimer = null
    }
    const pressDuration = Date.now() - this.pressStartTime
    if (pressDuration < this.longPressThreshold) {
      this.addDot()
      await audioService.playDit()
    }
  }

  // 长按处理
  private async handleLongPress(): Promise<void> {
    this.addDash()
    await audioService.playDah()
  }

  // 添加点
  private addDot(): void {
    if (this.mode === 'text_to_code' && !this.showAnswer) {
      this.practiceAnswer += '·'
      if (vibratorService.isVibrationEnabled()) {
        vibrator.vibrate(100, () => {})
      }
      this.startAutoCheck()
    }
  }

  // 添加划
  private addDash(): void {
    if (this.mode === 'text_to_code' && !this.showAnswer) {
      this.practiceAnswer += '-'
      if (vibratorService.isVibrationEnabled()) {
        vibrator.vibrate(300, () => {})
      }
      this.startAutoCheck()
    }
  }

  // 开始自动检查
  private startAutoCheck(): void {
    if (this.mode !== 'text_to_code' || this.showAnswer) {
      return
    }

    if (this.autoCheckTimer) {
      clearTimeout(this.autoCheckTimer)
      this.autoCheckTimer = null
    }

    // 获取正确答案长度
    const code = this.allCodes.find(c => c.character === this.practiceChar)
    const correctAnswerLength = code ? code.morse.length : 0
    const currentInputLength = this.practiceAnswer.length

    // 根据输入长度动态调整延迟
    let checkDelay: number
    if (currentInputLength >= correctAnswerLength && correctAnswerLength > 0) {
      checkDelay = 1000
    } else if (currentInputLength === 0) {
      return
    } else {
      checkDelay = 1500
    }

    this.autoCheckTimer = setTimeout(() => {
      this.autoCheckTimer = null
      if (this.practiceAnswer && this.practiceAnswer.trim().length > 0) {
        this.checkAnswer()
      }
    }, checkDelay)
  }

  // 删除最后一个字符
  private deleteLastChar(): void {
    if (this.practiceAnswer.length > 0) {
      this.practiceAnswer = this.practiceAnswer.slice(0, -1)
      if (this.autoCheckTimer) {
        clearTimeout(this.autoCheckTimer)
        this.autoCheckTimer = null
      }
      if (this.practiceAnswer.length > 0 && this.mode === 'text_to_code' && !this.showAnswer) {
        this.startAutoCheck()
      }
    }
  }

  // 清空输入
  private clearInput(): void {
    this.practiceAnswer = ''
    if (this.autoCheckTimer) {
      clearTimeout(this.autoCheckTimer)
      this.autoCheckTimer = null
    }
  }


  // 判断答案是否正确
  private isAnswerCorrect(): boolean {
    if (this.mode === 'text_to_code') {
      return this.practiceAnswer.trim() === this.getCorrectMorse()
    } else {
      return this.selectedChar === this.practiceChar
    }
  }

  build() {
    Stack() {
      Column() {
        if (!this.showAnswer) {
            Column() {
              if (this.mode === 'text_to_code') {
                // 文本转代码模式
                Text(this.practiceChar)
                  .fontSize(48)
                  .fontColor(this.isCorrectFeedback ? '#4CAF50' : '#FFD700')
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 8, bottom: 8 })

                // 输入显示 - 使用 Scroll 支持横向滚动
                Scroll() {
                  Text(this.practiceAnswer)
                    .fontSize(20)
                    .fontColor(this.isCorrectFeedback ? '#4CAF50' : '#FFFFFF')
                    .textAlign(TextAlign.Center)
                }
                .width('80%')
                .height(32)
                .scrollable(ScrollDirection.Horizontal)
                .scrollBar(BarState.Off)
                .padding(8)
                .backgroundColor('rgba(255, 255, 255, 0.1)')
                .borderRadius(8)
                .margin({ bottom: 8 })

                // 提示按钮
                if (this.showHint) {
                  Text(this.getCorrectMorse())
                    .fontSize(20)
                    .fontColor('#FFD700')
                    .fontWeight(FontWeight.Bold)
                    .height(32)
                    .margin({ bottom: 8 })
                } else {
                  Button() {
                    Image($r('app.media.ic_eye'))
                      .width(16)
                      .height(16)
                      .fillColor('#FFFFFF')
                  }
                  .width(32)
                  .height(32)
                  .backgroundColor('rgba(255, 255, 255, 0.1)')
                  .onClick(() => {
                    this.toggleHint()
                  })
                  .margin({ bottom: 8 })
                }
              }

              if (this.mode === 'code_to_text') {
                // 代码转文本模式：显示摩斯码（金色，无背景）
                Text(this.showMorseCode ? this.getCorrectMorse() : '')
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.isCorrectFeedback ? '#4CAF50' : '#FFD700')
                  .textAlign(TextAlign.Center)
                  .margin({ top: 12, bottom: 12 })
                  .opacity(this.showMorseCode ? 1 : 0)
              }
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .opacity(this.isContentVisible ? 1 : 0)

            // 单键输入按钮（仅字母转代码模式）- 使用 ArcButton
            if (this.useSingleButton && this.mode === 'text_to_code') {
              ArcButton({
                options: new ArcButtonOptions({
                  label: '·',
                  position: ArcButtonPosition.BOTTOM_EDGE,
                  styleMode: ArcButtonStyleMode.CUSTOM,
                  backgroundColor: ColorMetrics.resourceColor('#FFD700'),
                  fontColor: ColorMetrics.resourceColor('#000000')
                })
              })
              .onClick(() => {
                this.handleSingleButtonRelease()
              })
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) {
                  this.handleSingleButtonPress()
                } else if (event.type === TouchType.Up) {
                  this.handleSingleButtonRelease()
                }
              })
            } else if (this.mode === 'text_to_code') {
              // 双键模式（仅字母转代码模式）
              Row() {
                Button('·')
                  .width(60)
                  .height(60)
                  .backgroundColor('#FFD700')
                  .fontColor(Color.Black)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .borderRadius(30)
                  .onClick(() => {
                    this.addDot()
                    audioService.playDit()
                  })

                Button('-')
                  .width(60)
                  .height(60)
                  .backgroundColor('#FFD700')
                  .fontColor(Color.Black)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .borderRadius(30)
                  .onClick(() => {
                    this.addDash()
                    audioService.playDah()
                  })
              }
              .width('80%')
              .justifyContent(FlexAlign.SpaceEvenly)
              .margin({ top: 8, bottom: 8 })
            }

            // 代码转字母模式的字符选择（6个选项：3列2行）
            if (this.mode === 'code_to_text') {
              Grid() {
                ForEach(this.candidateChars, (char: string) => {
                  GridItem() {
                    Column() {
                      Text(char)
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#FFFFFF')
                        .textAlign(TextAlign.Center)
                    }
                    .width('100%')
                    .height('100%')
                    .justifyContent(FlexAlign.Center)
                    .backgroundColor(
                      this.selectedChar === char && char === this.practiceChar ? '#4CAF50' :
                        (this.selectedChar === char ? '#F44336' :
                          (this.selectedChar && char === this.practiceChar ? '#4CAF50' : 'rgba(255, 255, 255, 0.1)'))
                    )
                    .borderRadius(8)
                    .border({ width: 1, color: '#333333' })
                    .onClick(() => {
                      if (!this.selectedChar) {
                        this.selectChar(char)
                      }
                    })
                  }
                })
              }
              .columnsTemplate('1fr 1fr 1fr')
              .rowsTemplate('1fr 1fr')
              .columnsGap(4)
              .rowsGap(4)
              .width('80%')
              .layoutWeight(1)
              .margin({ top: 8, bottom: 20 })
              .opacity(this.showCandidateGrid ? 1 : 0)
            }
        } else {
          // 答案显示
          Text(this.isAnswerCorrect() ? LocalizationHelper.getString('watch_correct') : LocalizationHelper.getString('watch_wrong'))
            .fontSize(24)
            .fontColor(this.isAnswerCorrect() ? '#4CAF50' : '#F44336')
            .fontWeight(FontWeight.Bold)
            .margin({ top: 16, bottom: 8 })

          if (!this.isAnswerCorrect()) {
            Text(`${LocalizationHelper.getString('watch_correct_answer')} ${this.mode === 'text_to_code' 
              ? this.getCorrectMorse()
              : this.practiceChar}`)
              .fontSize(14)
              .fontColor('#FFFFFF')
              .margin({ bottom: 16 })
          }

          Button(LocalizationHelper.getString('watch_next_question'))
            .width('80%')
            .height(44)
            .backgroundColor('#FFD700')
            .fontColor('#000000')
            .fontWeight(FontWeight.Bold)
            .onClick(() => {
              this.nextQuestion()
            })
        }
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 8, bottom: 0, left: 12, right: 12 })
      .backgroundColor('#000000')

      // 引导对话框（仅 text to code 模式）
      if (this.showGuideDialog && this.mode === 'text_to_code') {
        Column() {
          Blank()
          this.GuideDialog()
          Blank()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          // 点击遮罩层关闭对话框
          this.showGuideDialog = false
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}

