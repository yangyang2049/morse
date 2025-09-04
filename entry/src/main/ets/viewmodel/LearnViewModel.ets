import { LessonData } from '../data/LessonData'
import { LessonConfig } from '../data/LessonConfig'
import { progressStore } from '../store/ProgressStoreSingleton'
import { eventHub, Events, LessonCompletedEventData } from '../utils/EventHub'
import { LessonItem } from '../types/LessonTypes'
import Context from '@ohos.app.ability.common'

@Observed
export class LearnViewModel {
  // 本地刷新触发器，当全局状态变化时更新
  private localRefreshKey: number = 0
  // 页面刷新触发器
  private pageRefreshCallback: (() => void) | null = null
  
  // 设置页面刷新回调
  setPageRefreshCallback(callback: () => void): void {
    this.pageRefreshCallback = callback
  }
  
  // 重新加载解锁状态
  private reloadUnlockState(): void {
    console.error(`[VM] reloadUnlockState: reloading unlock state`)
    // 强制触发本地刷新
    this.localRefreshKey++
    console.error(`[VM] reloadUnlockState: localRefreshKey=${this.localRefreshKey}`)
  }
  
  // 直接从单例获取解锁状态
  get unitUnlocked(): Map<string, boolean> {
    // 引用 localRefreshKey 使其响应式
    const _ = this.localRefreshKey
    return progressStore.getUnitUnlocked()
  }

  get targetUnitIdx(): number {
    return 0 // 简化，暂时返回0
  }

  get targetLessonIdx(): number | null {
    return 0 // 简化，暂时返回0
  }

  // 课程数据 - 响应式
  get introLessons(): LessonItem[] {
    // Reference local refresh key to make this reactive
    const _ = this.localRefreshKey
    
    const lesson1Completed = progressStore.isLessonCompleted(1)
    const lesson2Completed = progressStore.isLessonCompleted(2)
    
    return [
      { 
        key: 'intro_0', 
        title: '第 1 课', 
        subtitle: '摩斯密码基础', 
        unlocked: true, 
        unitUnlocked: true, 
        completed: lesson1Completed 
      },
      { 
        key: 'intro_1', 
        title: '第 2 课', 
        subtitle: '中文摩斯密码基础', 
        unlocked: true, 
        unitUnlocked: true, 
        completed: lesson2Completed 
      },
      { key: 'intro_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true },
      { key: 'intro_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true },
      { key: 'intro_p3', title: '占位', unlocked: true, unitUnlocked: true, completed: true },
      { key: 'intro_p4', title: '占位', unlocked: true, unitUnlocked: true, completed: true },
      { key: 'intro_p5', title: '占位', unlocked: true, unitUnlocked: true, completed: true },
      { key: 'intro_p6', title: '占位', unlocked: true, unitUnlocked: true, completed: true }
    ]
  }

  get alphabetLessons(): LessonItem[] {
    // Reference local refresh key to make this reactive
    const _ = this.localRefreshKey
    
    const items: LessonItem[] = []
    const subtitles: string[] = ['A B C', 'D E F', 'G H I J', '复习：A - J', 'K L M N', 'O P Q R', 'S T U V', 'W X Y Z', '复习：K - Z']
    
    for (let i = 0; i < 9; i++) {
      const lessonNumber = 3 + i // 字母课程从第3课开始
      const completed = progressStore.isLessonCompleted(lessonNumber)
      
      items.push({
        key: `alpha_${i}`,
        title: `第 ${i + 1} 课`,
        subtitle: subtitles[i],
        unlocked: true,
        unitUnlocked: true,
        completed: completed
      })
    }
    
    // Add placeholder lessons
    items.push({ key: 'alpha_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    items.push({ key: 'alpha_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    return items
  }

  get numberLessons(): LessonItem[] {
    // Reference local refresh key to make this reactive
    const _ = this.localRefreshKey
    
    const items: LessonItem[] = []
    const subtitles: string[] = ['0 1 2', '3 4 5', '6 7 8 9', '复习：0 - 9']
    
    for (let i = 0; i < 4; i++) {
      const lessonNumber = 12 + i // 数字课程从第12课开始
      const completed = progressStore.isLessonCompleted(lessonNumber)
      
      items.push({
        key: `number_${i}`,
        title: `第 ${i + 1} 课`,
        subtitle: subtitles[i],
        unlocked: true,
        unitUnlocked: true,
        completed: completed
      })
    }
    
    // Add placeholder lessons
    items.push({ key: 'number_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    items.push({ key: 'number_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    return items
  }

  get punctuationLessons(): LessonItem[] {
    // Reference local refresh key to make this reactive
    const _ = this.localRefreshKey
    
    const items: LessonItem[] = []
    const subtitles: string[] = ['. , ? !', '- ( ) "', '复习：标点符号']
    
    for (let i = 0; i < 3; i++) {
      const lessonNumber = 16 + i // 标点符号课程从第16课开始
      const completed = progressStore.isLessonCompleted(lessonNumber)
      
      items.push({
        key: `punctuation_${i}`,
        title: `第 ${i + 1} 课`,
        subtitle: subtitles[i],
        unlocked: true,
        unitUnlocked: true,
        completed: completed
      })
    }
    
    // Add placeholder lessons
    items.push({ key: 'punctuation_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    items.push({ key: 'punctuation_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    return items
  }

  get wordLessons(): LessonItem[] {
    // Reference local refresh key to make this reactive
    const _ = this.localRefreshKey
    
    const items: LessonItem[] = []
    const subtitles: string[] = ['常用单词', '短语练习', '句子练习']
    
    for (let i = 0; i < 3; i++) {
      const lessonNumber = 19 + i // 单词课程从第19课开始
      const completed = progressStore.isLessonCompleted(lessonNumber)
      
      items.push({
        key: `word_${i}`,
        title: `第 ${i + 1} 课`,
        subtitle: subtitles[i],
        unlocked: true,
        unitUnlocked: true,
        completed: completed
      })
    }
    
    // Add placeholder lessons
    items.push({ key: 'word_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    items.push({ key: 'word_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    return items
  }

  async init(context: Context): Promise<void> {
    console.error('[VM] init() called')
    await progressStore.load(context)
    
    // 监听课程完成事件
    eventHub.on(Events.LESSON_COMPLETED, (data: Object) => {
      console.error(`[VM] Received lesson completed event:`, data)
      this.handleLessonCompleted(data)
    })
  }
  
  // 处理课程完成事件 - 简化为只触发刷新
  private handleLessonCompleted(data: Object): void {
    console.error(`[VM] handleLessonCompleted: triggering UI refresh`)
    
    // 触发UI刷新
    this.localRefreshKey++
    console.error(`[VM] handleLessonCompleted: localRefreshKey=${this.localRefreshKey}`)
    
    // 通知页面刷新
    if (this.pageRefreshCallback) {
      console.error(`[VM] handleLessonCompleted: triggering page refresh`)
      this.pageRefreshCallback()
    }
  }

  async loadUnlockState(context: Context): Promise<void> {
    console.error('[VM] loadUnlockState: delegating to progress store')
    await progressStore.load(context)
    
    // 手动触发本地刷新
    this.localRefreshKey++
  }

  // 根据课程ID获取课程编号
  getLessonNumber(lessonId: string): number {
    return LessonConfig.getLessonNumber(lessonId)
  }
  
}