import { LessonData } from '../data/LessonData'
import { ProgressStore } from '../store/ProgressStore'
import { LessonConfig } from '../data/LessonConfig'
import Context from '@ohos.app.ability.common'

@Observed
export class LearnViewModel {
  private store: ProgressStore = new ProgressStore()
  
  // 简化的状态管理
  unitUnlocked: Map<string, boolean> = new Map([
    ['intro', true], // 临时解锁所有单元
    ['alphabet', true],
    ['numbers', true],
    ['punctuation', true],
    ['words', true]
  ])

  // 目标单元和课程索引
  targetUnitIdx: number = 0
  targetLessonIdx: number | null = null

  async init(context: Context): Promise<void> {
    console.error('[VM] init() called')
    await this.loadUnlockState(context)
  }

  async loadUnlockState(context: Context): Promise<void> {
    try {
      console.error('[VM] loadUnlockState: start load from store')
      await this.store.load(context)

      // 获取单元解锁状态
      this.unitUnlocked = this.store.getUnitUnlocked()

      // 计算目标单元和课次
      this.computeTargetUnitAndLesson()
      
      console.error(`[VM] loadUnlockState: unitUnlocked intro=${this.unitUnlocked.get('intro')} alphabet=${this.unitUnlocked.get('alphabet')} numbers=${this.unitUnlocked.get('numbers')} punctuation=${this.unitUnlocked.get('punctuation')} words=${this.unitUnlocked.get('words')}`)

    } catch (error) {
      console.error('[VM] loadUnlockState FAILED:', error)
    }
  }

  computeTargetUnitAndLesson(): void {
    // 使用store的简化计算逻辑
    const target = this.store.computeTarget()
    this.targetUnitIdx = target.unitIdx
    this.targetLessonIdx = target.lessonIdx
  }

  async markLessonCompleted(lessonId: string, context: Context): Promise<void> {
    try {
      console.error(`[VM] markLessonCompleted: ${lessonId}`)
      await this.store.saveLessonCompleted(lessonId, context)
      await this.loadUnlockState(context)
    } catch (error) {
      console.error('[VM] markLessonCompleted FAILED:', error)
    }
  }

  async markTestCompleted(testKey: string, context: Context): Promise<void> {
    try {
      console.error(`[VM] markTestCompleted: ${testKey}`)
      await this.store.saveTestCompleted(testKey, context)
      await this.loadUnlockState(context)
      console.error(`[VM] markTestCompleted: after loadUnlockState, lesson 2 unlocked: ${this.isLessonUnlocked(2)}`)
    } catch (error) {
      console.error('[VM] markTestCompleted FAILED:', error)
    }
  }

  async markLessonContentCompleted(lessonKey: string, context: Context): Promise<void> {
    try {
      console.error(`[VM] markLessonContentCompleted: ${lessonKey}`)
      await this.store.saveLessonContentCompleted(lessonKey, context)
      await this.loadUnlockState(context)
    } catch (error) {
      console.error('[VM] markLessonContentCompleted FAILED:', error)
    }
  }

  // 检查课程是否已解锁
  isLessonUnlocked(lessonNumber: number): boolean {
    return this.store.isLessonUnlocked(lessonNumber)
  }

  // 检查课程是否已完成
  isLessonCompleted(lessonNumber: number): boolean {
    return this.store.isLessonCompleted(lessonNumber)
  }

  // 根据课程ID获取课程编号
  getLessonNumber(lessonId: string): number {
    return LessonConfig.getLessonNumber(lessonId)
  }

  // 解锁所有课程（用于测试或管理员功能）
  async unlockAllLessons(context: Context): Promise<void> {
    try {
      console.error('[VM] unlockAllLessons: unlocking all lessons')
      await this.store.unlockAllLessons(context)
      await this.loadUnlockState(context)
    } catch (error) {
      console.error('[VM] unlockAllLessons FAILED:', error)
    }
  }

  // 重置进度（用于测试）
  async resetProgress(context: Context): Promise<void> {
    try {
      console.error('[VM] resetProgress: resetting all progress')
      await this.store.resetProgress(context)
      await this.loadUnlockState(context)
    } catch (error) {
      console.error('[VM] resetProgress FAILED:', error)
    }
  }
}
