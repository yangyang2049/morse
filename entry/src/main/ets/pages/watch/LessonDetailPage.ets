import router from '@ohos.router'
import { MorseCodeData, MorseCode } from '../../models/MorseCode'
import vibrator from '@ohos.vibrator'
import preferences from '@ohos.data.preferences'
import { Context } from '@kit.AbilityKit'
import { audioService } from '../../services/AudioService'
import { vibratorService } from '../../services/VibratorService'
import { promptAction, ArcButton, ArcButtonOptions, ArcButtonPosition, ArcButtonStyleMode, ColorMetrics } from '@kit.ArkUI'
import { LocalizationHelper } from '../../utils/LocalizationHelper'
import { CourseCatalogV2, CourseDefinition } from '../../data/CourseCatalogV2'
import { LocalLearningSettings } from '../../store/LocalLearningSettings'
import { learningRepositoryV2 } from '../../repository/LearningRepositoryV2'

@Entry
@Component
struct LessonDetailPage {
  @State courseId: string = ''
  @State currentLessonGroup: string[] = []
  @State lessonCharIndex: number = 0
  @State lessonInput: string = ''
  @State longPressThreshold: number = 300
  @State isCurrentCharCorrect: boolean = false
  @State showGuideDialog: boolean = false
  @State vibrationEnabled: boolean = true
  @State requiredPracticeCount: number = 3
  @State practiceCounts: Map<string, number> = new Map()
  @State showProgressToast: boolean = false
  @State progressToastText: string = ''
  
  private practiceSettingsStore: preferences.Preferences | null = null
  private pressStartTime: number = 0
  private longPressTimer: number | null = null
  private autoCheckTimer: number | null = null
  private nextCharTimer: number | null = null
  private clearInputTimer: number | null = null
  private guideTimer: number | null = null
  private progressToastTimer: number | null = null
  private isChecking: boolean = false
  private isPageActive: boolean = false
  private course: CourseDefinition | null = null

  async aboutToAppear() {
    this.isPageActive = true
    const params = router.getParams() as Record<string, Object>
    const courseId = params && typeof params['courseId'] === 'string' ? params['courseId'] as string : ''
    const course = CourseCatalogV2.get(courseId)
    if (!course || course.kind === 'knowledge') {
      router.back()
      return
    }
    this.courseId = course.id
    this.course = course
    this.currentLessonGroup = [...course.items]
    this.lessonCharIndex = 0
    this.lessonInput = ''

    try {
      const context = this.getUIContext()?.getHostContext() as Context
      if (context) {
        this.practiceSettingsStore = await preferences.getPreferences(context, 'practice_settings')
        await this.loadLongPressThresholdPreference(this.practiceSettingsStore)
        await this.loadVibrationPreference(this.practiceSettingsStore)
        this.requiredPracticeCount = course.kind === 'review'
          ? 1
          : await LocalLearningSettings.getRepetitionCount(context)
        await this.checkAndShowGuide()
      }
    } catch (error) {
      console.error('[LessonDetailPage] Failed to initialize preferences:', error)
    }

  }

