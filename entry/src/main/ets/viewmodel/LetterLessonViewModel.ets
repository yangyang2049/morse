import { MorseCode } from '../models/MorseCode'
import { audioService } from '../services/AudioService'
import Context from '@ohos.app.ability.common'
import { vibratorService } from '../services/VibratorService'
import { CourseCatalogV2 } from '../data/CourseCatalogV2'
import { learningRepositoryV2 } from '../repository/LearningRepositoryV2'

@Observed
export class LetterLessonViewModel {
  // 课程数据
  @Track codes: MorseCode[] = []
  @Track lessonId: string = ''
  @Track title: string = ''

  // 学习状态
  @Track currentIndex: number = 0
  @Track userInput: string = ''
  @Track showResult: boolean = false
  @Track isCorrect: boolean = false
  @Track showMorseCode: boolean = true
  @Track completionCount: Map<number, number> = new Map()
  @Track practiceCount: Map<number, number> = new Map()
  @Track hintRevealed: Map<number, boolean> = new Map()

  // 进度相关
  @Track progressVisual: number = 0
  @Track showCompletedColor: boolean = false
  @Track REQUIRED_PRACTICE_COUNT: number = 3

  // 设置项
  @Track soundEnabled: boolean = true

  // 对话框状态
  @Track showCompletionDialog: boolean = false
  isLessonCompleted: boolean = false

  // 复习模式状态
  @Track isReviewMode: boolean = false // 复习模式：所有练习完成后显示提示
  @Track reviewIndex: number = 0 // 复习模式中的当前索引

  // 内部状态
  private autoCheckTimer: number | null = null
  private progressTimer: number | null = null
  private context: Context | null = null

  async init(context: Context, lessonId: string, title: string, codes: MorseCode[], repetitionCount: number): Promise<void> {
    this.lessonId = lessonId
    this.title = title
    this.codes = codes
    this.context = context
    this.REQUIRED_PRACTICE_COUNT = this.isReviewLesson() ? 1 : Math.max(1, Math.min(5, repetitionCount))

    // 复习课程默认隐藏提示
    if (this.isReviewLesson()) {
      this.showMorseCode = false
    }
  }

  // 输入操作
  addDot(): void {
    // 输入时振动反馈：点短振
    void vibratorService.vibrateDit()
    this.userInput = this.userInput + '.'
    this.showResult = false
    this.startAutoCheck()
  }

  addDash(): void {
    // 输入时振动反馈：划长振
    void vibratorService.vibrateDah()
    this.userInput = this.userInput + '-'
    this.showResult = false
    this.startAutoCheck()
  }

  addSpace(): void {
    // 防止首位或连续空格
    if (this.userInput.length === 0) {
      return
    }
    if (this.userInput.endsWith(' ')) {
      return
    }
    this.userInput = this.userInput + ' '
    this.showResult = false
    this.startAutoCheck()
  }

  // 播放当前字母的摩尔斯码音频
  async playCurrentMorseCode(): Promise<void> {
    const currentCode = this.codes[this.currentIndex]
    if (currentCode && currentCode.morse) {
      try {
        await audioService.playMorseSequence(currentCode.morse)
      } catch (error) {
        console.error('Failed to play morse code audio:', error)
      }
    }
  }

  // 播放用户输入的摩尔斯码音频
  async playUserInput(): Promise<void> {
    if (this.userInput.trim().length > 0) {
      try {
        await audioService.playMorseSequence(this.userInput)
      } catch (error) {
        console.error('Failed to play user input audio:', error)
      }
    }
  }

  clearInput(): void {
    this.userInput = ''
    this.showResult = false
    this.isCorrect = false
    if (this.autoCheckTimer !== null) {
      clearTimeout(this.autoCheckTimer)
      this.autoCheckTimer = null
    }
  }

  private startAutoCheck(): void {
    if (this.autoCheckTimer !== null) {
      clearTimeout(this.autoCheckTimer)
      this.autoCheckTimer = null
    }

    // 单词课程使用更长的检查时间
    const isWordLesson = CourseCatalogV2.get(this.lessonId)?.unitId === 'words'
    const checkDelay = isWordLesson ? 1800 : 800

    this.autoCheckTimer = setTimeout(() => {
      this.autoCheckTimer = null
      this.checkAnswer()
    }, checkDelay)
  }

