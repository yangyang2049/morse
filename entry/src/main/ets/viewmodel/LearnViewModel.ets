import { LessonData } from '../data/LessonData'
import { LessonConfig } from '../data/LessonConfig'
import { progressStore } from '../store/ProgressStoreSingleton'
import { LessonItem } from '../types/LessonTypes'
import Context from '@ohos.app.ability.common'

@Observed
export class LearnViewModel {
  // 本地刷新触发器，当全局状态变化时更新
  @Track private localRefreshKey: number = 0
  
  // 供UI直接绑定的可追踪列表
  @Track introLessons: LessonItem[] = []
  @Track alphabetLessons: LessonItem[] = []
  @Track numberLessons: LessonItem[] = []
  @Track punctuationLessons: LessonItem[] = []
  @Track wordLessons: LessonItem[] = []
  
  
  // 重新加载解锁状态
  private reloadUnlockState(): void {
    console.error(`[VM] reloadUnlockState: reloading unlock state`)
    // 强制触发本地刷新
    this.localRefreshKey++
    console.error(`[VM] reloadUnlockState: localRefreshKey=${this.localRefreshKey}`)
    // 重建课程列表
    this.rebuildLessons()
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

  // 重建课程数据 - 使用强制重新计算确保实时响应性
  private rebuildLessons(): void {
    console.error(`[VM] rebuildLessons: START - localRefreshKey=${this.localRefreshKey}`)
    
    // 确保使用最新的数据 - 添加调试日志
    console.error(`[VM] rebuildLessons: completedLessons=${Array.from(progressStore.completedLessons).join(',')}`)
    
    // 强制重新计算所有课程状态 - 确保实时响应性
    this.forceRecalculateAllLessons()
    
    // Intro lessons - 重新计算状态
    {
      const lesson1Completed = progressStore.isLessonCompleted(1)
      const lesson2Completed = progressStore.isLessonCompleted(2)
      const lesson1Unlocked = progressStore.isLessonUnlocked(1)
      const lesson2Unlocked = progressStore.isLessonUnlocked(2)
      
      console.error(`[VM] rebuildLessons: lesson1 completed=${lesson1Completed} unlocked=${lesson1Unlocked}`)
      console.error(`[VM] rebuildLessons: lesson2 completed=${lesson2Completed} unlocked=${lesson2Unlocked}`)
      
      // 完全重新创建数组以确保响应式更新
      const newIntroLessons: LessonItem[] = [
        { key: 'intro_0', title: '第 1 课', subtitle: '摩斯密码基础', unlocked: lesson1Unlocked, unitUnlocked: true, completed: lesson1Completed },
        { key: 'intro_1', title: '第 2 课', subtitle: '中文摩斯密码基础', unlocked: lesson2Unlocked, unitUnlocked: true, completed: lesson2Completed },
        { key: 'intro_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true },
        { key: 'intro_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true },
        { key: 'intro_p3', title: '占位', unlocked: true, unitUnlocked: true, completed: true },
        { key: 'intro_p4', title: '占位', unlocked: true, unitUnlocked: true, completed: true },
        { key: 'intro_p5', title: '占位', unlocked: true, unitUnlocked: true, completed: true },
        { key: 'intro_p6', title: '占位', unlocked: true, unitUnlocked: true, completed: true }
      ]
      
      // 强制触发响应式更新
      this.introLessons.length = 0  // 清空现有数组
      this.introLessons.push(...newIntroLessons)  // 添加新数据
      
      console.error(`[VM] rebuildLessons: introLessons updated, lesson2 unlocked=${lesson2Unlocked}, array length=${this.introLessons.length}`)
    }
    
    // Alphabet lessons
    {
      const items: LessonItem[] = []
      const subtitles: string[] = ['A B C', 'D E F', 'G H I J', '复习：A - J', 'K L M N', 'O P Q R', 'S T U V', 'W X Y Z', '复习：K - Z']
      for (let i = 0; i < 9; i++) {
        const lessonNumber = 3 + i
        const completed = progressStore.isLessonCompleted(lessonNumber)
        const unlocked = progressStore.isLessonUnlocked(lessonNumber)
        items.push({ key: `alpha_${i}`, title: `第 ${i + 1} 课`, subtitle: subtitles[i], unlocked, unitUnlocked: true, completed })
      }
      items.push({ key: 'alpha_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      items.push({ key: 'alpha_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      
      // 强制触发响应式更新
      this.alphabetLessons.length = 0  // 清空现有数组
      this.alphabetLessons.push(...items)  // 添加新数据
      console.error(`[VM] rebuildLessons: alphabetLessons updated, array length=${this.alphabetLessons.length}`)
    }
    
    // Number lessons
    {
      const items: LessonItem[] = []
      const subtitles: string[] = ['0 1 2', '3 4 5', '6 7 8 9', '复习：0 - 9']
      for (let i = 0; i < 4; i++) {
        const lessonNumber = 12 + i
        const completed = progressStore.isLessonCompleted(lessonNumber)
        const unlocked = progressStore.isLessonUnlocked(lessonNumber)
        items.push({ key: `number_${i}`, title: `第 ${i + 1} 课`, subtitle: subtitles[i], unlocked, unitUnlocked: true, completed })
      }
      items.push({ key: 'number_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      items.push({ key: 'number_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      
      // 强制触发响应式更新
      this.numberLessons.length = 0
      this.numberLessons.push(...items)
      console.error(`[VM] rebuildLessons: numberLessons updated, array length=${this.numberLessons.length}`)
    }
    
    // Punctuation lessons
    {
      const items: LessonItem[] = []
      const subtitles: string[] = ['. , ? !', '- ( ) "', '复习：标点符号']
      for (let i = 0; i < 3; i++) {
        const lessonNumber = 16 + i
        const completed = progressStore.isLessonCompleted(lessonNumber)
        const unlocked = progressStore.isLessonUnlocked(lessonNumber)
        items.push({ key: `punctuation_${i}`, title: `第 ${i + 1} 课`, subtitle: subtitles[i], unlocked, unitUnlocked: true, completed })
      }
      items.push({ key: 'punctuation_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      items.push({ key: 'punctuation_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      items.push({ key: 'punctuation_p3', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      
      // 强制触发响应式更新
      this.punctuationLessons.length = 0
      this.punctuationLessons.push(...items)
      console.error(`[VM] rebuildLessons: punctuationLessons updated, array length=${this.punctuationLessons.length}`)
    }
    
    // Word lessons
    {
      const items: LessonItem[] = []
      const subtitles: string[] = ['3字母单词', '4字母单词', '5字母单词']
      for (let i = 0; i < 3; i++) {
        const lessonNumber = 19 + i
        const completed = progressStore.isLessonCompleted(lessonNumber)
        const unlocked = progressStore.isLessonUnlocked(lessonNumber)
        items.push({ key: `word_${i}`, title: `第 ${i + 1} 课`, subtitle: subtitles[i], unlocked, unitUnlocked: true, completed })
      }
      items.push({ key: 'word_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      items.push({ key: 'word_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      items.push({ key: 'word_p3', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      
      // 强制触发响应式更新
      this.wordLessons.length = 0
      this.wordLessons.push(...items)
      console.error(`[VM] rebuildLessons: wordLessons updated, array length=${this.wordLessons.length}`)
    }
    
    console.error(`[VM] rebuildLessons: COMPLETED - all arrays updated`)
  }

  async init(context: Context): Promise<void> {
    console.error('[VM] init() called')
    await progressStore.load(context)
    this.rebuildLessons()
  }
  
  // 公开方法：供外部调用来重建课程数据
  public refreshLessons(): void {
    console.error(`[VM] refreshLessons: rebuilding lessons`)
    console.error(`[VM] refreshLessons: current completedLessons=${Array.from(progressStore.completedLessons).join(',')}`)
    
    // 强制增加 localRefreshKey 以触发响应式更新
    this.localRefreshKey++
    console.error(`[VM] refreshLessons: incremented localRefreshKey to ${this.localRefreshKey}`)
    
    this.rebuildLessons()
    
    console.error(`[VM] refreshLessons: completed rebuilding`)
  }

  async loadUnlockState(context: Context): Promise<void> {
    console.error('[VM] loadUnlockState: delegating to progress store')
    await progressStore.load(context)
    
    // 手动触发本地刷新
    this.localRefreshKey++
    this.rebuildLessons()
  }

  // 根据课程ID获取课程编号
  getLessonNumber(lessonId: string): number {
    return LessonConfig.getLessonNumber(lessonId)
  }
  
  // 强制重新计算所有课程状态 - 确保实时响应性
  private forceRecalculateAllLessons(): void {
    console.error(`[VM] forceRecalculateAllLessons: starting recalculation`)
    
    // 强制重新计算所有课程状态
    for (let i = 1; i <= 21; i++) {
      const completed = progressStore.isLessonCompleted(i)
      const unlocked = progressStore.isLessonUnlocked(i)
      console.error(`[VM] forceRecalculateAllLessons: lesson${i} completed=${completed} unlocked=${unlocked}`)
    }
    
    console.error(`[VM] forceRecalculateAllLessons: recalculation completed`)
  }
  
}