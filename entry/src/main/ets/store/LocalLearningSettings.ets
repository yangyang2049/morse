import { preferences } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'

const SETTINGS_STORE = 'practice_settings'
const REPETITION_KEY = 'lesson_repetition_count_v2'
const DEFAULT_REPETITION_COUNT = 3

export class LocalLearningSettings {
  static clampRepetitionCount(value: number): number {
    if (!Number.isFinite(value)) {
      return DEFAULT_REPETITION_COUNT
    }
    return Math.max(1, Math.min(5, Math.round(value)))
  }

  static async getRepetitionCount(context: Context): Promise<number> {
    try {
      const store = await preferences.getPreferences(context, SETTINGS_STORE)
      const value = await store.get(REPETITION_KEY, DEFAULT_REPETITION_COUNT) as number
      return LocalLearningSettings.clampRepetitionCount(value)
    } catch (error) {
      console.error('[LocalLearningSettings] Failed to load repetition count:', error)
      return DEFAULT_REPETITION_COUNT
    }
  }

  static async setRepetitionCount(context: Context, value: number): Promise<number> {
    const normalized = LocalLearningSettings.clampRepetitionCount(value)
    const store = await preferences.getPreferences(context, SETTINGS_STORE)
    await store.put(REPETITION_KEY, normalized)
    await store.flush()
    return normalized
  }
}
