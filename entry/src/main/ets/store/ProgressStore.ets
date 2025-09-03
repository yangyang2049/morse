import { preferences } from '@kit.ArkData'
import { LessonConfig } from '../data/LessonConfig'
import { FORCE_UNLOCK_ALL } from '../data/FeatureFlags'
import Context from '@ohos.app.ability.common'

export interface ProgressTarget {
  unitIdx: number
  lessonIdx: number | null
}

export class ProgressStore {
  // 简化的解锁系统：只存储已解锁的课程编号
  unlockedLessons: Set<number> = new Set() // 临时解锁所有课程

  // 课程完成状态
  completedLessons: Set<number> = new Set()

  async load(context: Context): Promise<void> {
    console.error('[STORE] load: begin')
    const prefs = await preferences.getPreferences(context, 'learn_progress')

    if (FORCE_UNLOCK_ALL) {
      // 临时强制解锁所有课程（由特性开关控制）
      console.error('[STORE] load: FORCE_UNLOCK_ALL=true, unlocking all lessons')
      for (let i = 1; i <= LessonConfig.getTotalLessons(); i++) {
        this.unlockedLessons.add(i)
      }
      console.error(`[STORE] load: unlocked all lessons: ${Array.from(this.unlockedLessons).join(',')}`)
    } else {
      // 正常加载已解锁的课程编号
      const unlockedArray = await prefs.get('unlocked_lessons', '[]') as string
      console.error(`[STORE] load: unlockedArray from prefs = "${unlockedArray}"`)
      try {
        const unlockedNumbers = JSON.parse(unlockedArray) as number[]
        this.unlockedLessons = new Set(unlockedNumbers)
        console.error(`[STORE] load: loaded from prefs, unlocked lessons: ${Array.from(this.unlockedLessons).join(',')}`)
      } catch {
        // 若解析失败，至少解锁第一课
        console.error('[STORE] load: failed to parse prefs, unlocking lesson 1 as fallback')
        this.unlockedLessons = new Set([1])
      }
    }

    // 加载已完成的课程编号
    const completedArray = await prefs.get('completed_lessons', '[]') as string
    try {
      const completedNumbers = JSON.parse(completedArray) as number[]
      this.completedLessons = new Set(completedNumbers)
    } catch {
      this.completedLessons = new Set()
    }

    console.error(`[STORE] load: unlocked=${Array.from(this.unlockedLessons).join(',')} completed=${Array.from(this.completedLessons).join(',')}`)
  }

  async saveLessonCompleted(lessonId: string, context: Context): Promise<void> {
    console.error(`[STORE] saveLessonCompleted: ${lessonId}`)
    const lessonNumber = LessonConfig.getLessonNumber(lessonId)
    if (lessonNumber === 0) return

    // 标记课程为已完成
    this.completedLessons.add(lessonNumber)
    
    // 解锁下一课
    const nextLessonNumber = lessonNumber + 1
    if (nextLessonNumber <= LessonConfig.getTotalLessons()) {
      this.unlockedLessons.add(nextLessonNumber)
    }

    // 保存到preferences
    const prefs = await preferences.getPreferences(context, 'learn_progress')
    await prefs.put('completed_lessons', JSON.stringify(Array.from(this.completedLessons)))
    await prefs.put('unlocked_lessons', JSON.stringify(Array.from(this.unlockedLessons)))
    await prefs.flush()

    console.error(`[STORE] lesson ${lessonNumber} completed, unlocked lessons: ${Array.from(this.unlockedLessons).join(',')}`)
  }

  async saveTestCompleted(testKey: string, context: Context): Promise<void> {
    console.error(`[STORE] saveTestCompleted: ${testKey}`)
    // 测试完成等同于课程完成，解锁下一课
    let lessonNumber = 0
    if (testKey === 'intro_test_completed') {
      lessonNumber = 1 // 第1课完成
    } else if (testKey === 'chinese_test_completed') {
      lessonNumber = 2 // 第2课完成
    }
    
    if (lessonNumber > 0) {
      // 直接调用内部逻辑，避免递归
      this.completedLessons.add(lessonNumber)
      const nextLessonNumber = lessonNumber + 1
      if (nextLessonNumber <= LessonConfig.getTotalLessons()) {
        this.unlockedLessons.add(nextLessonNumber)
      }
      
      // 保存到preferences
      const prefs = await preferences.getPreferences(context, 'learn_progress')
      await prefs.put('completed_lessons', JSON.stringify(Array.from(this.completedLessons)))
      await prefs.put('unlocked_lessons', JSON.stringify(Array.from(this.unlockedLessons)))
      await prefs.flush()
      
      console.error(`[STORE] test ${testKey} completed, lesson ${lessonNumber} completed, unlocked lessons: ${Array.from(this.unlockedLessons).join(',')}`)
    }
  }

