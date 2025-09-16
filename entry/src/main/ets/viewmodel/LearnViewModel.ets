import { LessonConfig } from '../data/LessonConfig'
import { progressStore } from '../store/ProgressStoreSingleton'
import { LessonItem } from '../types/LessonTypes'
import Context from '@ohos.app.ability.common'
import { i18nService } from '../services/I18nService'

@Observed
export class LearnViewModel {
  // 使用@Track装饰器，确保数据变化时触发UI更新
  @Track private introLessons: LessonItem[] = []
  @Track private alphabetLessons: LessonItem[] = []
  @Track private numberLessons: LessonItem[] = []
  @Track private punctuationLessons: LessonItem[] = []
  @Track private wordLessons: LessonItem[] = []
  
  // 添加一个版本号来强制触发UI更新
  @Track public dataVersion: number = 0

  // 获取课程标题（基于字典）
  private getLessonTitle(lessonNumber: number): string {
    const key = `lesson_${lessonNumber}`
    return i18nService.t(key)
  }
  

  // 重建课程数据
  private rebuildLessons(): void {
    console.log('[LearnViewModel] Rebuilding lessons with current language:', i18nService.getCurrentLanguage())
    // 使用 i18nService 判断是否为中文
    const isChinese = i18nService.isChinese()
    console.log(`[LearnViewModel] isChinese: ${isChinese}, will ${isChinese ? 'show' : 'hide'} lesson 2`)
    console.log(`[LearnViewModel] AppStorage currentLanguage: ${AppStorage.get<string>('currentLanguage')}`)
    
    // Intro lessons - 根据语言显示不同的课程
    {
      const newIntroLessons: LessonItem[] = []
      
      // 第1课：摩斯电码基础
      const intro1 = this.getLessonNumber('intro_lesson_0')
      const lesson1Completed = progressStore.isLessonCompleted(intro1)
      newIntroLessons.push({ 
        key: 'intro_0', 
        title: this.getLessonTitle(1), 
        subtitle: i18nService.t('morse_code_basics'), 
        unlocked: true, 
        unitUnlocked: true, 
        completed: lesson1Completed 
      })

      // 第2课：中文摩尔斯电码 - 只在中文时显示
      if (isChinese) {
        const intro2 = this.getLessonNumber('intro_lesson_1')
        const lesson2Completed = progressStore.isLessonCompleted(intro2)
        newIntroLessons.push({ 
          key: 'intro_1', 
          title: this.getLessonTitle(2), 
          subtitle: i18nService.t('chinese_morse_code'), 
          unlocked: true, 
          unitUnlocked: true, 
          completed: lesson2Completed 
        })
        console.log('[LearnViewModel] Added real lesson 2 for Chinese')
        
        // 中文版本：添加9个占位符
        for (let i = 1; i <= 9; i++) {
          newIntroLessons.push({ key: `intro_p${i}`, title: '占位', unlocked: true, unitUnlocked: true, completed: true })
        }
      } else {
        console.log('[LearnViewModel] Skipped lesson 2 for English')
        
        // 英文版本：添加10个占位符（比中文版本多1个，因为少了第2课）
        for (let i = 1; i <= 10; i++) {
          newIntroLessons.push({ key: `intro_p${i}`, title: '占位', unlocked: true, unitUnlocked: true, completed: true })
        }
      }

      this.introLessons = newIntroLessons
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
      // 占位填充
      for (let i = 1; i <= 2; i++) {
        items.push({ key: `alpha_p${i}`, title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      }
      this.alphabetLessons = items
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
      // 占位填充
      for (let i = 1; i <= 7; i++) {
        items.push({ key: `number_p${i}`, title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      }
      this.numberLessons = items
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
      // 占位填充
      for (let i = 1; i <= 8; i++) {
        items.push({ key: `punctuation_p${i}`, title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      }
      this.punctuationLessons = items
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
      // 占位填充
      for (let i = 1; i <= 8; i++) {
        items.push({ key: `word_p${i}`, title: '占位', unlocked: true, unitUnlocked: true, completed: true })
      }
      this.wordLessons = items
    }
  }

  async init(context: Context): Promise<void> {
    await progressStore.load(context)
    this.rebuildLessons()
  }
  
  // 公开方法：供外部调用来重建课程数据
  public refreshLessons(): void {
    console.log('[LearnViewModel] Refreshing lessons due to language change')
    
    // 直接从 i18nService 获取当前语言状态，确保同步
    const currentLang = i18nService.getCurrentLanguage()
    const isChinese = i18nService.isChinese()
    console.log(`[LearnViewModel] Current language from i18nService: ${currentLang}, isChinese: ${isChinese}`)
    console.log(`[LearnViewModel] AppStorage language: ${AppStorage.get<string>('currentLanguage')}`)
    
    this.rebuildLessons()
    
    // 更新版本号来强制触发UI更新
    this.dataVersion++
    console.log('[LearnViewModel] Lessons refreshed, intro count:', this.introLessons.length, 'dataVersion:', this.dataVersion)
    
    // 输出第一个和第二个课程的详细信息进行调试
    const introLessons = this.getIntroLessons()
    if (introLessons.length > 0) {
      console.log(`[LearnViewModel] First lesson: ${introLessons[0].key} - ${introLessons[0].title}`)
    }
    if (introLessons.length > 1) {
      console.log(`[LearnViewModel] Second lesson: ${introLessons[1].key} - ${introLessons[1].title}`)
    }
  }

  // 根据课程ID获取课程编号
  getLessonNumber(lessonId: string): number {
    return LessonConfig.getLessonNumber(lessonId)
  }

  // 获取课程数据的方法
  getIntroLessons(): LessonItem[] {
    return [...this.introLessons]
  }

  getAlphabetLessons(): LessonItem[] {
    return [...this.alphabetLessons]
  }

  getNumberLessons(): LessonItem[] {
    return [...this.numberLessons]
  }

  getPunctuationLessons(): LessonItem[] {
    return [...this.punctuationLessons]
  }

  getWordLessons(): LessonItem[] {
    return [...this.wordLessons]
  }
  
}
