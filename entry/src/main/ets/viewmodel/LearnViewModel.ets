import { LessonData } from '../data/LessonData'
import { ProgressStore } from '../store/ProgressStore'

@Observed
export class LearnViewModel {
  private store: ProgressStore = new ProgressStore()
  // 单元解锁状态
  unitUnlocked: Map<string, boolean> = new Map([
    ['intro', true],
    ['alphabet', false],
    ['numbers', false],
    ['punctuation', false],
    ['words', false]
  ])

  // 基础课程完成状态
  introCompleted: boolean = false
  chineseCompleted: boolean = false
  introTestCompleted: boolean = false
  chineseTestCompleted: boolean = false

  // 字母课程完成状态
  alphabetLessonsCompleted: Map<string, boolean> = new Map()
  // 数字课程完成状态
  numberLessonsCompleted: Map<string, boolean> = new Map()
  // 符号课程完成状态
  punctuationLessonsCompleted: Map<string, boolean> = new Map()
  // 单词课程完成状态
  wordLessonsCompleted: Map<string, boolean> = new Map()

  // 目标单元和课程索引
  targetUnitIdx: number = 0
  targetLessonIdx: number | null = null

  async init(): Promise<void> {
    console.error('[VM] init() called')
    await this.loadUnlockState()
  }

  async loadUnlockState(): Promise<void> {
    try {
      console.error('[VM] loadUnlockState: start load from store')
      // Load from store and sync to view model state
      await this.store.load()

      this.introCompleted = this.store.introCompleted
      this.chineseCompleted = this.store.chineseCompleted
      this.introTestCompleted = this.store.introTestCompleted
      this.chineseTestCompleted = this.store.chineseTestCompleted

      this.alphabetLessonsCompleted = new Map(this.store.alphabetLessonsCompleted)
      this.numberLessonsCompleted = new Map(this.store.numberLessonsCompleted)
      this.punctuationLessonsCompleted = new Map(this.store.punctuationLessonsCompleted)
      this.wordLessonsCompleted = new Map(this.store.wordLessonsCompleted)

      this.unitUnlocked = this.store.getUnitUnlocked()

      // 计算目标单元和课次
      this.computeTargetUnitAndLesson()
      console.error(`[VM] loadUnlockState: flags introCompleted=${this.introCompleted} introTestCompleted=${this.introTestCompleted} chineseCompleted=${this.chineseCompleted} chineseTestCompleted=${this.chineseTestCompleted}`)
      console.error(`[VM] loadUnlockState: unitUnlocked intro=${this.unitUnlocked.get('intro')} alphabet=${this.unitUnlocked.get('alphabet')} numbers=${this.unitUnlocked.get('numbers')} punctuation=${this.unitUnlocked.get('punctuation')} words=${this.unitUnlocked.get('words')}`)

    } catch (error) {
      console.error('[VM] loadUnlockState FAILED:', error)
    }
  }

  computeTargetUnitIndex(): number {
    // 单元顺序: 0 基础(两课), 1 字母, 2 数字, 3 符号, 4 单词
    // 如果基础未完成或测试未通过，停留在基础单元
    if (!this.introCompleted ||
        !this.introTestCompleted ||
        !this.chineseCompleted ||
        !this.chineseTestCompleted) {
      return 0
    }

    // 如果字母单元未解锁或未完成，跳到字母单元
    if (!this.unitUnlocked.get('numbers')) {
      return 1
    }

    // 如果数字单元未解锁或未完成，跳到数字单元
    if (!this.unitUnlocked.get('punctuation') || !this.unitUnlocked.get('words')) {
      return 2
    }

    // 数字完成后，符号和单词都解锁，优先跳到符号单元
    const isPunctuationCompleted = Array.from(this.punctuationLessonsCompleted.values()).every(completed => completed)
    const isWordCompleted = Array.from(this.wordLessonsCompleted.values()).every(completed => completed)

    if (!isPunctuationCompleted) {
      return 3 // 符号单元
    } else if (!isWordCompleted) {
      return 4 // 单词单元
    }

    // 都完成了，停留在单词单元
    return 4
  }

  computeTargetUnitAndLesson(): void {
    const unitIdx = this.computeTargetUnitIndex()
    let lessonIdx: number | null = null

    if (unitIdx === 0) {
      // 基础单元：两课，按测验通过情况定位
      if (!this.introTestCompleted) {
        lessonIdx = 0
      } else if (!this.chineseTestCompleted) {
        lessonIdx = 1
      }
    } else if (unitIdx === 1) {
      // 字母：9课，定位到第一节未完成
      for (let i = 0; i < 9; i++) {
        if (!(this.alphabetLessonsCompleted.get(`alphabet_lesson_${i}`) ?? false)) {
          lessonIdx = i
          break
        }
      }
    } else if (unitIdx === 2) {
      // 数字：4课
      for (let i = 0; i < 4; i++) {
        if (!(this.numberLessonsCompleted.get(`number_lesson_${i}`) ?? false)) {
          lessonIdx = i
          break
        }
      }
    } else if (unitIdx === 3) {
      // 符号：3课
      for (let i = 0; i < 3; i++) {
        if (!(this.punctuationLessonsCompleted.get(`punctuation_lesson_${i}`) ?? false)) {
          lessonIdx = i
          break
        }
      }
    } else if (unitIdx === 4) {
      // 单词：3课
      for (let i = 0; i < 3; i++) {
        if (!(this.wordLessonsCompleted.get(`word_lesson_${i}`) ?? false)) {
          lessonIdx = i
          break
        }
      }
    }

    this.targetUnitIdx = unitIdx
    this.targetLessonIdx = lessonIdx
  }

  async markLessonCompleted(lessonId: string): Promise<void> {
    try {
      console.error(`[VM] markLessonCompleted: ${lessonId}`)
      await this.store.saveLessonCompleted(lessonId)
      await this.loadUnlockState()
    } catch (error) {
      console.error('[VM] markLessonCompleted FAILED:', error)
    }
  }

  async markTestCompleted(testKey: string): Promise<void> {
    try {
      console.error(`[VM] markTestCompleted: ${testKey}`)
      await this.store.saveTestCompleted(testKey)
      await this.loadUnlockState()
    } catch (error) {
      console.error('[VM] markTestCompleted FAILED:', error)
    }
  }

  async markLessonContentCompleted(lessonKey: string): Promise<void> {
    try {
      console.error(`[VM] markLessonContentCompleted: ${lessonKey}`)
      await this.store.saveLessonContentCompleted(lessonKey)
      await this.loadUnlockState()
    } catch (error) {
      console.error('[VM] markLessonContentCompleted FAILED:', error)
    }
  }
}