  aboutToDisappear() {
    this.isPageActive = false
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
    if (this.guideTimer) {
      clearTimeout(this.guideTimer)
      this.guideTimer = null
    }
    if (this.progressToastTimer) {
      clearTimeout(this.progressToastTimer)
      this.progressToastTimer = null
    }
    this.showProgressToast = false
    
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

  // 获取当前课程字符
  private getCurrentLessonChar(): string {
    if (this.lessonCharIndex < this.currentLessonGroup.length) {
      return this.currentLessonGroup[this.lessonCharIndex]
    }
    return ''
  }

  private isWordCourse(): boolean {
    return this.course?.unitId === 'words'
  }

  private getPreviousVisibleItems(): string[] {
    const visibleCount = this.isWordCourse() ? 1 : 2
    const startIndex = Math.max(0, this.lessonCharIndex - visibleCount)
    return this.currentLessonGroup.slice(startIndex, this.lessonCharIndex)
  }

  private getNextVisibleItems(): string[] {
    const visibleCount = this.isWordCourse() ? 1 : 2
    return this.currentLessonGroup.slice(
      this.lessonCharIndex + 1,
      this.lessonCharIndex + 1 + visibleCount
    )
  }

  // 获取当前课程字符的摩斯码
  private getCurrentLessonCharCode(): MorseCode | null {
    const currentChar = this.getCurrentLessonChar()
    if (!currentChar) {
      return null
    }
    const existing = MorseCodeData.getAllCodes().find((code: MorseCode) => code.character === currentChar)
    if (existing) {
      return existing
    }
    if (this.course?.unitId === 'words') {
      return new MorseCode(currentChar, MorseCodeData.textToMorse(currentChar).replace(/·/g, '.'), '')
    }
    return null
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
    const charCode = this.getCurrentLessonCharCode()

    if (charCode) {
      const normalize = (value: string): string => value.replace(/·/g, '.').replace(/\s+/g, '')
      const isCorrect = normalize(this.lessonInput) === normalize(charCode.morse)
      void learningRepositoryV2.recordAttempt(this.courseId, currentChar, isCorrect)

      if (isCorrect) {
        // 正确：将字母变为绿色，等待200ms后切换到下一个
        if (this.nextCharTimer) {
          clearTimeout(this.nextCharTimer)
        }
        
        const currentCount = this.practiceCounts.get(currentChar) || 0
        const nextCounts = new Map(this.practiceCounts)
        nextCounts.set(currentChar, currentCount + 1)
        this.practiceCounts = nextCounts
        this.showPracticeProgressToast(currentCount + 1)
        const itemCompleted = currentCount + 1 >= this.requiredPracticeCount
        this.isCurrentCharCorrect = itemCompleted
        this.nextCharTimer = setTimeout(() => {
          if (!this.isPageActive) {
            return
          }
          this.hidePracticeProgressToast()
          if (itemCompleted) {
            this.nextLessonChar()
          } else {
            this.lessonInput = ''
            this.isCurrentCharCorrect = false
          }
          this.isChecking = false
          this.nextCharTimer = null
        }, 500)
      } else {
        // 错误：显示toast，清除输入
        if (this.clearInputTimer) {
          clearTimeout(this.clearInputTimer)
        }
        
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
          if (!this.isPageActive) {
            return
          }
          this.lessonInput = ''
          this.isChecking = false
          this.clearInputTimer = null
        }, 1500)
      }
    } else {
      this.isChecking = false
    }
  }

  private showPracticeProgressToast(completedCount: number): void {
    if (this.requiredPracticeCount <= 1 || !this.isPageActive) {
      return
    }
    if (this.progressToastTimer) {
      clearTimeout(this.progressToastTimer)
    }
    const progress = Math.min(completedCount, this.requiredPracticeCount)
    this.progressToastText = `${progress}/${this.requiredPracticeCount}`
    this.showProgressToast = true
    this.progressToastTimer = setTimeout(() => {
      if (this.isPageActive) {
        this.showProgressToast = false
      }
      this.progressToastTimer = null
    }, 800)
  }

  private hidePracticeProgressToast(): void {
    if (this.progressToastTimer) {
      clearTimeout(this.progressToastTimer)
      this.progressToastTimer = null
    }
    this.showProgressToast = false
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
    const charCode = this.getCurrentLessonCharCode()
    const correctAnswerLength = charCode ? charCode.morse.replace(/\s+/g, '').length : 0
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
      if (!this.isPageActive) {
        return
      }
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
      this.lessonCharIndex = this.currentLessonGroup.length
      void this.saveLessonProgress()
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

  // 仅当固定 CourseId 的全部练习项达标后写完成状态。
  private async saveLessonProgress(): Promise<void> {
    try {
      const allItemsCompleted = this.currentLessonGroup.every((item: string) =>
        (this.practiceCounts.get(item) || 0) >= this.requiredPracticeCount)
      if (this.isPageActive && this.courseId.length > 0 &&
        this.lessonCharIndex >= this.currentLessonGroup.length && allItemsCompleted) {
        await learningRepositoryV2.completeCourse(this.courseId)
        console.log(`[LessonDetailPage] Completed courseId=${this.courseId}`)
      }
    } catch (error) {
      console.error('[LessonDetailPage] Failed to save lesson progress:', error)
    }
  }

  // 检查并显示引导对话框
  private async checkAndShowGuide(): Promise<void> {
    try {
      if (this.practiceSettingsStore) {
        const hasShownGuide = await this.practiceSettingsStore.get('has_shown_watch_letter_lesson_guide', false) as boolean
        if (!hasShownGuide && this.isPageActive) {
          this.guideTimer = setTimeout(() => {
            if (this.isPageActive) {
              this.showGuideDialog = true
            }
            this.guideTimer = null
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
      if (this.practiceSettingsStore) {
        await this.practiceSettingsStore.put('has_shown_watch_letter_lesson_guide', true)
        await this.practiceSettingsStore.flush()
        console.log('[LessonDetailPage] Saved guide shown status')
      }
    } catch (error) {
      console.error('[LessonDetailPage] Failed to save guide shown status:', error)
    }
  }

  @Builder
  private CourseFocusRail() {
    Row() {
      Row() {
        ForEach(this.getPreviousVisibleItems(), (item: string, index: number) => {
          Text(item)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
            .opacity(index === this.getPreviousVisibleItems().length - 1 ? 0.85 : 0.5)
            .maxLines(1)
            .margin({ right: this.isWordCourse() ? 3 : 5 })
        }, (item: string, index: number) => `previous-${this.lessonCharIndex}-${index}-${item}`)
      }
      .width(this.isWordCourse() ? '22%' : '28%')
      .justifyContent(FlexAlign.End)

      Text(this.getCurrentLessonChar())
        .width(this.isWordCourse() ? '56%' : '44%')
        .fontSize(this.isWordCourse() ? 28 : 60)
        .fontColor(this.isCurrentCharCorrect ? '#4CAF50' : '#FFD700')
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .maxLines(1)

      Row() {
        ForEach(this.getNextVisibleItems(), (item: string, index: number) => {
          Text(item)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .opacity(index === 0 ? 0.75 : 0.45)
            .maxLines(1)
            .margin({ left: this.isWordCourse() ? 3 : 5 })
        }, (item: string, index: number) => `next-${this.lessonCharIndex}-${index}-${item}`)
      }
      .width(this.isWordCourse() ? '22%' : '28%')
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height(this.isWordCourse() ? 56 : 72)
    .alignItems(VerticalAlign.Center)
  }

  // 引导对话框 Builder
  @Builder
  private GuideDialog() {
    Column() {
      Text(LocalizationHelper.getString('hint'))
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
      Column() {
        if (this.lessonCharIndex < this.currentLessonGroup.length) {
          // 学习单个字符（收紧垂直间距，使 ArcButton 贴底且完全可见）
          Column() {
            Column() {
              this.CourseFocusRail()

              if (this.getCurrentLessonCharCode()) {
                Text(this.getCurrentLessonCharCode()!.morse.replace(/\./g, '·'))
                  .fontSize(this.isWordCourse() ? 12 : 20)
                  .fontColor('#FFFFFF')
                  .margin({ bottom: 6 })
              }

              // 输入显示
              Scroll() {
                Text(this.lessonInput || '')
                  .fontSize(20)
                  .fontColor('#FFFFFF')
                  .textAlign(TextAlign.Center)
              }
              .width(this.isWordCourse() ? '90%' : '80%')
              .height(28)
              .scrollable(ScrollDirection.Horizontal)
              .scrollBar(BarState.Off)
              .padding(6)
              .backgroundColor('rgba(255, 255, 255, 0.1)')
              .borderRadius(8)
              .margin({ bottom: 4 })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .translate({ y: this.isWordCourse() ? 8 : 0 })

            // 手表端仅单键 ArcButton
            ArcButton({
              options: new ArcButtonOptions({
                label: '·',
                position: ArcButtonPosition.BOTTOM_EDGE,
                styleMode: ArcButtonStyleMode.CUSTOM,
                backgroundColor: ColorMetrics.resourceColor('#FFD700'),
                fontColor: ColorMetrics.resourceColor('#000000')
              })
            })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.handleSingleButtonPress()
              } else if (event.type === TouchType.Up) {
                this.handleSingleButtonRelease()
              }
            })
            .margin({ top: 4, bottom: 0 })
          }
          .width(this.isWordCourse() ? '96%' : '80%')
          .layoutWeight(1)
          .height('100%')
        } else {
          // 课程完成：完成信息居中，返回 ArcButton 贴合底边
          Column() {
            Column() {
              Text(LocalizationHelper.getString('watch_completed'))
                .fontSize(28)
                .fontColor('#4CAF50')
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 8 })

              Text(this.currentLessonGroup.join(' '))
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)

            ArcButton({
              options: new ArcButtonOptions({
                label: LocalizationHelper.getString('watch_back'),
                position: ArcButtonPosition.BOTTOM_EDGE,
                styleMode: ArcButtonStyleMode.CUSTOM,
                backgroundColor: ColorMetrics.resourceColor('#222222'),
                fontColor: ColorMetrics.resourceColor('#FFFFFF'),
                onClick: () => {
                  console.info('[LessonDetailPage] Completion ArcButton back clicked')
                  router.back()
                }
              })
            })
              .margin({ top: 4, bottom: 0 })
          }
          .width('80%')
          .layoutWeight(1)
          .height('100%')
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 4, bottom: 0, left: 12, right: 12 })
      .backgroundColor('#000000')
      .focusable(true)
      .defaultFocus(true)

      if (this.showProgressToast && !this.showGuideDialog) {
        Row() {
          Text(this.progressToastText)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .padding({ left: 16, right: 16, top: 7, bottom: 7 })
            .backgroundColor('rgba(64, 64, 64, 0.78)')
            .borderRadius(18)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .position({ x: 0, y: 52 })
      }

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