  async saveLessonContentCompleted(lessonKey: string, context: Context): Promise<void> {
    console.error(`[STORE] saveLessonContentCompleted: ${lessonKey}`)
    // 课程内容完成等同于课程完成
    let lessonNumber = 0
    if (lessonKey === 'intro_completed') {
      lessonNumber = 1
    } else if (lessonKey === 'chinese_completed') {
      lessonNumber = 2
    }
    
    if (lessonNumber > 0) {
      // 直接调用内部逻辑，避免递归
      this.completedLessons.add(lessonNumber)
      const nextLessonNumber = lessonNumber + 1
      if (nextLessonNumber <= LessonConfig.getTotalLessons()) {
        this.unlockedLessons.add(nextLessonNumber)
      }
      
      // 保存到preferences
      const prefs = await preferences.getPreferences(context, 'learn_progress')
      await prefs.put('completed_lessons', JSON.stringify(Array.from(this.completedLessons)))
      await prefs.put('unlocked_lessons', JSON.stringify(Array.from(this.unlockedLessons)))
      await prefs.flush()
      
      console.error(`[STORE] lesson content ${lessonKey} completed, lesson ${lessonNumber} completed, unlocked lessons: ${Array.from(this.unlockedLessons).join(',')}`)
    }
  }

  // 检查课程是否已解锁
  isLessonUnlocked(lessonNumber: number): boolean {
    if (FORCE_UNLOCK_ALL) return true
    return this.unlockedLessons.has(lessonNumber)
  }

  // 检查课程是否已完成
  isLessonCompleted(lessonNumber: number): boolean {
    return this.completedLessons.has(lessonNumber)
  }

  // 检查单元是否已解锁（基于单元起始课程是否解锁）
  getUnitUnlocked(): Map<string, boolean> {
    const units = ['intro', 'alphabet', 'numbers', 'punctuation', 'words']
    if (FORCE_UNLOCK_ALL) {
      const allTrue: Map<string, boolean> = new Map()
      for (const unitId of units) { allTrue.set(unitId, true) }
      return allTrue
    }

    const unitUnlocked: Map<string, boolean> = new Map()
    for (const unitId of units) {
      const startLesson = LessonConfig.getUnitStartLesson(unitId)
      unitUnlocked.set(unitId, this.isLessonUnlocked(startLesson))
    }
    return unitUnlocked
  }

  // 计算目标位置（单元和下一课索引）
  computeTarget(): ProgressTarget {
    // 找到第一个未完成的已解锁课程
    let targetLessonNumber = 0
    for (let i = 1; i <= LessonConfig.getTotalLessons(); i++) {
      if (this.isLessonUnlocked(i) && !this.isLessonCompleted(i)) {
        targetLessonNumber = i
        break
      }
    }

    // 如果没有找到未完成的课程，返回最后一个课程
    if (targetLessonNumber === 0) {
      targetLessonNumber = LessonConfig.getTotalLessons()
    }

    // 根据课程编号确定单元索引
    let unitIdx = 0
    if (LessonConfig.isLessonInUnit(targetLessonNumber, 'intro')) {
      unitIdx = 0
    } else if (LessonConfig.isLessonInUnit(targetLessonNumber, 'alphabet')) {
      unitIdx = 1
    } else if (LessonConfig.isLessonInUnit(targetLessonNumber, 'numbers')) {
      unitIdx = 2
    } else if (LessonConfig.isLessonInUnit(targetLessonNumber, 'punctuation')) {
      unitIdx = 3
    } else if (LessonConfig.isLessonInUnit(targetLessonNumber, 'words')) {
      unitIdx = 4
    }

    // 计算课程在单元内的索引
    let lessonIdx: number | null = null
    if (unitIdx === 0) {
      lessonIdx = targetLessonNumber - 1 // 基础单元：课程1->索引0，课程2->索引1
    } else if (unitIdx === 1) {
      lessonIdx = targetLessonNumber - 3 // 字母单元：课程3->索引0
    } else if (unitIdx === 2) {
      lessonIdx = targetLessonNumber - 12 // 数字单元：课程12->索引0
    } else if (unitIdx === 3) {
      lessonIdx = targetLessonNumber - 16 // 符号单元：课程16->索引0
    } else if (unitIdx === 4) {
      lessonIdx = targetLessonNumber - 19 // 单词单元：课程19->索引0
    }

    return { unitIdx, lessonIdx }
  }

  // 解锁所有课程（用于测试或管理员功能）
  async unlockAllLessons(context: Context): Promise<void> {
    console.error('[STORE] unlockAllLessons: unlocking all lessons')
    for (let i = 1; i <= LessonConfig.getTotalLessons(); i++) {
      this.unlockedLessons.add(i)
    }
    
    // 保存到preferences
    const prefs = await preferences.getPreferences(context, 'learn_progress')
    await prefs.put('unlocked_lessons', JSON.stringify(Array.from(this.unlockedLessons)))
    await prefs.flush()
    
    console.error(`[STORE] all lessons unlocked: ${Array.from(this.unlockedLessons).join(',')}`)
  }

  // 重置进度（用于测试）
  async resetProgress(context: Context): Promise<void> {
    console.error('[STORE] resetProgress: resetting all progress')
    // 临时解锁所有课程
    this.unlockedLessons = new Set()
    for (let i = 1; i <= LessonConfig.getTotalLessons(); i++) {
      this.unlockedLessons.add(i)
    }
    this.completedLessons = new Set()
    
    // 保存到preferences
    const prefs = await preferences.getPreferences(context, 'learn_progress')
    await prefs.put('unlocked_lessons', JSON.stringify(Array.from(this.unlockedLessons)))
    await prefs.put('completed_lessons', JSON.stringify(Array.from(this.completedLessons)))
    await prefs.flush()
    
    console.error('[STORE] progress reset, all lessons unlocked')
  }
}
