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
struct PracticeMistakesPage {
  @State mistakeCode: MorseCode | null = null
  @State practiceAnswer: string = ''
  @State showAnswer: boolean = false
  @State useSingleButton: boolean = false
  @State longPressThreshold: number = 300
  @State isCorrectFeedback: boolean = false
  @State showHint: boolean = false
  @State isContentVisible: boolean = true
  @State isEmpty: boolean = false
  @State currentMode: PracticeMode = 'text_to_code'
  @State candidateChars: string[] = []
  @State selectedChar: string = ''
  @State showMorseCode: boolean = true
  @State showCandidateGrid: boolean = true
  @State vibrationEnabled: boolean = true
  
  private pressStartTime: number = 0
  private longPressTimer: number | null = null
  private autoCheckTimer: number | null = null
  private hintTimer: number | null = null
  private preferencesStore: preferences.Preferences | null = null
  private mistakesList: MorseCode[] = []
  private currentMistakeIndex: number = 0
  private allCodes: MorseCode[] = []
  
  private nextQuestionTimer: number | null = null
  private checkAnswerTimers: number[] = []
  private selectCharTimers: number[] = []
  private isTransitioning: boolean = false

  async aboutToAppear() {
    // Initialize preferences
    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        this.preferencesStore = await preferences.getPreferences(context, 'practice_settings')
        await this.loadButtonModePreference()
        await this.loadLongPressThresholdPreference()
        await this.loadVibrationPreference()
        
        // Load mistakes and all codes
        await FavoritesStore.getInstance().init(context)
        this.allCodes = [
          ...MorseCodeData.englishAlphabet,
          ...MorseCodeData.numbers
        ]
        this.loadMistakes()
      }
    } catch (error) {
      console.error('[PracticeMistakesPage] Failed to initialize:', error)
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
    this.checkAnswerTimers.forEach(id => clearTimeout(id))
    this.checkAnswerTimers = []
    this.selectCharTimers.forEach(id => clearTimeout(id))
    this.selectCharTimers = []
  }

  private loadMistakes(): void {
    const mistakes = FavoritesStore.getInstance().getMistakeMorseCodes()
    this.mistakesList = mistakes
    
    if (this.mistakesList.length === 0) {
      this.isEmpty = true
      this.mistakeCode = null
    } else {
      this.isEmpty = false
      this.mistakesList.sort(() => Math.random() - 0.5)
      this.currentMistakeIndex = 0
      this.nextQuestion(false)
    }
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

  // Load button mode preference
  private async loadButtonModePreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        const hasSetPreference = await this.preferencesStore.get('has_set_button_mode', false) as boolean
        if (hasSetPreference) {
          this.useSingleButton = await this.preferencesStore.get('use_single_button', false) as boolean
        } else {
          this.useSingleButton = true
        }
      }
    } catch (error) {
      console.error('[PracticeMistakesPage] Failed to load button mode preference:', error)
    }
  }

  // Load long press threshold preference
  private async loadLongPressThresholdPreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        this.longPressThreshold = await this.preferencesStore.get('long_press_threshold', 300) as number
      }
    } catch (error) {
      console.error('[PracticeMistakesPage] Failed to load long press threshold:', error)
    }
  }

  // 加载震动偏好设置
  private async loadVibrationPreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        this.vibrationEnabled = await this.preferencesStore.get('vibration_enabled', true) as boolean
      }
    } catch (error) {
      console.error('[PracticeMistakesPage] Failed to load vibration preference:', error)
    }
  }

  // Generate candidate chars for code_to_text mode
  private generateCandidates(): void {
    if (!this.mistakeCode || this.allCodes.length === 0) {
      this.candidateChars = []
      return
    }

    const candidates: string[] = [this.mistakeCode.character]
    const availableChars = this.allCodes.filter(code => code.character !== this.mistakeCode?.character)
    
    const count = Math.min(5, availableChars.length)
    for (let i = 0; i < count; i++) {
      const randomIndex = Math.floor(Math.random() * availableChars.length)
      candidates.push(availableChars[randomIndex].character)
      availableChars.splice(randomIndex, 1)
    }
    
    this.candidateChars = candidates.sort(() => Math.random() - 0.5)
  }

  // Next question logic
  private nextQuestion(animate: boolean = true): void {
    if (this.isTransitioning && animate) return

    if (this.mistakesList.length === 0) {
      this.isEmpty = true
      this.mistakeCode = null
      return
    }

    if (this.currentMistakeIndex >= this.mistakesList.length) {
      this.currentMistakeIndex = 0
    }

    this.isCorrectFeedback = false
    this.showHint = false
    this.practiceAnswer = ''
    this.showAnswer = false
    this.selectedChar = ''
    
    // Randomly select mode
    this.currentMode = Math.random() > 0.5 ? 'text_to_code' : 'code_to_text'
    
    if (animate) {
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
        this.mistakeCode = this.mistakesList[this.currentMistakeIndex]
        if (this.currentMode === 'code_to_text') {
          this.generateCandidates()
        }
        this.isContentVisible = true
        this.isTransitioning = false
        this.nextQuestionTimer = null
      }, 300)
    } else {
      this.mistakeCode = this.mistakesList[this.currentMistakeIndex]
      if (this.currentMode === 'code_to_text') {
        this.generateCandidates()
      }
      this.isContentVisible = true
    }
  }

  // Get correct Morse answer
  private getCorrectMorse(): string {
    return this.mistakeCode ? this.mistakeCode.morse.replace(/\./g, '·') : ''
  }

  // Select Char (Code to Text mode)
  private selectChar(char: string): void {
    if (this.selectedChar || this.isTransitioning || !this.mistakeCode) {
      return
    }
    
    this.selectedChar = char
    const isCorrect = char === this.mistakeCode.character
    
    // Clean up timers
    this.selectCharTimers.forEach(id => clearTimeout(id))
    this.selectCharTimers = []
    
    if (isCorrect) {
      FavoritesStore.getInstance().tryRemoveFromMistakes(this.mistakeCode.character)
      this.isCorrectFeedback = true
      
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

      const t3 = setTimeout(() => {
        this.currentMistakeIndex++
        this.nextQuestion()
      }, 300)
      this.selectCharTimers.push(t3)
    } else {
      FavoritesStore.getInstance().addToMistakes(this.mistakeCode.character)
      if (vibratorService.isVibrationEnabled()) {
        vibrator.vibrate(250, () => {})
      }
      
      const t4 = setTimeout(() => {
        // Move to next question even on wrong answer in mistakes mode? 
        // Or stay? Original logic stayed. But let's stay to let user see correct answer?
        // Actually, usually we show feedback and move on or retry.
        // PracticeDetailPage moves on after 1500ms for code_to_text.
        this.currentMistakeIndex++
        this.nextQuestion()
      }, 1500)
      this.selectCharTimers.push(t4)
    }
  }

  // Check answer (Text to Code mode)
  private checkAnswer(): void {
    if (!this.mistakeCode) return

    const correctMorse = this.getCorrectMorse()
    const isCorrect = this.practiceAnswer.trim() === correctMorse

    // Clean up timers
    this.checkAnswerTimers.forEach(id => clearTimeout(id))
    this.checkAnswerTimers = []

    if (isCorrect) {
      if (this.autoCheckTimer) {
        clearTimeout(this.autoCheckTimer)
        this.autoCheckTimer = null
      }
      this.isCorrectFeedback = true
      
      FavoritesStore.getInstance().tryRemoveFromMistakes(this.mistakeCode.character)

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

      const t3 = setTimeout(() => {
        this.currentMistakeIndex++
        this.nextQuestion()
      }, 300)
      this.checkAnswerTimers.push(t3)
    } else {
      if (this.autoCheckTimer) {
        clearTimeout(this.autoCheckTimer)
        this.autoCheckTimer = null
      }
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
        console.error('[PracticeMistakesPage] Failed to show toast:', error)
      }
      
      FavoritesStore.getInstance().addToMistakes(this.mistakeCode.character)

      const t4 = setTimeout(() => {
        this.practiceAnswer = ''
      }, 1500)
      this.checkAnswerTimers.push(t4)
    }
  }

  // Delete current mistake
  private async deleteCurrentMistake(): Promise<void> {
    if (this.mistakeCode) {
      await FavoritesStore.getInstance().removeFromMistakes(this.mistakeCode.character)
      this.mistakesList.splice(this.currentMistakeIndex, 1)
      if (this.currentMistakeIndex >= this.mistakesList.length) {
        this.currentMistakeIndex = 0
      }
      this.nextQuestion(true)
    }
  }

  // Input handling
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
      await audioService.playDit()
    }
  }

  private async handleLongPress(): Promise<void> {
    this.addDash()
    await audioService.playDah()
  }

  private addDot(): void {
    if (!this.showAnswer) {
      this.practiceAnswer += '·'
      if (vibratorService.isVibrationEnabled()) {
        vibrator.vibrate(100, () => {})
      }
      this.startAutoCheck()
    }
  }

  private addDash(): void {
    if (!this.showAnswer) {
      this.practiceAnswer += '-'
      if (vibratorService.isVibrationEnabled()) {
        vibrator.vibrate(300, () => {})
      }
      this.startAutoCheck()
    }
  }

  private startAutoCheck(): void {
    if (this.showAnswer || !this.mistakeCode) return

    if (this.autoCheckTimer) {
      clearTimeout(this.autoCheckTimer)
      this.autoCheckTimer = null
    }

    const correctAnswerLength = this.mistakeCode.morse.length
    const currentInputLength = this.practiceAnswer.length

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

  private deleteLastChar(): void {
    if (this.practiceAnswer.length > 0) {
      this.practiceAnswer = this.practiceAnswer.slice(0, -1)
      if (this.autoCheckTimer) {
        clearTimeout(this.autoCheckTimer)
        this.autoCheckTimer = null
      }
      if (this.practiceAnswer.length > 0 && !this.showAnswer) {
        this.startAutoCheck()
      }
    }
  }

  private clearInput(): void {
    this.practiceAnswer = ''
    if (this.autoCheckTimer) {
      clearTimeout(this.autoCheckTimer)
      this.autoCheckTimer = null
    }
  }

  build() {
    Stack() {
      if (this.isEmpty) {
        Column() {
          Text(LocalizationHelper.getString('watch_mistakes_empty'))
            .fontSize(16)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
            .width('80%')
            .margin({ bottom: 20 })
          
          Button(LocalizationHelper.getString('watch_back'))
            .width('80%')
            .height(44)
            .backgroundColor('#FFD700')
            .fontColor('#000000')
            .onClick(() => {
              router.back()
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Stack({ alignContent: Alignment.TopEnd }) {
          // Back button
          Button() {
            Image($rawfile('ic_back.svg'))
              .width(16)
              .height(16)
              .fillColor(Color.White)
          }
          .width(36)
          .height(36)
          .backgroundColor('rgba(255, 255, 255, 0.1)')
          .borderRadius(18)
          .margin({ top: 8, right: 8 })
          .onClick(() => {
            router.back()
          })

          // Main content
          Column() {
            if (!this.showAnswer && this.mistakeCode) {
              
              if (this.currentMode === 'text_to_code') {
                // --- Text to Code Mode UI ---
                Column() {
                  // Character display
                  Text(this.mistakeCode.character)
                    .fontSize(48)
                    .fontColor(this.isCorrectFeedback ? '#4CAF50' : '#FFD700')
                    .fontWeight(FontWeight.Bold)
                    .margin({ top: 8, bottom: 8 })

                  // Input display - 使用 Scroll 支持横向滚动
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

                  // Hint and Delete buttons
                  if (this.showHint) {
                    Text(this.getCorrectMorse())
                      .fontSize(20)
                      .fontColor('#FFD700')
                      .fontWeight(FontWeight.Bold)
                      .height(32)
                      .margin({ bottom: 8 })
                  } else {
                    Row() {
                      // Hint Button
                      Button() {
                        SymbolGlyph($r('sys.symbol.eye'))
                          .fontSize(20)
                          .fontColor(['#FFFFFF'])
                      }
                      .width(32)
                      .height(32)
                      .backgroundColor('rgba(255, 255, 255, 0.1)')
                      .onClick(() => {
                        this.toggleHint()
                      })

                      // Delete Button
                      Button() {
                        SymbolGlyph($r('sys.symbol.trash'))
                          .fontSize(20)
                          .fontColor(['#F44336'])
                      }
                      .width(32)
                      .height(32)
                      .backgroundColor('rgba(255, 255, 255, 0.1)')
                      .margin({ left: 12 })
                      .onClick(() => {
                        this.deleteCurrentMistake()
                      })
                    }
                    .margin({ bottom: 8 })
                  }
                }
                .width('100%')
                .layoutWeight(1)
                .justifyContent(FlexAlign.Center)
                .opacity(this.isContentVisible ? 1 : 0)

                // Input Buttons
                if (this.useSingleButton) {
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
                } else {
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
              } else {
                // --- Code to Text Mode UI ---
                Column() {
                  // Morse display
                  Text(this.showMorseCode ? this.getCorrectMorse() : '')
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.isCorrectFeedback ? '#4CAF50' : '#FFD700')
                    .textAlign(TextAlign.Center)
                    .margin({ top: 12, bottom: 12 })
                    .opacity(this.showMorseCode ? 1 : 0)

                  // Candidate Grid
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
                          this.selectedChar === char && char === this.mistakeCode?.character ? '#4CAF50' :
                            (this.selectedChar === char ? '#F44336' :
                              (this.selectedChar && char === this.mistakeCode?.character ? '#4CAF50' : 'rgba(255, 255, 255, 0.1)'))
                        )
                        .borderRadius(8)
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
                .width('100%')
                .layoutWeight(1)
                .justifyContent(FlexAlign.Center)
                .opacity(this.isContentVisible ? 1 : 0)
              }
            }
          }
          .width('100%')
          .height('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 20, bottom: 0, left: 12, right: 12 })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
