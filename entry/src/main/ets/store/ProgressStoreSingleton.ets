import { preferences } from '@kit.ArkData'
import Context from '@ohos.app.ability.common'
import { LessonConfig } from '../data/LessonConfig'
import { LessonGroups } from '../data/LessonGroups'
import { eventHub, Events, LessonCompletedEventData } from '../utils/EventHub'
import { DeviceHelper } from '../utils/DeviceHelper'
import { recordLessonCompleted } from '../utils/AppGalleryCommentHelper'

type UnitId = 'intro' | 'alphabet' | 'numbers' | 'punctuation' | 'words'
export type WatchLessonType = 'alphabet' | 'numbers' | 'punctuation'

const UNITS: UnitId[] = ['intro', 'alphabet', 'numbers', 'punctuation', 'words']

const PREFS_NAME = 'learn_progress'
const KEY_COMPLETED = 'completed_lessons'

class ProgressStore {
  /** 已完成课程编号集合（1-based） */
  completedLessons: Set<number> = new Set()

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

  async load(context: Context): Promise<void> {
    const prefs = await this.getPrefs(context)
    const completedRaw = await prefs.get(KEY_COMPLETED, '[]')
    this.completedLessons = this.parseSet(completedRaw as string)
    console.error(`[STORE] load: loaded completedLessons=${Array.from(this.completedLessons).join(',')}`)
  }

  async saveLessonCompleted(lessonNumber: number, context: Context): Promise<void> {
    if (lessonNumber <= 0) {
      console.error(`[STORE] saveLessonCompleted: invalid lesson number ${lessonNumber}`)
      return
    }

    const wasNewlyCompleted = !this.completedLessons.has(lessonNumber)

    this.markLessonCompleted(lessonNumber)
    await this.persist(context)
    console.log(`[STORE] Lesson ${lessonNumber} completed and saved. Total completed: ${Array.from(this.completedLessons).join(',')}`)

    const eventData: LessonCompletedEventData = {
      lessonNumber: lessonNumber,
      completedLessons: Array.from(this.completedLessons),
      unitUnlocked: this.getUnitUnlocked()
    }
    console.error(`[STORE] saveLessonCompleted: sending event with completedLessons=${Array.from(this.completedLessons).join(',')}`)
    eventHub.emit(Events.LESSON_COMPLETED, eventData)

    if (wasNewlyCompleted && !DeviceHelper.isWearable()) {
      void recordLessonCompleted(context)
    }
  }

  isLessonUnlocked(n: number): boolean {
    return true
  }

  isLessonCompleted(n: number): boolean {
    return this.completedLessons.has(n)
  }

  getUnitUnlocked(): Map<UnitId, boolean> {
    const map = new Map<UnitId, boolean>()
    for (const u of UNITS) {
      const start = LessonConfig.getUnitStartLesson(u)
      map.set(u, this.isLessonUnlocked(start))
    }
    return map
  }

  /** 手表：基础课是否完成（课程编号 1） */
  isBasicsCompleted(): boolean {
    return this.isLessonCompleted(1)
  }

  /** 手表分组 → 与手机 LessonConfig 共用的课程编号 */
  getWatchGroupLessonNumber(lessonType: WatchLessonType, groupIndex: number): number {
    const lessonId = lessonType === 'alphabet'
      ? `alphabet_lesson_${groupIndex}`
      : lessonType === 'numbers'
        ? `number_lesson_${groupIndex}`
        : `punctuation_lesson_${groupIndex}`
    return LessonConfig.getLessonNumber(lessonId)
  }

  getWatchGroupTotal(lessonType: WatchLessonType): number {
    if (lessonType === 'alphabet') {
      return LessonGroups.getAlphabetGroups().length
    }
    if (lessonType === 'numbers') {
      return LessonGroups.getNumberGroups().length
    }
    return LessonGroups.getPunctuationGroups().length
  }

  /**
   * 手表：已完成的连续组数（也是下一组下标；全部完成则为 total）
   */
  getWatchGroupProgress(lessonType: WatchLessonType): number {
    const total = this.getWatchGroupTotal(lessonType)
    let completed = 0
    for (let i = 0; i < total; i++) {
      const lessonNumber = this.getWatchGroupLessonNumber(lessonType, i)
      if (lessonNumber > 0 && this.isLessonCompleted(lessonNumber)) {
        completed++
      } else {
        break
      }
    }
    return completed
  }

  /** 手表：保存某一组完成 */
  async saveWatchGroupCompleted(lessonType: WatchLessonType, groupIndex: number, context: Context): Promise<void> {
    const lessonNumber = this.getWatchGroupLessonNumber(lessonType, groupIndex)
    if (lessonNumber > 0) {
      await this.saveLessonCompleted(lessonNumber, context)
    }
  }
}

export const progressStore = new ProgressStore()
