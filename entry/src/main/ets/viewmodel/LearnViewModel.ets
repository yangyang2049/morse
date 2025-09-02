import { preferences } from '@kit.ArkData'
import { LessonData } from '../data/LessonData'

@Observed
export class LearnViewModel {
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
    await this.loadUnlockState()
  }

  async loadUnlockState(): Promise<void> {
    try {
      const dataPreferences = await preferences.getPreferences(getContext(), 'learn_progress')
      
      // 加载基础课程完成状态
      this.introCompleted = await dataPreferences.get('intro_completed', false) as boolean
      this.chineseCompleted = await dataPreferences.get('chinese_completed', false) as boolean
      this.introTestCompleted = await dataPreferences.get('intro_test_completed', false) as boolean
      this.chineseTestCompleted = await dataPreferences.get('chinese_test_completed', false) as boolean

      // 加载字母课程完成状态
      for (let i = 0; i < 9; i++) {
        const lessonId = `alphabet_lesson_${i}`
        this.alphabetLessonsCompleted.set(lessonId, await dataPreferences.get(`${lessonId}_completed`, false) as boolean)
      }

      // 加载数字课程完成状态
      for (let i = 0; i < 4; i++) {
        const lessonId = `number_lesson_${i}`
        this.numberLessonsCompleted.set(lessonId, await dataPreferences.get(`${lessonId}_completed`, false) as boolean)
      }

      // 加载符号课程完成状态
      for (let i = 0; i < 3; i++) {
        const lessonId = `punctuation_lesson_${i}`
        this.punctuationLessonsCompleted.set(lessonId, await dataPreferences.get(`${lessonId}_completed`, false) as boolean)
      }

      // 加载单词课程完成状态
      for (let i = 0; i < 3; i++) {
        const lessonId = `word_lesson_${i}`
        this.wordLessonsCompleted.set(lessonId, await dataPreferences.get(`${lessonId}_completed`, false) as boolean)
      }

      // 检查各单元的完成状态
      const isIntroUnitCompleted = this.introCompleted &&
        this.chineseCompleted &&
        this.introTestCompleted &&
        this.chineseTestCompleted

      const isAlphabetUnitCompleted = Array.from(this.alphabetLessonsCompleted.values()).every(completed => completed)
      const isNumberUnitCompleted = Array.from(this.numberLessonsCompleted.values()).every(completed => completed)

      // 单元解锁逻辑：当前单元完成后解锁下一单元
      this.unitUnlocked.set('alphabet', isIntroUnitCompleted)
      this.unitUnlocked.set('numbers', isAlphabetUnitCompleted)
      // 数字单元完成后同时解锁符号和单词单元
      this.unitUnlocked.set('punctuation', isNumberUnitCompleted)
      this.unitUnlocked.set('words', isNumberUnitCompleted)

      // 计算目标单元和课次
      this.computeTargetUnitAndLesson()

    } catch (error) {
      console.error('加载学习进度失败:', error)
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
      const dataPreferences = await preferences.getPreferences(getContext(), 'learn_progress')
      await dataPreferences.put(`${lessonId}_completed`, true)
      await dataPreferences.flush()
      
      // 更新内存状态
      if (lessonId.startsWith('alphabet_')) {
        this.alphabetLessonsCompleted.set(lessonId, true)
      } else if (lessonId.startsWith('number_')) {
        this.numberLessonsCompleted.set(lessonId, true)
      } else if (lessonId.startsWith('punctuation_')) {
        this.punctuationLessonsCompleted.set(lessonId, true)
      } else if (lessonId.startsWith('word_')) {
        this.wordLessonsCompleted.set(lessonId, true)
      }
      
      // 重新计算解锁状态
      await this.loadUnlockState()
    } catch (error) {
      console.error('保存课程完成状态失败:', error)
    }
  }

  async markTestCompleted(testKey: string): Promise<void> {
    try {
      const dataPreferences = await preferences.getPreferences(getContext(), 'learn_progress')
      await dataPreferences.put(testKey, true)
      await dataPreferences.flush()
      
      // 更新内存状态
      if (testKey === 'intro_test_completed') {
        this.introTestCompleted = true
      } else if (testKey === 'chinese_test_completed') {
        this.chineseTestCompleted = true
      }
      
      // 重新计算解锁状态
      await this.loadUnlockState()
    } catch (error) {
      console.error('保存测试完成状态失败:', error)
    }
  }

  async markLessonContentCompleted(lessonKey: string): Promise<void> {
    try {
      const dataPreferences = await preferences.getPreferences(getContext(), 'learn_progress')
      await dataPreferences.put(lessonKey, true)
      await dataPreferences.flush()
      
      // 更新内存状态
      if (lessonKey === 'intro_completed') {
        this.introCompleted = true
      } else if (lessonKey === 'chinese_completed') {
        this.chineseCompleted = true
      }
      
      // 重新计算解锁状态
      await this.loadUnlockState()
    } catch (error) {
      console.error('保存课程内容完成状态失败:', error)
    }
  }
}
