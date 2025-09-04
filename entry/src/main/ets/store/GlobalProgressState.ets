import { ProgressStore } from './ProgressStore'
import { LessonItem, UnitData } from '../types/LessonTypes'
import Context from '@ohos.app.ability.common'

@Observed
export class GlobalProgressState {
  private store: ProgressStore = new ProgressStore()
  
  // 全局状态
  unitUnlocked: Map<string, boolean> = new Map([
    ['intro', false],
    ['alphabet', false], 
    ['numbers', false],
    ['punctuation', false],
    ['words', false]
  ])
  
  completedLessons: Set<number> = new Set()
  
  refreshKey: number = 0
  
  // 目标单元和课程索引
  targetUnitIdx: number = 0
  targetLessonIdx: number | null = null

  async init(context: Context): Promise<void> {
    console.error('[GLOBAL] init() called')
    await this.loadUnlockState(context)
  }

  async loadUnlockState(context: Context): Promise<void> {
    try {
      console.error('[GLOBAL] loadUnlockState: start load from store')
      await this.store.load(context)

      // 更新 @Provide 状态
      this.unitUnlocked = this.store.getUnitUnlocked()
      this.completedLessons = this.store.completedLessons

      // 计算目标单元和课次
      this.computeTargetUnitAndLesson()
      
      console.error(`[GLOBAL] loadUnlockState: unitUnlocked intro=${this.unitUnlocked.get('intro')} alphabet=${this.unitUnlocked.get('alphabet')} numbers=${this.unitUnlocked.get('numbers')} punctuation=${this.unitUnlocked.get('punctuation')} words=${this.unitUnlocked.get('words')}`)

    } catch (error) {
      console.error('[GLOBAL] loadUnlockState FAILED:', error)
    }
  }

  computeTargetUnitAndLesson(): void {
    const target = this.store.computeTarget()
    this.targetUnitIdx = target.unitIdx
    this.targetLessonIdx = target.lessonIdx
  }

  async markLessonCompleted(lessonNumber: number, context: Context): Promise<void> {
    try {
      console.error(`[GLOBAL] markLessonCompleted: Starting for lessonNumber=${lessonNumber}`)
      console.error(`[GLOBAL] markLessonCompleted: Before save - unitUnlocked intro=${this.unitUnlocked.get('intro')} alphabet=${this.unitUnlocked.get('alphabet')} numbers=${this.unitUnlocked.get('numbers')}`)
      
      await this.store.saveLessonCompleted(lessonNumber, context)
      console.error(`[GLOBAL] markLessonCompleted: After saveLessonCompleted, reloading unlock state`)
      
      await this.loadUnlockState(context)
      
      // 通知所有监听者状态已更新
      this.notifyStateChange()
      
      console.error(`[GLOBAL] markLessonCompleted: After loadUnlockState, unitUnlocked intro=${this.unitUnlocked.get('intro')} alphabet=${this.unitUnlocked.get('alphabet')} numbers=${this.unitUnlocked.get('numbers')} punctuation=${this.unitUnlocked.get('punctuation')} words=${this.unitUnlocked.get('words')}`)
      console.error(`[GLOBAL] markLessonCompleted: Target unit=${this.targetUnitIdx}, target lesson=${this.targetLessonIdx}`)
      console.error(`[GLOBAL] markLessonCompleted: refreshKey=${this.refreshKey}`)
    } catch (error) {
      console.error('[GLOBAL] markLessonCompleted FAILED:', error)
    }
  }
  
  // 通知状态变化
  private notifyStateChange(): void {
    // 触发 @Observed 类的更新 - 创建新的对象引用
    this.unitUnlocked = new Map(this.unitUnlocked)
    this.completedLessons = new Set(this.completedLessons)
    
    // 增加刷新键值
    this.refreshKey++
    
    // 通知所有监听者
    this.notifyListeners()
  }
  
  // 监听器列表
  private listeners: (() => void)[] = []
  
  // 添加监听器
  addListener(listener: () => void): void {
    this.listeners.push(listener)
  }
  
  // 移除监听器
  removeListener(listener: () => void): void {
    const index = this.listeners.indexOf(listener)
    if (index > -1) {
      this.listeners.splice(index, 1)
    }
  }
  
  // 通知所有监听者
  private notifyListeners(): void {
    console.error(`[GLOBAL] notifyListeners: notifying ${this.listeners.length} listeners`)
    this.listeners.forEach((listener, index) => {
      try {
        console.error(`[GLOBAL] notifyListeners: calling listener ${index}`)
        listener()
      } catch (error) {
        console.error(`[GLOBAL] notifyListeners: error in listener ${index}:`, error)
      }
    })
  }

  // 检查课程是否已解锁
  isLessonUnlocked(lessonNumber: number): boolean {
    return this.store.isLessonUnlocked(lessonNumber)
  }

  // 检查课程是否已完成
  isLessonCompleted(lessonNumber: number): boolean {
    return this.store.isLessonCompleted(lessonNumber)
  }
}

// 全局单例
export const globalProgressState = new GlobalProgressState()
