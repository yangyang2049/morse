import { MorseCode } from '../models/MorseCode'
import { LearnViewModel } from './LearnViewModel'
import { globalProgressState } from '../store/GlobalProgressState'
import Context from '@ohos.app.ability.common'

@Observed
export class LetterLessonViewModel {
  // 课程数据
  codes: MorseCode[] = []
  lessonId: string = ''
  title: string = ''
  
  // 学习状态
  currentIndex: number = 0
  userInput: string = ''
  showResult: boolean = false
  isCorrect: boolean = false
  showMorseCode: boolean = true
  completionCount: Map<number, number> = new Map()
  practiceCount: Map<number, number> = new Map()
  hintRevealed: Map<number, boolean> = new Map()
  
  // 进度相关
  progressVisual: number = 0
  showCompletedColor: boolean = false
  readonly REQUIRED_PRACTICE_COUNT: number = 5
  
  // 对话框状态
  showCompletionDialog: boolean = false
  isLessonCompleted: boolean = false
  
  // 内部状态
  private autoCheckTimer: number | null = null
  private progressTimer: number | null = null
  private learnViewModel: LearnViewModel = new LearnViewModel()
  
  async init(context: Context, lessonId: string, title: string, codes: MorseCode[]): Promise<void> {
    this.lessonId = lessonId
    this.title = title
    this.codes = codes
    await this.learnViewModel.init(context)
  }
  
  // 输入操作
  addDot(): void {
    this.userInput = (this.userInput + '.').trim()
    this.showResult = false
    this.startAutoCheck()
  }
  
  addDash(): void {
    this.userInput = (this.userInput + '-').trim()
    this.showResult = false
    this.startAutoCheck()
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
    this.autoCheckTimer = setTimeout(() => {
      this.autoCheckTimer = null
      this.checkAnswer()
    }, 800)
  }
  
  private checkAnswer(): void {
    const currentCode = this.codes[this.currentIndex]
    const isCorrect = this.userInput === currentCode.morse

    this.isCorrect = isCorrect
    this.showResult = true

    if (isCorrect) {
      const currentPracticeCount = this.practiceCount.get(this.currentIndex) || 0
      const newCount = currentPracticeCount + 1
      this.practiceCount.set(this.currentIndex, newCount)
      
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
        this.completionCount.set(this.currentIndex, 1)
        setTimeout(() => {
          this.moveToNext()
        }, 1000)
      } else {
        setTimeout(() => {
          this.clearInput()
        }, 1000)
      }
    } else {
      setTimeout(() => {
        this.clearInput()
      }, 1500)
    }
  }
  
  private moveToNext(): void {
    if (this.currentIndex < this.codes.length - 1) {
      this.currentIndex++
      const nextCount = this.practiceCount.get(this.currentIndex) || 0
      this.progressVisual = Math.min(nextCount / this.REQUIRED_PRACTICE_COUNT, 1)
      this.showCompletedColor = false
      this.clearInput()
    } else {
      this.showCompletionDialog = true
    }
  }
  
  async markLessonCompleted(context: Context): Promise<void> {
    if (this.lessonId && !this.isLessonCompleted) {
      try {
        const lessonNumber = parseInt(this.lessonId) || 0
        // 使用全局状态标记课程完成
        await globalProgressState.markLessonCompleted(lessonNumber, context)
        this.isLessonCompleted = true
        
        console.error(`[LetterLessonViewModel] markLessonCompleted: Completed for lessonNumber=${lessonNumber}`)
      } catch (error) {
        console.error(`[LetterLessonViewModel] markLessonCompleted: Error: ${error}`)
      }
    }
  }
  
  // 对话框操作
  closeCompletionDialog(): void {
    this.showCompletionDialog = false
  }
  
  restartLesson(): void {
    this.currentIndex = 0
    this.completionCount.clear()
    this.practiceCount.clear()
    this.progressVisual = 0
    this.showCompletedColor = false
    this.clearInput()
    this.showCompletionDialog = false
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
  shouldShowHint(index: number): boolean {
    const isReviewLesson = this.codes.length > 10
    if (isReviewLesson) {
      return this.hintRevealed.get(index) || false
    } else {
      return this.showMorseCode
    }
  }
  
  getProgressColor(): ResourceColor {
    return this.showCompletedColor ? Color.Green : '#FFD700'
  }
  
  getCircumference(): number {
    return 2 * Math.PI * 110
  }
  
  getProgressVisualLength(): number {
    return this.getCircumference() * Math.max(0, Math.min(this.progressVisual, 1))
  }
  
  getLetterStatusColor(index: number): ResourceColor {
    const currentPracticeCount = this.practiceCount.get(index) || 0
    const isCompleted = currentPracticeCount >= this.REQUIRED_PRACTICE_COUNT
    const isActive = index === this.currentIndex
    
    if (isCompleted) {
      return Color.Green
    } else if (isActive) {
      return '#FFD700'
    } else {
      return Color.White
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