  private checkAnswer(): void {
    const currentCode = this.codes[this.currentIndex]
    const isWordLesson = CourseCatalogV2.get(this.lessonId)?.unitId === 'words'
    const userNormalized = this.normalizeMorseForComparison(this.userInput, !!isWordLesson)
    const answerNormalized = this.normalizeMorseForComparison(currentCode.morse, !!isWordLesson)
    const isCorrect = userNormalized === answerNormalized

    void learningRepositoryV2.recordAttempt(this.lessonId, currentCode.character, isCorrect)

    this.isCorrect = isCorrect
    this.showResult = true

    if (this.isReviewMode) {
      // 复习模式：隐藏提示，只需要一次正确输入
      if (isCorrect) {
        // 课程模式：输入时已有振动，不需要额外答题振动
        // 正确输入，继续下一个
        setTimeout(() => {
          this.moveToNext()
        }, 1000)
      } else {
        // 课程模式：输入时已有振动，不需要额外答题振动
        // 错误输入，清除输入重新尝试，但不显示提示
        this.showMorseCode = false // 确保隐藏提示
        setTimeout(() => {
          this.clearInput()
        }, 1500)
      }
    } else {
      // 正常练习模式
      const isReviewLesson = this.isReviewLesson()
      if (isCorrect) {
        // 课程模式：输入时已有振动，不需要额外答题振动
        if (isReviewLesson) {
          // 复习课程：只需要一次正确输入
          const nextCompletion = new Map(this.completionCount)
          nextCompletion.set(this.currentIndex, 1)
          this.completionCount = nextCompletion
          this.animateProgressTo(1, 320, () => {
            this.showCompletedColor = true
          })
          setTimeout(() => {
            this.moveToNext()
          }, 1000)
        } else {
          // 普通课程：需要多次练习
          const currentPracticeCount = this.practiceCount.get(this.currentIndex) || 0
          const newCount = currentPracticeCount + 1
          const nextPractice = new Map(this.practiceCount)
          nextPractice.set(this.currentIndex, newCount)
          this.practiceCount = nextPractice

          const targetProgress = Math.min(newCount / this.REQUIRED_PRACTICE_COUNT, 1)
          if (newCount >= this.REQUIRED_PRACTICE_COUNT) {
            this.animateProgressTo(targetProgress, 320, () => {
              this.showCompletedColor = true
            })
          } else {
            this.showCompletedColor = false
            this.animateProgressTo(targetProgress, 320)
          }

          if (newCount >= this.REQUIRED_PRACTICE_COUNT) {
            const nextCompletion = new Map(this.completionCount)
            nextCompletion.set(this.currentIndex, 1)
            this.completionCount = nextCompletion
            setTimeout(() => {
              this.moveToNext()
            }, 1000)
          } else {
            setTimeout(() => {
              this.clearInput()
            }, 1000)
          }
        }
      } else {
        // 课程模式：输入时已有振动，不需要额外答题振动
        setTimeout(() => {
          this.clearInput()
        }, 1500)
      }
    }
  }

  private normalizeMorseForComparison(input: string, isWordLesson: boolean): string {
    // 统一点划字符并标准化空格
    let s: string = input.replace(/·/g, '.').replace(/[–—]/g, '-')
    if (isWordLesson) {
      // 单词课：忽略所有空格，仅对比点划序列
      s = s.replace(/\s+/g, '')
    } else {
      s = s.trim()
    }
    return s
  }

  private moveToNext(): void {
    if (this.isReviewMode) {
      // 复习模式：按顺序显示所有字符
      if (this.reviewIndex < this.codes.length - 1) {
        this.reviewIndex++
        this.currentIndex = this.reviewIndex
        this.showMorseCode = false // 隐藏提示，准备下一个字符
        this.clearInput()
      } else {
        // 复习模式完成，显示完成对话框
        this.markLessonCompletedImmediately()
        this.showCompletionDialog = true
      }
    } else {
      // 正常练习模式
      if (this.currentIndex < this.codes.length - 1) {
        this.currentIndex++
        const nextCount = this.practiceCount.get(this.currentIndex) || 0
        this.progressVisual = Math.min(nextCount / this.REQUIRED_PRACTICE_COUNT, 1)
        this.showCompletedColor = false
        // 移动到下一个字符时重置提示显示
        if (this.isReviewLesson()) {
          this.showMorseCode = false // 复习课程默认隐藏提示
        }
        this.clearInput()
      } else {
        void this.markLessonCompletedImmediately()
        this.showCompletionDialog = true
      }
    }
  }

