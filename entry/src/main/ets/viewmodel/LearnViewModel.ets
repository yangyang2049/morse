import { LessonData } from '../data/LessonData'
import { ProgressStore } from '../store/ProgressStore'
import { LessonConfig } from '../data/LessonConfig'
import Context from '@ohos.app.ability.common'

@Observed
export class LearnViewModel {
  private store: ProgressStore = new ProgressStore()
  
  // 简化的状态管理
  unitUnlocked: Map<string, boolean> = new Map([
    ['intro', false], // 初始状态：只有intro单元解锁（基于第一课）
    ['alphabet', false],
    ['numbers', false],
    ['punctuation', false],
    ['words', false]
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



  async markLessonContentCompleted(lessonKey: string, context: Context): Promise<void> {
    try {
      console.error(`[VM] markLessonContentCompleted: ${lessonKey}`)
      await this.store.saveLessonCompleted(lessonKey, context)
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



}
