import router from '@ohos.router'
import { MorseCodeData, MorseCode } from '../models/MorseCode'
import vibrator from '@ohos.vibrator'
import { BusinessError } from '@kit.BasicServicesKit'
import preferences from '@ohos.data.preferences'
import { Context } from '@kit.AbilityKit'
import { audioService } from '../services/AudioService'
import { promptAction, ArcButton, ArcButtonOptions, ArcButtonPosition, ArcButtonStyleMode, ColorMetrics } from '@kit.ArkUI'
import { LessonGroups } from '../data/LessonGroups'

@Entry
@Component
struct LessonDetailPage {
  @State lessonType: 'alphabet' | 'numbers' = 'alphabet'
  @State currentLessonGroup: string[] = []
  @State currentLessonIndex: number = 0
  @State lessonCharIndex: number = 0
  @State lessonInput: string = ''
  @State useSingleButton: boolean = true
  @State longPressThreshold: number = 300
  @State isCurrentCharCorrect: boolean = false
  @State vibrationEnabled: boolean = true
  
  private preferencesStore: preferences.Preferences | null = null
  private pressStartTime: number = 0
  private longPressTimer: number | null = null
  private autoCheckTimer: number | null = null

  async aboutToAppear() {
    // 初始化偏好设置存储
    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        this.preferencesStore = await preferences.getPreferences(context, 'lesson_progress')
        const practiceStore = await preferences.getPreferences(context, 'practice_settings')
        await this.loadButtonModePreference(practiceStore)
        await this.loadLongPressThresholdPreference(practiceStore)
        await this.loadVibrationPreference(practiceStore)
      }
    } catch (error) {
      console.error('[LessonDetailPage] Failed to initialize preferences:', error)
    }

    const params = router.getParams() as Record<string, Object>
    if (params) {
      this.lessonType = (params['lessonType'] as 'alphabet' | 'numbers') || 'alphabet'
      this.currentLessonIndex = (params['lessonIndex'] as number) || 0
      this.startLesson(this.currentLessonIndex)
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
  }

  // 加载按钮模式偏好
  private async loadButtonModePreference(store: preferences.Preferences | null): Promise<void> {
    try {
      if (store) {
        const hasSetPreference = await store.get('has_set_button_mode', false) as boolean
        if (hasSetPreference) {
          this.useSingleButton = await store.get('use_single_button', true) as boolean
        } else {
          this.useSingleButton = true // 默认单键模式
        }
      }
    } catch (error) {
      console.error('[LessonDetailPage] Failed to load button mode preference:', error)
    }
  }

  // 加载长按时间偏好
  private async loadLongPressThresholdPreference(store: preferences.Preferences | null): Promise<void> {
    try {
      if (store) {
        this.longPressThreshold = await store.get('long_press_threshold', 300) as number
      }
    } catch (error) {
      console.error('[LessonDetailPage] Failed to load long press threshold:', error)
    }
  }

  // 加载震动偏好设置
  private async loadVibrationPreference(store: preferences.Preferences | null): Promise<void> {
    try {
      if (store) {
        this.vibrationEnabled = await store.get('vibration_enabled', true) as boolean
      }
    } catch (error) {
      console.error('[LessonDetailPage] Failed to load vibration preference:', error)
    }
  }

  // 开始课程
  private startLesson(groupIndex: number): void {
    const groups = this.lessonType === 'alphabet'
      ? LessonGroups.getAlphabetGroups()
      : LessonGroups.getNumberGroups()

    if (groupIndex < groups.length) {
      this.currentLessonGroup = groups[groupIndex]
      this.currentLessonIndex = groupIndex
      this.lessonCharIndex = 0
      this.lessonInput = ''
      this.isCurrentCharCorrect = false
    }
  }

  // 获取当前课程字符
  private getCurrentLessonChar(): string {
    if (this.lessonCharIndex < this.currentLessonGroup.length) {
      return this.currentLessonGroup[this.lessonCharIndex]
    }
    return ''
  }

  // 获取当前课程字符的摩斯码
  private getCurrentLessonCharCode(): MorseCode | null {
    const currentChar = this.getCurrentLessonChar()
    if (!currentChar) {
      return null
    }
    return MorseCodeData.getAllCodes().find(c => c.character === currentChar) || null
  }

  // 检查课程答案
  private checkLessonAnswer(): void {
    // 如果输入为空，不检查
    if (this.lessonInput.trim().length === 0) {
      return
    }

    const currentChar = this.currentLessonGroup[this.lessonCharIndex]
    const charCode = MorseCodeData.getAllCodes().find(c => c.character === currentChar)

    if (charCode) {
      const isCorrect = this.lessonInput === charCode.morse ||
        this.lessonInput === charCode.morse.replace(/\./g, '·')

      if (isCorrect) {
        // 正确：将字母变为绿色，等待200ms后切换到下一个
        // 先清除自动检查定时器，防止重复检查
        if (this.autoCheckTimer) {
          clearTimeout(this.autoCheckTimer)
          this.autoCheckTimer = null
        }
        // 设置正确状态，字母变为绿色
        this.isCurrentCharCorrect = true
        // 等待500ms后切换到下一个字母，给用户更多时间看到正确的UI
        setTimeout(() => {
          this.nextLessonChar()
        }, 500)
      } else {
        // 错误：显示toast，清除输入，停留在当前字母
        // 先清除自动检查定时器，防止重复检查
        if (this.autoCheckTimer) {
          clearTimeout(this.autoCheckTimer)
          this.autoCheckTimer = null
        }
        try {
          promptAction.showToast({
            message: 'X 再试一次',
            duration: 1000,
            bottom: '45%'
          })
        } catch (error) {
          console.error('[LessonDetailPage] Failed to show toast:', error)
        }
        // 清除输入，让用户重新输入，不切换到下一个
        setTimeout(() => {
          this.lessonInput = ''
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
    this.lessonInput += '·'
    if (this.vibrationEnabled) {
      vibrator.vibrate(100, () => {})
    }
    this.startAutoCheck()
  }

  // 添加划
  private addDash(): void {
    this.lessonInput += '-'
    if (this.vibrationEnabled) {
      vibrator.vibrate(300, () => {})
    }
    this.startAutoCheck()
  }

  // 开始自动检查
  private startAutoCheck(): void {
    if (this.autoCheckTimer) {
      clearTimeout(this.autoCheckTimer)
      this.autoCheckTimer = null
    }

    // 获取当前字符的正确答案长度，用于判断输入是否可能已完成
    const currentChar = this.currentLessonGroup[this.lessonCharIndex]
    const charCode = MorseCodeData.getAllCodes().find(c => c.character === currentChar)
    const correctAnswerLength = charCode ? charCode.morse.length : 0
    const currentInputLength = this.lessonInput.length

    // 根据输入长度和正确答案长度动态调整延迟
    // 如果输入长度已经达到或超过正确答案，使用较短的延迟（用户可能已完成输入）
    // 如果输入还较短，使用较长的延迟（用户可能还在输入）
    let checkDelay: number
    if (currentInputLength >= correctAnswerLength && correctAnswerLength > 0) {
      // 输入长度已达到或超过正确答案，可能已完成，使用较短延迟
      checkDelay = 1000
    } else if (currentInputLength === 0) {
      // 输入为空，不应该检查
      return
    } else {
      // 输入还较短，用户可能还在输入，使用较长延迟
      checkDelay = 1500
    }

    // 延迟后自动检查，但需要确保输入不为空
    this.autoCheckTimer = setTimeout(() => {
      this.autoCheckTimer = null
      // 再次检查输入是否为空，防止在定时器执行期间输入被清空
      if (this.lessonInput && this.lessonInput.trim().length > 0) {
        this.checkLessonAnswer()
      }
    }, checkDelay)
  }

  // 删除最后一个字符
  private deleteLastChar(): void {
    if (this.lessonInput.length > 0) {
      this.lessonInput = this.lessonInput.slice(0, -1)
      if (this.autoCheckTimer) {
        clearTimeout(this.autoCheckTimer)
        this.autoCheckTimer = null
      }
      if (this.lessonInput.length > 0) {
        this.startAutoCheck()
      }
    }
  }

  // 清空输入
  private clearInput(): void {
    this.lessonInput = ''
    if (this.autoCheckTimer) {
      clearTimeout(this.autoCheckTimer)
      this.autoCheckTimer = null
    }
  }

  // 下一个课程字符
  private nextLessonChar(): void {
    if (this.autoCheckTimer) {
      clearTimeout(this.autoCheckTimer)
      this.autoCheckTimer = null
    }
    
    // 重置正确状态
    this.isCurrentCharCorrect = false
    
    if (this.lessonCharIndex < this.currentLessonGroup.length - 1) {
      this.lessonCharIndex++
      this.lessonInput = ''
    } else {
      // 当前组完成，可以继续下一组
      this.lessonCharIndex = this.currentLessonGroup.length
    }
  }

  // 上一个课程字符
  private prevLessonChar(): void {
    if (this.lessonCharIndex > 0) {
      this.lessonCharIndex--
      this.lessonInput = ''
      this.isCurrentCharCorrect = false
      if (this.autoCheckTimer) {
        clearTimeout(this.autoCheckTimer)
        this.autoCheckTimer = null
      }
    }
  }

  // 保存课程进度
  private async saveLessonProgress(): Promise<void> {
    try {
      if (this.preferencesStore) {
        const nextIndex = this.currentLessonIndex + 1
        const key = this.lessonType === 'alphabet' ? 'alphabet_progress' : 'numbers_progress'
        await this.preferencesStore.put(key, nextIndex)
        await this.preferencesStore.flush()
        console.log(`[LessonDetailPage] Saved progress: ${key}=${nextIndex}`)
      }
    } catch (error) {
      console.error('[LessonDetailPage] Failed to save lesson progress:', error)
    }
  }

  // 下一组课程
  private async nextLessonGroup(): Promise<void> {
    const groups = this.lessonType === 'alphabet'
      ? LessonGroups.getAlphabetGroups()
      : LessonGroups.getNumberGroups()

    if (this.currentLessonIndex < groups.length - 1) {
      // 保存当前进度
      await this.saveLessonProgress()
      this.startLesson(this.currentLessonIndex + 1)
    } else {
      // 所有课程完成，保存进度并返回
      await this.saveLessonProgress()
      router.back()
    }
  }


  build() {
    Scroll() {
      Column() {
        if (this.lessonCharIndex < this.currentLessonGroup.length) {
          // 学习单个字符
          Column() {
            // 显示所有字母，高亮当前字母
            Scroll() {
              Row() {
                ForEach(this.currentLessonGroup, (char: string, index: number) => {
                  Text(char)
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(index === this.lessonCharIndex ? '#FFD700' : '#FFFFFF')
                    .margin({ right: 8 })
                })
              }
              .justifyContent(FlexAlign.Center)
            }
            .width('100%')
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .margin({ bottom: 8 })

            Text(this.getCurrentLessonChar())
              .fontSize(64)
              .fontColor(this.isCurrentCharCorrect ? '#00FF00' : '#FFD700')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 2 })

            if (this.getCurrentLessonCharCode()) {
              // 将普通点转换为中间点显示
              Text(this.getCurrentLessonCharCode()!.morse.replace(/\./g, '·'))
                .fontSize(22)
                .fontColor('#FFFFFF')
                .margin({ bottom: 12 })
            }

            // 输入显示
            Text(this.lessonInput || '')
              .fontSize(20)
              .fontColor('#FFFFFF')
              .height(32)
              .width('80%')
              .textAlign(TextAlign.Center)
              .padding(8)
              .backgroundColor('rgba(255, 255, 255, 0.1)')
              .borderRadius(8)
              .margin({ bottom: 8 })

            // 单键输入按钮 - 使用 ArcButton 自定义金色样式
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
                // 短按处理
                this.handleSingleButtonRelease()
              })
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) {
                  this.handleSingleButtonPress()
                } else if (event.type === TouchType.Up) {
                  this.handleSingleButtonRelease()
                }
              })
              .margin({ bottom: 8 })

              // 控制按钮
              Row() {
                Button('删除')
                  .layoutWeight(1)
                  .height(32)
                  .backgroundColor('#222222')
                  .fontColor('#FFFFFF')
                  .fontSize(11)
                  .onClick(() => {
                    this.deleteLastChar()
                  })

                Button('清空')
                  .layoutWeight(1)
                  .height(32)
                  .backgroundColor('#222222')
                  .fontColor('#FFFFFF')
                  .fontSize(11)
                  .margin({ left: 6 })
                  .onClick(() => {
                    this.clearInput()
                  })
              }
              .width('80%')
              .margin({ bottom: 8 })
            } else {
              // 双键模式
              Row() {
                Button('·')
                  .width(55)
                  .height(55)
                  .backgroundColor('#FFD700')
                  .fontColor(Color.Black)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .borderRadius(28)
                  .onClick(() => {
                    this.addDot()
                    audioService.playDit()
                  })

                Button('-')
                  .width(55)
                  .height(55)
                  .backgroundColor('#FFD700')
                  .fontColor(Color.Black)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .borderRadius(28)
                  .onClick(() => {
                    this.addDash()
                    audioService.playDah()
                  })
              }
              .width('80%')
              .justifyContent(FlexAlign.SpaceEvenly)
              .margin({ bottom: 8 })

              // 控制按钮
              Row() {
                Button('删除')
                  .layoutWeight(1)
                  .height(32)
                  .backgroundColor('#222222')
                  .fontColor('#FFFFFF')
                  .fontSize(11)
                  .onClick(() => {
                    this.deleteLastChar()
                  })

                Button('清空')
                  .layoutWeight(1)
                  .height(32)
                  .backgroundColor('#222222')
                  .fontColor('#FFFFFF')
                  .fontSize(11)
                  .margin({ left: 6 })
                  .onClick(() => {
                    this.clearInput()
                  })
              }
              .width('80%')
              .margin({ bottom: 8 })
            }
          }
          .width('80%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          // 课程完成
          Column() {
            Text('✓ 完成')
              .fontSize(32)
              .fontColor('#00FF00')
              .margin({ bottom: 16 })

            Text(this.currentLessonGroup.join(' '))
              .fontSize(14)
              .fontColor('#FFFFFF')
              .margin({ bottom: 24 })

            Button('下一组')
              .width('80%')
              .height(50)
              .backgroundColor('#FFD700')
              .fontColor('#000000')
              .margin({ bottom: 16 })
              .onClick(() => {
                this.nextLessonGroup()
              })

            Button('返回')
              .width('80%')
              .height(50)
              .backgroundColor('#222222')
              .fontColor('#FFFFFF')
              .onClick(() => {
                router.back()
              })
          }
          .width('80%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 8, bottom: 8, left: 12, right: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}