  private async markLessonCompletedImmediately(): Promise<void> {
    if (this.lessonId && !this.isLessonCompleted && this.context) {
      try {
        await learningRepositoryV2.completeCourse(this.lessonId)
        this.isLessonCompleted = true
        console.error(`[LetterLessonViewModel] Completed courseId=${this.lessonId}`)
      } catch (error) {
        console.error(`[LetterLessonViewModel] markLessonCompletedImmediately: Error: ${error}`)
      }
    } else {
      console.error(`[LetterLessonViewModel] markLessonCompletedImmediately: Cannot complete - lessonId=${this.lessonId}, isLessonCompleted=${this.isLessonCompleted}, context=${!!this.context}`)
    }
  }

  async markLessonCompleted(context: Context): Promise<void> {
    if (this.lessonId && !this.isLessonCompleted) {
      try {
        await learningRepositoryV2.completeCourse(this.lessonId)
        this.isLessonCompleted = true
        console.error(`[LetterLessonViewModel] Completed courseId=${this.lessonId}`)
      } catch (error) {
        console.error(`[LetterLessonViewModel] markLessonCompleted: Error: ${error}`)
      }
    }
  }

  // 对话框操作
  closeCompletionDialog(): void {
    this.showCompletionDialog = false
  }

  // 重新开始课程
  restartLesson(): void {
    this.currentIndex = 0
    this.reviewIndex = 0
    this.isReviewMode = false
    this.userInput = ''
    this.showResult = false
    this.isCorrect = false
    this.showMorseCode = true
    this.showCompletedColor = false
    this.progressVisual = 0
    this.completionCount = new Map()
    this.practiceCount = new Map()
    this.hintRevealed = new Map()
  }


  // 进度动画
  private animateProgressTo(target: number, duration: number = 320, onComplete?: () => void) {
    if (this.progressTimer !== null) {
      clearInterval(this.progressTimer)
      this.progressTimer = null
    }

    const start = this.progressVisual
    const delta = target - start
    if (Math.abs(delta) < 1e-4 || duration <= 0) {
      this.progressVisual = target
      return
    }

    const startTs = Date.now()
    const easeInOutCubic = (t: number) => t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2

    this.progressTimer = setInterval(() => {
      const t = Math.min(1, (Date.now() - startTs) / duration)
      this.progressVisual = start + delta * easeInOutCubic(t)
      if (t >= 1) {
        if (this.progressTimer !== null) {
          clearInterval(this.progressTimer)
          this.progressTimer = null
        }
        this.progressVisual = target
        if (onComplete) {
          onComplete()
        }
      }
    }, 16)
  }

  // 工具方法
  isReviewLesson(): boolean {
    return CourseCatalogV2.get(this.lessonId)?.kind === 'review'
  }

  shouldShowHint(index: number): boolean {
    // 所有课程都允许通过点击来显示提示
    return this.showMorseCode
  }

  getProgressColor(): ResourceColor {
    return this.showCompletedColor ? Color.Green : '#FFD700'
  }

  getCircumference(): number {
    // 与 ProgressCircle 的 Circle 220x220 一致，半径为 110
    return 2 * Math.PI * 110
  }

  getProgressVisualLength(): number {
    return this.getCircumference() * Math.max(0, Math.min(this.progressVisual, 1))
  }

  getLetterStatusColor(index: number): ResourceColor {
    const isReviewLesson = this.isReviewLesson()
    const isActive = index === this.currentIndex

    if (isReviewLesson) {
      // 复习课程：基于completionCount判断是否完成
      const isCompleted = this.completionCount.get(index) === 1
      if (isCompleted) {
        return Color.Green
      } else if (isActive) {
        return '#FFD700'
      } else {
        return Color.White
      }
    } else {
      // 普通课程：基于practiceCount判断是否完成
      const currentPracticeCount = this.practiceCount.get(index) || 0
      const isCompleted = currentPracticeCount >= this.REQUIRED_PRACTICE_COUNT
      if (isCompleted) {
        return Color.Green
      } else if (isActive) {
        return '#FFD700'
      } else {
        return Color.White
      }
    }
  }

  // 清理资源
  destroy(): void {
    if (this.autoCheckTimer !== null) {
      clearTimeout(this.autoCheckTimer)
      this.autoCheckTimer = null
    }
    if (this.progressTimer !== null) {
      clearInterval(this.progressTimer)
      this.progressTimer = null
    }
  }
}
