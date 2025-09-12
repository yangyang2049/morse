import { LessonData } from '../data/LessonData'
import { LessonConfig } from '../data/LessonConfig'
import { progressStore } from '../store/ProgressStoreSingleton'
import { LessonItem } from '../types/LessonTypes'
import Context from '@ohos.app.ability.common'
import { i18nService } from '../services/I18nService'
// 统一改为 i18nService
import { eventHub, Events } from '../utils/EventHub'

@Observed
export class LearnViewModel {
  // 本地刷新触发器，当全局状态变化时更新
  private localRefreshKey: number = 0
  
  // 供UI直接绑定的可观察列表 - 改为普通属性，通过手动触发更新
  introLessons: LessonItem[] = []
  alphabetLessons: LessonItem[] = []
  numberLessons: LessonItem[] = []
  punctuationLessons: LessonItem[] = []
  wordLessons: LessonItem[] = []

  // 获取课程标题（基于字典）
  private getLessonTitle(lessonNumber: number): string {
    const key = `lesson_${lessonNumber}`
    return i18nService.t(key)
  }
  
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
    
    // Intro lessons - 使用 LessonConfig 映射，英文版仅显示1课
    {
      const intro1 = this.getLessonNumber('intro_lesson_0')
      const intro2 = this.getLessonNumber('intro_lesson_1') // 若英文映射中不存在则为0

      const lesson1Completed = progressStore.isLessonCompleted(intro1)
      const lesson1Unlocked = progressStore.isLessonUnlocked(intro1)

      const newIntroLessons: LessonItem[] = []
      newIntroLessons.push({ key: 'intro_0', title: this.getLessonTitle(1), subtitle: i18nService.t('morse_code_basics'), unlocked: true, unitUnlocked: true, completed: lesson1Completed })

      // 只在中文模式下显示中文摩斯码课程
      if (intro2 > 0 && i18nService.getCurrentLanguage() === 'zh') {
        const lesson2Completed = progressStore.isLessonCompleted(intro2)
        newIntroLessons.push({ key: 'intro_1', title: this.getLessonTitle(2), subtitle: i18nService.t('chinese_morse_code'), unlocked: true, unitUnlocked: true, completed: lesson2Completed })
      }

      // 占位填充保持布局 - 增加更多占位符以匹配其他单元
      newIntroLessons.push({ key: 'intro_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      newIntroLessons.push({ key: 'intro_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      newIntroLessons.push({ key: 'intro_p3', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      newIntroLessons.push({ key: 'intro_p4', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      newIntroLessons.push({ key: 'intro_p5', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      newIntroLessons.push({ key: 'intro_p6', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      newIntroLessons.push({ key: 'intro_p7', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      newIntroLessons.push({ key: 'intro_p8', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      newIntroLessons.push({ key: 'intro_p9', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      newIntroLessons.push({ key: 'intro_p10', title: '占位', unlocked: true, unitUnlocked: true, completed: true })

      // 强制触发响应式更新 - 重新赋值整个数组
      this.introLessons = [...newIntroLessons]
      console.error(`[VM] rebuildLessons: introLessons updated (intro2=${intro2})`)
    }
    
    // Alphabet lessons
    {
      const items: LessonItem[] = []
      const subtitles: string[] = [
        i18nService.t('alphabet_abc'), i18nService.t('alphabet_def'), i18nService.t('alphabet_ghij'), 
        i18nService.t('alphabet_review_aj'), i18nService.t('alphabet_klmn'), i18nService.t('alphabet_opqr'), 
        i18nService.t('alphabet_stuv'), i18nService.t('alphabet_wxyz'), i18nService.t('alphabet_review_kz')
      ]
      for (let i = 0; i < 9; i++) {
        const lessonNumber = this.getLessonNumber(`alphabet_lesson_${i}`)
        if (lessonNumber <= 0) { continue }
        const completed = progressStore.isLessonCompleted(lessonNumber)
        items.push({ key: `alpha_${i}`, title: this.getLessonTitle(i + 1), subtitle: subtitles[i], unlocked: true, unitUnlocked: true, completed })
      }
      items.push({ key: 'alpha_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      items.push({ key: 'alpha_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      
      // 强制触发响应式更新 - 重新赋值整个数组
      this.alphabetLessons = [...items]
      console.error(`[VM] rebuildLessons: alphabetLessons updated, array length=${this.alphabetLessons.length}`)
    }
    
    // Number lessons
    {
      const items: LessonItem[] = []
      const subtitles: string[] = [i18nService.t('numbers_123'), i18nService.t('numbers_456'), i18nService.t('numbers_7890'), i18nService.t('numbers_review')]
      for (let i = 0; i < 4; i++) {
        const lessonNumber = this.getLessonNumber(`number_lesson_${i}`)
        if (lessonNumber <= 0) { continue }
        const completed = progressStore.isLessonCompleted(lessonNumber)
        items.push({ key: `number_${i}`, title: this.getLessonTitle(i + 1), subtitle: subtitles[i], unlocked: true, unitUnlocked: true, completed })
      }
      items.push({ key: 'number_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      items.push({ key: 'number_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      
      // 强制触发响应式更新 - 重新赋值整个数组
      this.numberLessons = [...items]
      console.error(`[VM] rebuildLessons: numberLessons updated, array length=${this.numberLessons.length}`)
    }
    
    // Punctuation lessons
    {
      const items: LessonItem[] = []
      const subtitles: string[] = [i18nService.t('punctuation_basic'), i18nService.t('punctuation_advanced'), i18nService.t('punctuation_review')]
      for (let i = 0; i < 3; i++) {
        const lessonNumber = this.getLessonNumber(`punctuation_lesson_${i}`)
        if (lessonNumber <= 0) { continue }
        const completed = progressStore.isLessonCompleted(lessonNumber)
        items.push({ key: `punctuation_${i}`, title: this.getLessonTitle(i + 1), subtitle: subtitles[i], unlocked: true, unitUnlocked: true, completed })
      }
      items.push({ key: 'punctuation_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      items.push({ key: 'punctuation_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      items.push({ key: 'punctuation_p3', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      
      // 强制触发响应式更新 - 重新赋值整个数组
      this.punctuationLessons = [...items]
      console.error(`[VM] rebuildLessons: punctuationLessons updated, array length=${this.punctuationLessons.length}`)
    }
    
    // Word lessons
    {
      const items: LessonItem[] = []
      const subtitles: string[] = [i18nService.t('words_3letter'), i18nService.t('words_4letter'), i18nService.t('words_5letter')]
      for (let i = 0; i < 3; i++) {
        const lessonNumber = this.getLessonNumber(`word_lesson_${i}`)
        if (lessonNumber <= 0) { continue }
        const completed = progressStore.isLessonCompleted(lessonNumber)
        items.push({ key: `word_${i}`, title: this.getLessonTitle(i + 1), subtitle: subtitles[i], unlocked: true, unitUnlocked: true, completed })
      }
      items.push({ key: 'word_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      items.push({ key: 'word_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      items.push({ key: 'word_p3', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      
      // 强制触发响应式更新 - 重新赋值整个数组
      this.wordLessons = [...items]
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
