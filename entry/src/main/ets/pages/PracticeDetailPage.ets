import router from '@ohos.router'
import { MorseCodeData, MorseCode } from '../models/MorseCode'
import { audioService } from '../services/AudioService'
import vibrator from '@ohos.vibrator'
import { BusinessError } from '@kit.BasicServicesKit'
import preferences from '@ohos.data.preferences'
import { Context } from '@kit.AbilityKit'
import { promptAction, ArcButton, ArcButtonOptions, ArcButtonPosition, ArcButtonStyleMode, ColorMetrics } from '@kit.ArkUI'

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
  
  private pressStartTime: number = 0
  private longPressTimer: number | null = null
  private autoCheckTimer: number | null = null
  private hintTimer: number | null = null
  private preferencesStore: preferences.Preferences | null = null
  private allCodes: MorseCode[] = []

  async aboutToAppear() {
    // 初始化偏好设置存储
    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        this.preferencesStore = await preferences.getPreferences(context, 'practice_settings')
        await this.loadButtonModePreference()
        await this.loadLongPressThresholdPreference()
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
      const randomIndex = Math.floor(Math.random() * this.allCodes.length)
      this.practiceChar = this.allCodes[randomIndex].character
      this.generateCandidates()
      this.showMorseCode = true
      this.showCandidateGrid = true
    } else {
      this.nextQuestion()
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

  // 下一题
  private nextQuestion(): void {
    this.isCorrectFeedback = false
    this.showHint = false
    this.isContentVisible = false
    
    if (this.hintTimer) {
      clearTimeout(this.hintTimer)
      this.hintTimer = null
    }

    setTimeout(() => {
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
      
      this.isContentVisible = true
    }, 300)
  }

  // 生成候选字符（6个选项：1个正确答案 + 5个随机错误选项）
  private generateCandidates(): void {
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
    if (this.selectedChar) {
      return // 已经选择过了
    }
    
    this.selectedChar = char
    this.practiceAnswer = char
    
    const isCorrect = char === this.practiceChar
    
    if (isCorrect) {
      this.isCorrectFeedback = true
      // 正确：成功振动
      vibrator.vibrate(50, () => {})
      setTimeout(() => {
        vibrator.vibrate(50, () => {})
      }, 100)
      // 延迟后切换到下一题
      setTimeout(() => {
        this.nextQuestion()
      }, 300)
    } else {
      // 错误：错误振动
      vibrator.vibrate(250, () => {})
      // 延迟后切换到下一题
      setTimeout(() => {
        this.nextQuestion()
      }, 1500)
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

      if (isCorrect) {
        // 正确：自动切换到下一题
        if (this.autoCheckTimer) {
          clearTimeout(this.autoCheckTimer)
          this.autoCheckTimer = null
        }
        this.isCorrectFeedback = true
        // 成功振动
        vibrator.vibrate(50, () => {})
        setTimeout(() => {
          vibrator.vibrate(50, () => {})
        }, 100)
        // 延迟后切换到下一题
        setTimeout(() => {
          this.nextQuestion()
        }, 300)
      } else {
        // 错误：显示toast，清除输入
        if (this.autoCheckTimer) {
          clearTimeout(this.autoCheckTimer)
          this.autoCheckTimer = null
        }
        // 错误振动
        vibrator.vibrate(250, () => {})
        try {
          promptAction.showToast({
            message: 'X 再试一次',
            duration: 1000,
            bottom: '45%'
          })
        } catch (error) {
          console.error('[PracticeDetailPage] Failed to show toast:', error)
        }
        // 清除输入，让用户重新输入
        setTimeout(() => {
          this.practiceAnswer = ''
        }, 1500)
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
      vibrator.vibrate(100, () => {})
      this.startAutoCheck()
    }
  }

  // 添加划
  private addDash(): void {
    if (this.mode === 'text_to_code' && !this.showAnswer) {
      this.practiceAnswer += '-'
      vibrator.vibrate(300, () => {})
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
    Column() {
        if (!this.showAnswer) {
            Column() {
              if (this.mode === 'text_to_code') {
                // 文本转代码模式
                Text(this.practiceChar)
                  .fontSize(48)
                  .fontColor(this.isCorrectFeedback ? '#00FF00' : '#FFD700')
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 8, bottom: 8 })

                // 输入显示
                Text(this.practiceAnswer)
                  .fontSize(20)
                  .fontColor(this.isCorrectFeedback ? '#00FF00' : '#FFFFFF')
                  .height(32)
                  .width('80%')
                  .textAlign(TextAlign.Center)
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
                  .fontColor(this.isCorrectFeedback ? '#00FF00' : '#FFD700')
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
                Button() {
                  Circle({ width: 20, height: 20 })
                    .fill('#444444')
                }
                .width(60)
                  .height(60)
                  .backgroundColor('#FFD700')
                  .borderRadius(30)
                  .onClick(() => {
                    this.addDot()
                    audioService.playDit()
                  })

                Button('-')
                  .width(60)
                  .height(60)
                  .backgroundColor('#FFD700')
                  .fontColor('#444444')
                  .fontSize(16)
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
                      this.selectedChar === char && char === this.practiceChar ? '#00FF00' :
                        (this.selectedChar === char ? '#FF0000' :
                          (this.selectedChar && char === this.practiceChar ? '#00FF00' : 'rgba(255, 255, 255, 0.1)'))
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
        } else {
          // 答案显示
          Text(this.isAnswerCorrect() ? '✓ 正确' : '✗ 错误')
            .fontSize(24)
            .fontColor(this.isAnswerCorrect() ? '#00FF00' : '#FF0000')
            .fontWeight(FontWeight.Bold)
            .margin({ top: 16, bottom: 8 })

          if (!this.isAnswerCorrect()) {
            Text(this.mode === 'text_to_code' 
              ? `正确答案: ${this.getCorrectMorse()}`
              : `正确答案: ${this.practiceChar}`)
              .fontSize(14)
              .fontColor('#FFFFFF')
              .margin({ bottom: 16 })
          }

          Button('下一题')
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
  }
}

