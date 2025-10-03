import { LessonConfig } from '../data/LessonConfig'
import { progressStore } from '../store/ProgressStoreSingleton'
import { LessonItem } from '../types/Types'
import Context from '@ohos.app.ability.common'

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
  private getLessonTitle(lessonNumber: number, unitIndex: number = 0): string {
    // 前两课（摩斯电码基础和中文摩斯电码）使用特殊标题
    if (lessonNumber <= 2) {
      const key = `lesson_${lessonNumber}`
      const localizedTitle = this.getLocalizedString(key)
      console.log(`[LearnViewModel] getLessonTitle(${lessonNumber}): key=${key}, localizedTitle=${localizedTitle}`)
      return localizedTitle
    }

    // 其他课程使用 "Lesson X" 或 "第X课" 格式，每个单元从1开始
    const currentLanguage = AppStorage.get<string>('currentLanguage') || 'zh-CN'
    const isChinese = currentLanguage.startsWith('zh')

    if (isChinese) {
      return `第${unitIndex + 1}课`
    } else {
      return `Lesson ${unitIndex + 1}`
    }
  }

  // 获取本地化字符串的辅助函数
  private getLocalizedString(key: string): string {
    const currentLanguage = AppStorage.get<string>('currentLanguage') || 'zh-CN'
    const isChinese = currentLanguage.startsWith('zh')
    console.log(`[LearnViewModel] getLocalizedString(${key}): currentLanguage=${currentLanguage}, isChinese=${isChinese}`)

    // 硬编码本地化字符串
    const localizedStrings: Record<string, Record<string, string>> = {
      'zh-CN': {
        'lesson_1': '摩斯电码基础',
        'lesson_2': '中文摩斯电码',
        'lesson_3': '字母 ABC',
        'lesson_4': '字母 DEF',
        'lesson_5': '字母 GHIJ',
        'lesson_6': '字母复习 A-J',
        'lesson_7': '字母 KLMN',
        'lesson_8': '字母 OPQR',
        'lesson_9': '字母 STUV',
        'lesson_10': '字母 WXYZ',
        'lesson_11': '字母复习 K-Z',
        'lesson_12': '数字 123',
        'lesson_13': '数字 456',
        'lesson_14': '数字 7890',
        'lesson_15': '数字复习',
        'lesson_16': '标点符号基础',
        'lesson_17': '标点符号进阶',
        'lesson_18': '标点符号复习',
        'lesson_19': '3字母单词',
        'lesson_20': '4字母单词',
        'lesson_21': '5字母单词',
        'morse_code_basics': '学习摩斯电码的基本原理和符号',
        'chinese_morse_code': '掌握中文摩斯电码的编码规则',
        'alphabet_abc': 'ABC',
        'alphabet_def': 'DEF',
        'alphabet_ghij': 'GHIJ',
        'alphabet_review_aj': '复习 A-J',
        'alphabet_klmn': 'KLMN',
        'alphabet_opqr': 'OPQR',
        'alphabet_stuv': 'STUV',
        'alphabet_wxyz': 'WXYZ',
        'alphabet_review_kz': '复习 K-Z',
        'numbers_123': '123',
        'numbers_456': '456',
        'numbers_7890': '7890',
        'numbers_review': '复习',
        'punctuation_basic': '基础',
        'punctuation_advanced': '进阶',
        'punctuation_review': '复习',
        'words_3letter': '3字母',
        'words_4letter': '4字母',
        'words_5letter': '5字母'
      },
      'en-US': {
        'lesson_1': 'Morse Code Basics',
        'lesson_2': 'Chinese Morse Code',
        'lesson_3': 'Letters ABC',
        'lesson_4': 'Letters DEF',
        'lesson_5': 'Letters GHIJ',
        'lesson_6': 'Letters Review A-J',
        'lesson_7': 'Letters KLMN',
        'lesson_8': 'Letters OPQR',
        'lesson_9': 'Letters STUV',
        'lesson_10': 'Letters WXYZ',
        'lesson_11': 'Letters Review K-Z',
        'lesson_12': 'Numbers 123',
        'lesson_13': 'Numbers 456',
        'lesson_14': 'Numbers 7890',
        'lesson_15': 'Numbers Review',
        'lesson_16': 'Punctuation Basics',
        'lesson_17': 'Punctuation Advanced',
        'lesson_18': 'Punctuation Review',
        'lesson_19': '3-Letter Words',
        'lesson_20': '4-Letter Words',
        'lesson_21': '5-Letter Words',
        'morse_code_basics': 'History, principles, and symbols',
        'chinese_morse_code': 'Master the encoding rules for Chinese Morse code',
        'alphabet_abc': 'ABC',
        'alphabet_def': 'DEF',
        'alphabet_ghij': 'GHIJ',
        'alphabet_review_aj': 'Review A-J',
        'alphabet_klmn': 'KLMN',
        'alphabet_opqr': 'OPQR',
        'alphabet_stuv': 'STUV',
        'alphabet_wxyz': 'WXYZ',
        'alphabet_review_kz': 'Review K-Z',
        'numbers_123': '123',
        'numbers_456': '456',
        'numbers_7890': '7890',
        'numbers_review': 'Review',
        'punctuation_basic': 'Basics',
        'punctuation_advanced': 'Advanced',
        'punctuation_review': 'Review',
        'words_3letter': '3-Letter',
        'words_4letter': '4-Letter',
        'words_5letter': '5-Letter'
      }
    }

    const langKey = isChinese ? 'zh-CN' : 'en-US'
    return localizedStrings[langKey]?.[key] || key
  }

  // 加载所有需要的字符串到缓存

  // 重建课程数据
  private rebuildLessons(): void {
    console.log('[LearnViewModel] Rebuilding lessons')
    // 从 AppStorage 判断是否为中文
    const currentLanguage = AppStorage.get<string>('currentLanguage') || 'zh-CN'
    const isChinese = currentLanguage.startsWith('zh')
    console.log(`[LearnViewModel] rebuildLessons: currentLanguage=${currentLanguage}, isChinese=${isChinese}`)

    // 测试第一个课程的标题
    const testTitle = this.getLessonTitle(1)
    console.log(`[LearnViewModel] Test lesson 1 title: ${testTitle}`)

    // Intro lessons - 根据语言显示不同的课程
    {
      const newIntroLessons: LessonItem[] = []

      // 第1课：摩斯电码基础
      const intro1 = this.getLessonNumber('intro_lesson_0')
      const lesson1Completed = progressStore.isLessonCompleted(intro1)
      newIntroLessons.push({
        key: 'intro_0',
        title: this.getLessonTitle(1),
        subtitle: this.getLocalizedString('morse_code_basics'),
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
          subtitle: this.getLocalizedString('chinese_morse_code'),
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

        // 英文版本：添加10个占位符
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
        this.getLocalizedString('alphabet_abc'),
        this.getLocalizedString('alphabet_def'),
        this.getLocalizedString('alphabet_ghij'),
        this.getLocalizedString('alphabet_review_aj'),
        this.getLocalizedString('alphabet_klmn'),
        this.getLocalizedString('alphabet_opqr'),
        this.getLocalizedString('alphabet_stuv'),
        this.getLocalizedString('alphabet_wxyz'),
        this.getLocalizedString('alphabet_review_kz')
      ]
      for (let i = 0; i < 9; i++) {
        const lessonNumber = this.getLessonNumber(`alphabet_lesson_${i}`)
        if (lessonNumber <= 0) { continue }
        const completed = progressStore.isLessonCompleted(lessonNumber)
        items.push({ key: `alpha_${i}`, title: this.getLessonTitle(i + 3, i), subtitle: subtitles[i], unlocked: true, unitUnlocked: true, completed })
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
      const subtitles: string[] = [
        this.getLocalizedString('numbers_123'),
        this.getLocalizedString('numbers_456'),
        this.getLocalizedString('numbers_7890'),
        this.getLocalizedString('numbers_review')
      ]
      for (let i = 0; i < 4; i++) {
        const lessonNumber = this.getLessonNumber(`number_lesson_${i}`)
        if (lessonNumber <= 0) { continue }
        const completed = progressStore.isLessonCompleted(lessonNumber)
        items.push({ key: `number_${i}`, title: this.getLessonTitle(i + 12, i), subtitle: subtitles[i], unlocked: true, unitUnlocked: true, completed })
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
      const subtitles: string[] = [
        this.getLocalizedString('punctuation_basic'),
        this.getLocalizedString('punctuation_advanced'),
        this.getLocalizedString('punctuation_review')
      ]
      for (let i = 0; i < 3; i++) {
        const lessonNumber = this.getLessonNumber(`punctuation_lesson_${i}`)
        if (lessonNumber <= 0) { continue }
        const completed = progressStore.isLessonCompleted(lessonNumber)
        items.push({ key: `punctuation_${i}`, title: this.getLessonTitle(i + 16, i), subtitle: subtitles[i], unlocked: true, unitUnlocked: true, completed })
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
      const subtitles: string[] = [
        this.getLocalizedString('words_3letter'),
        this.getLocalizedString('words_4letter'),
        this.getLocalizedString('words_5letter')
      ]
      for (let i = 0; i < 3; i++) {
        const lessonNumber = this.getLessonNumber(`word_lesson_${i}`)
        if (lessonNumber <= 0) { continue }
        const completed = progressStore.isLessonCompleted(lessonNumber)
        items.push({ key: `word_${i}`, title: this.getLessonTitle(i + 19, i), subtitle: subtitles[i], unlocked: true, unitUnlocked: true, completed })
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

    // 重建课程数据
    this.rebuildLessons()
  }

  // 公开方法：供外部调用来重建课程数据
  public refreshLessons(): void {
    console.log('[LearnViewModel] Refreshing lessons due to language change')

    // 重建课程数据
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
