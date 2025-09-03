import { preferences } from '@kit.ArkData'
import Context from '@ohos.app.ability.common'
import { LessonConfig } from '../data/LessonConfig'

export interface ProgressTarget {
  unitIdx: number
  lessonIdx: number | null
}

type UnitId = 'intro' | 'alphabet' | 'numbers' | 'punctuation' | 'words'
const UNITS: UnitId[] = ['intro', 'alphabet', 'numbers', 'punctuation', 'words']

const PREFS_NAME = 'learn_progress'
const KEY_UNLOCKED = 'unlocked_lessons'
const KEY_COMPLETED = 'completed_lessons'



export class ProgressStore {
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
    console.error(`[STORE] persist: saving completedArray=[${completedArray.join(',')}] as json="${jsonString}"`)
    await prefs.put(KEY_COMPLETED, jsonString)
    await prefs.flush()
    console.error(`[STORE] persist: save completed`)
  }

  private parseSet(raw: string): Set<number> {
    try {
      console.error(`[STORE] parseSet: input="${raw}"`)
      const arr = JSON.parse(raw) as number[]
      console.error(`[STORE] parseSet: parsed array=[${arr.join(',')}]`)
      const filtered = arr.filter(n => Number.isInteger(n) && n > 0)
      console.error(`[STORE] parseSet: filtered=[${filtered.join(',')}]`)
      const result = new Set(filtered)
      console.error(`[STORE] parseSet: result set=[${Array.from(result).join(',')}]`)
      return result
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
    console.error('[STORE] load: begin')
    const prefs = await this.getPrefs(context)

    const completedRaw = await prefs.get(KEY_COMPLETED, '[]')
    console.error(`[STORE] load: raw data=${completedRaw}`)
    this.completedLessons = this.parseSet(completedRaw as string)

    const completedArray = Array.from(this.completedLessons)
    console.error(`[STORE] load: completed=${completedArray.join(',')}`)
  }

  // ───────────────────────────────── mutations ───────────────────────────────
  async saveLessonCompleted(lessonId: string, context: Context): Promise<void> {
    const n = LessonConfig.getLessonNumber(lessonId)
    console.error(`[STORE] saveLessonCompleted: ${lessonId} -> #${n}`)
    if (n <= 0) {
      console.error(`[STORE] saveLessonCompleted: invalid lesson number ${n} for lessonId ${lessonId}`)
      return
    }
    console.error(`[STORE] saveLessonCompleted: before markLessonCompleted, completedLessons=[${Array.from(this.completedLessons).join(',')}]`)
    this.markLessonCompleted(n)
    console.error(`[STORE] saveLessonCompleted: after markLessonCompleted, completedLessons=[${Array.from(this.completedLessons).join(',')}]`)
    await this.persist(context)
    console.error(`[STORE] saveLessonCompleted: after persist, completedLessons=[${Array.from(this.completedLessons).join(',')}]`)
  }

  // ───────────────────────────────── queries ────────────────────────────────
  isLessonUnlocked(n: number): boolean {
    // First lesson is always unlocked
    if (n === 1) return true
    
    // A lesson is unlocked if the previous lesson is completed
    const prevLessonCompleted = this.completedLessons.has(n - 1)
    console.error(`[STORE] isLessonUnlocked: lesson=${n}, prevLesson=${n-1}, prevCompleted=${prevLessonCompleted}, completedSet=${Array.from(this.completedLessons).join(',')}`)
    return prevLessonCompleted
  }

  isLessonCompleted(n: number): boolean {
    return this.completedLessons.has(n)
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
   * 计算当前学习目标：定位到第一个\n   * “已解锁但未完成”的课程所在的单元及其索引。
   */
  computeTarget(): ProgressTarget {
    let target = 0
    const total = LessonConfig.getTotalLessons()
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