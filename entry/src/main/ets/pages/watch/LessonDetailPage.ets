import router from '@ohos.router'
import { MorseCodeData, MorseCode } from '../../models/MorseCode'
import vibrator from '@ohos.vibrator'
import { BusinessError } from '@kit.BasicServicesKit'
import preferences from '@ohos.data.preferences'
import { Context } from '@kit.AbilityKit'
import { audioService } from '../../services/AudioService'
import { vibratorService } from '../../services/VibratorService'
import { promptAction, ArcButton, ArcButtonOptions, ArcButtonPosition, ArcButtonStyleMode, ColorMetrics } from '@kit.ArkUI'
import { LessonGroups } from '../../data/LessonGroups'
import { LocalizationHelper } from '../../utils/LocalizationHelper'
import { FavoritesStore } from '../../store/FavoritesStore'
import { progressStore } from '../../store/ProgressStoreSingleton'
import { LessonConfig } from '../../data/LessonConfig'

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
  @State showGuideDialog: boolean = false
  @State vibrationEnabled: boolean = true
  
  private preferencesStore: preferences.Preferences | null = null
  private pressStartTime: number = 0
  private longPressTimer: number | null = null
  private autoCheckTimer: number | null = null
  private nextCharTimer: number | null = null
  private clearInputTimer: number | null = null
  private saveTimer: number | null = null
  private isChecking: boolean = false
  private pendingSave: boolean = false

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
        await this.checkAndShowGuide()
      }
    } catch (error) {
      console.error('[LessonDetailPage] Failed to initialize preferences:', error)
    }

    const params = router.getParams() as Record<string, Object>
    if (params) {
      const lessonType = (params['lessonType'] as 'alphabet' | 'numbers') || 'alphabet'
      const lessonIndex = (params['lessonIndex'] as number) || 0

      // 验证 lessonType
      if (lessonType !== 'alphabet' && lessonType !== 'numbers') {
        console.error('[LessonDetailPage] Invalid lessonType:', lessonType)
        router.back()
        return
      }

      // 验证 lessonIndex
      const groups = lessonType === 'alphabet'
        ? LessonGroups.getAlphabetGroups()
        : LessonGroups.getNumberGroups()
      
      if (lessonIndex < 0 || lessonIndex >= groups.length) {
        console.error('[LessonDetailPage] Invalid lessonIndex:', lessonIndex, 'max:', groups.length - 1)
        this.currentLessonIndex = 0
      } else {
        this.currentLessonIndex = lessonIndex
      }

      this.lessonType = lessonType
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
    if (this.nextCharTimer) {
      clearTimeout(this.nextCharTimer)
      this.nextCharTimer = null
    }
    if (this.clearInputTimer) {
      clearTimeout(this.clearInputTimer)
      this.clearInputTimer = null
    }
    
    // 确保保存待处理的进度
    if (this.pendingSave && this.preferencesStore) {
      const nextIndex = this.currentLessonIndex + 1
      const key = this.lessonType === 'alphabet' ? 'alphabet_progress' : 'numbers_progress'
      this.preferencesStore.put(key, nextIndex).then(() => {
        return this.preferencesStore?.flush()
      }).catch((error: Error) => {
        console.error('[LessonDetailPage] Failed to save progress on exit:', error)
      })
    }
    
    if (this.saveTimer) {
      clearTimeout(this.saveTimer)
      this.saveTimer = null
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
    if (this.isChecking) {
      return // 防止重复检查
    }

    // 如果输入为空，不检查
    if (this.lessonInput.trim().length === 0) {
      return
    }

    this.isChecking = true

    // 清除自动检查定时器
    if (this.autoCheckTimer) {
      clearTimeout(this.autoCheckTimer)
      this.autoCheckTimer = null
    }

    const currentChar = this.currentLessonGroup[this.lessonCharIndex]
    const charCode = MorseCodeData.getAllCodes().find(c => c.character === currentChar)

    if (charCode) {
      const isCorrect = this.lessonInput === charCode.morse ||
        this.lessonInput === charCode.morse.replace(/\./g, '·')

      if (isCorrect) {
        // 正确：将字母变为绿色，等待200ms后切换到下一个
        if (this.nextCharTimer) {
          clearTimeout(this.nextCharTimer)
        }
        
        // 尝试从错题本移除
        FavoritesStore.getInstance().tryRemoveFromMistakes(currentChar)
        
        // 设置正确状态，字母变为绿色
        this.isCurrentCharCorrect = true
        // 等待500ms后切换到下一个字母
        this.nextCharTimer = setTimeout(() => {
          this.nextLessonChar()
          this.isChecking = false
          this.nextCharTimer = null
        }, 500)
      } else {
        // 错误：显示toast，清除输入
        if (this.clearInputTimer) {
          clearTimeout(this.clearInputTimer)
        }
        
        // 加入错题本
        FavoritesStore.getInstance().addToMistakes(currentChar)
        
        try {
          promptAction.showToast({
            message: LocalizationHelper.getString('watch_try_again'),
            duration: 1000,
            bottom: '45%'
          })
        } catch (error) {
          console.error('[LessonDetailPage] Failed to show toast:', error)
        }
        // 清除输入，让用户重新输入
        this.clearInputTimer = setTimeout(() => {
          this.lessonInput = ''
          this.isChecking = false
          this.clearInputTimer = null
        }, 1500)
      }
    } else {
      this.isChecking = false
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
    if (vibratorService.isVibrationEnabled()) {
      vibrator.vibrate(100, () => {})
    }
    this.startAutoCheck()
  }

  // 添加划
  private addDash(): void {
    this.lessonInput += '-'
    if (vibratorService.isVibrationEnabled()) {
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
      // 立即保存进度
      this.saveLessonProgress()
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

  // 保存课程进度 (防抖)
  private async saveLessonProgress(): Promise<void> {
    if (!this.preferencesStore) return
    
    this.pendingSave = true
    
    if (this.saveTimer) {
      clearTimeout(this.saveTimer)
    }
    
    this.saveTimer = setTimeout(async () => {
      if (this.pendingSave && this.preferencesStore) {
        try {
          const nextIndex = this.currentLessonIndex + 1
          const key = this.lessonType === 'alphabet' ? 'alphabet_progress' : 'numbers_progress'
          await this.preferencesStore.put(key, nextIndex)
          await this.preferencesStore.flush()
          this.pendingSave = false
          console.log(`[LessonDetailPage] Saved progress: ${key}=${nextIndex}`)
          
          // 同时保存到 ProgressStoreSingleton 并发送事件
          // 根据 lessonType 和 currentLessonIndex 计算课程编号
          const lessonId = this.lessonType === 'alphabet' 
            ? `alphabet_lesson_${this.currentLessonIndex}`
            : `number_lesson_${this.currentLessonIndex}`
          const lessonNumber = LessonConfig.getLessonNumber(lessonId)
          
          if (lessonNumber > 0) {
            const context = this.getUIContext()?.getHostContext() as Context
            if (context) {
              await progressStore.saveLessonCompleted(lessonNumber, context)
              console.log(`[LessonDetailPage] Lesson ${lessonNumber} also saved to ProgressStoreSingleton`)
            }
          }
        } catch (error) {
          console.error('[LessonDetailPage] Failed to save lesson progress:', error)
        }
      }
      this.saveTimer = null
    }, 500)
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

  // 检查并显示引导对话框
  private async checkAndShowGuide(): Promise<void> {
    try {
      if (this.preferencesStore) {
        const hasShownGuide = await this.preferencesStore.get('has_shown_watch_letter_lesson_guide', false) as boolean
        if (!hasShownGuide) {
          // 延迟显示，确保页面已加载
          setTimeout(() => {
            this.showGuideDialog = true
          }, 500)
        }
      }
    } catch (error) {
      console.error('[LessonDetailPage] Failed to check guide:', error)
    }
  }

  // 保存已显示引导的状态
  private async saveGuideShown(): Promise<void> {
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.put('has_shown_watch_letter_lesson_guide', true)
        await this.preferencesStore.flush()
        console.log('[LessonDetailPage] Saved guide shown status')
      }
    } catch (error) {
      console.error('[LessonDetailPage] Failed to save guide shown status:', error)
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

      Text(LocalizationHelper.getString('watch_guide_text_letter_lesson'))
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
          await this.saveGuideShown()
          this.showGuideDialog = false
        })
    }
    .padding(24)
    .backgroundColor('#2A2A2A')
    .borderRadius(12)
    .width('85%')
    .constraintSize({ maxWidth: 400 })
  }

  build() {
    Stack() {
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
              .fontColor(this.isCurrentCharCorrect ? '#4CAF50' : '#FFD700')
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 2 })

            if (this.getCurrentLessonCharCode()) {
              // 将普通点转换为中间点显示
              Text(this.getCurrentLessonCharCode()!.morse.replace(/\./g, '·'))
                .fontSize(22)
                .fontColor('#FFFFFF')
                .margin({ bottom: 12 })
            }

            // 输入显示 - 使用 Scroll 支持横向滚动
            Scroll() {
              Text(this.lessonInput || '')
                .fontSize(20)
                .fontColor('#FFFFFF')
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
                Button(LocalizationHelper.getString('watch_delete'))
                  .layoutWeight(1)
                  .height(32)
                  .backgroundColor('#222222')
                  .fontColor('#FFFFFF')
                  .fontSize(11)
                  .onClick(() => {
                    this.deleteLastChar()
                  })

                Button(LocalizationHelper.getString('watch_clear'))
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
                Button(LocalizationHelper.getString('watch_delete'))
                  .layoutWeight(1)
                  .height(32)
                  .backgroundColor('#222222')
                  .fontColor('#FFFFFF')
                  .fontSize(11)
                  .onClick(() => {
                    this.deleteLastChar()
                  })

                Button(LocalizationHelper.getString('watch_clear'))
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
            Text(LocalizationHelper.getString('watch_completed'))
              .fontSize(32)
              .fontColor('#4CAF50')
              .margin({ bottom: 16 })

            Text(this.currentLessonGroup.join(' '))
              .fontSize(14)
              .fontColor('#FFFFFF')
              .margin({ bottom: 24 })

            Button(LocalizationHelper.getString('watch_next_group'))
              .width('80%')
              .height(50)
              .backgroundColor('#FFD700')
              .fontColor('#000000')
              .margin({ bottom: 16 })
              .onClick(() => {
                this.nextLessonGroup()
              })

            Button(LocalizationHelper.getString('watch_back'))
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
      .focusable(true)
      .defaultFocus(true)

      // 引导对话框
      if (this.showGuideDialog) {
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

