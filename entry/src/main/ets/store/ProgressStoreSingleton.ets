import { preferences } from '@kit.ArkData'
import Context from '@ohos.app.ability.common'
import { LessonConfig } from '../data/LessonConfig'
import { eventHub, Events, LessonCompletedEventData } from '../utils/EventHub'

export interface ProgressTarget {
  unitIdx: number
  lessonIdx: number | null
}

type UnitId = 'intro' | 'alphabet' | 'numbers' | 'punctuation' | 'words'
const UNITS: UnitId[] = ['intro', 'alphabet', 'numbers', 'punctuation', 'words']

const PREFS_NAME = 'learn_progress'
const KEY_COMPLETED = 'completed_lessons'

class ProgressStore {
  /** 已完成课程编号集合（1-based） */
  completedLessons: Set<number> = new Set()

  // ───────────────────────────────── helpers ─────────────────────────────────
  private async getPrefs(context: Context) {
    return preferences.getPreferences(context, PREFS_NAME)
  }

  private async persist(context: Context) {
    const prefs = await this.getPrefs(context)
    const completedArray: number[] = Array.from(this.completedLessons)
    const jsonString = JSON.stringify(completedArray)
    await prefs.put(KEY_COMPLETED, jsonString)
    await prefs.flush()
  }

  private parseSet(raw: string): Set<number> {
    try {
      const arr = JSON.parse(raw) as number[]
      const filtered = arr.filter(n => Number.isInteger(n) && n > 0)
      return new Set(filtered)
    } catch (error) {
      console.error(`[STORE] parseSet: error parsing "${raw}":`, error)
      return new Set()
    }
  }

  private markLessonCompleted(lessonNumber: number) {
    if (lessonNumber <= 0) return
    this.completedLessons.add(lessonNumber)
  }

  // ───────────────────────────────── lifecycle ───────────────────────────────
  async load(context: Context): Promise<void> {
    const prefs = await this.getPrefs(context)
    const completedRaw = await prefs.get(KEY_COMPLETED, '[]')
    this.completedLessons = this.parseSet(completedRaw as string)
    console.error(`[STORE] load: loaded completedLessons=${Array.from(this.completedLessons).join(',')}`)
  }

  // ───────────────────────────────── mutations ───────────────────────────────
  async saveLessonCompleted(lessonNumber: number, context: Context): Promise<void> {
    if (lessonNumber <= 0) {
      console.error(`[STORE] saveLessonCompleted: invalid lesson number ${lessonNumber}`)
      return
    }
    
    // 直接标记课程完成，不需要重新加载
    this.markLessonCompleted(lessonNumber)
    await this.persist(context)
    console.log(`[STORE] Lesson ${lessonNumber} completed and saved. Total completed: ${Array.from(this.completedLessons).join(',')}`)
    
    // 发送课程完成事件
    const eventData: LessonCompletedEventData = {
      lessonNumber: lessonNumber,
      completedLessons: Array.from(this.completedLessons),
      unitUnlocked: this.getUnitUnlocked()
    }
    console.error(`[STORE] saveLessonCompleted: sending event with completedLessons=${Array.from(this.completedLessons).join(',')}`)
    eventHub.emit(Events.LESSON_COMPLETED, eventData)
  }

  // ───────────────────────────────── queries ────────────────────────────────
  isLessonUnlocked(n: number): boolean {
    // First lesson is always unlocked
    if (n === 1) return true
    
    // A lesson is unlocked if the previous lesson is completed
    const prevLessonCompleted = this.completedLessons.has(n - 1)
    console.error(`[STORE] isLessonUnlocked: lesson${n} unlocked=${prevLessonCompleted} (prev lesson ${n-1} completed=${prevLessonCompleted})`)
    return prevLessonCompleted
  }

  isLessonCompleted(n: number): boolean {
    const completed = this.completedLessons.has(n)
    console.error(`[STORE] isLessonCompleted: lesson${n} completed=${completed}`)
    return completed
  }

  /**
   * 返回每个单元是否解锁（由该单元起始课程是否解锁决定）
   */
  getUnitUnlocked(): Map<UnitId, boolean> {
    const map = new Map<UnitId, boolean>()
    for (const u of UNITS) {
      const start = LessonConfig.getUnitStartLesson(u)
      map.set(u, this.isLessonUnlocked(start))
    }
    return map
  }

  /**
   * 计算当前学习目标：定位到第一个
   * "已解锁但未完成"的课程所在的单元及其索引。
   */
  computeTarget(): ProgressTarget {
    let target = 0
    const total = LessonConfig.getTotalLessonsForLanguage()
    for (let i = 1; i <= total; i++) {
      if (this.isLessonUnlocked(i) && !this.isLessonCompleted(i)) { target = i; break }
    }
    if (target === 0) target = total

    // 找到所属单元及索引
    let unitIdx = 0
    let lessonIdx: number | null = null

    for (let idx = 0; idx < UNITS.length; idx++) {
      const u = UNITS[idx]
      if (LessonConfig.isLessonInUnit(target, u)) {
        unitIdx = idx
        const start = LessonConfig.getUnitStartLesson(u)
        lessonIdx = target - start
        break
      }
    }

    return { unitIdx, lessonIdx }
  }
}

// 单例实例
export const progressStore = new ProgressStore()



