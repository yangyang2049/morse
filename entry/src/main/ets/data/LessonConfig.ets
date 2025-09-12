import { languageService } from '../services/LanguageService'

// 课程配置和编号系统
export class LessonConfig {
  // 课程编号映射 - 中文版本使用全局连续编号
  static readonly LESSON_MAPPING = new Map<string, number>([
    // 基础单元 (1-2)
    ['intro_lesson_0', 1], // 摩斯密码基础
    ['intro_lesson_1', 2], // 中文摩尔斯电码
    
    // 字母单元 (3-11)
    ['alphabet_lesson_0', 3], // ABC
    ['alphabet_lesson_1', 4], // DEF
    ['alphabet_lesson_2', 5], // GHIJ
    ['alphabet_lesson_3', 6], // 复习：A-J
    ['alphabet_lesson_4', 7], // KLMN
    ['alphabet_lesson_5', 8], // OPQR
    ['alphabet_lesson_6', 9], // STUV
    ['alphabet_lesson_7', 10], // WXYZ
    ['alphabet_lesson_8', 11], // 复习：K-Z
    
    // 数字单元 (12-15)
    ['number_lesson_0', 12], // 1 2 3
    ['number_lesson_1', 13], // 4 5 6
    ['number_lesson_2', 14], // 7 8 9 0
    ['number_lesson_3', 15], // 复习：0-9
    
    // 符号单元 (16-18)
    ['punctuation_lesson_0', 16], // . , ? ! : ;
    ['punctuation_lesson_1', 17], // = + - _ " ' ( ) / @
    ['punctuation_lesson_2', 18], // 复习
    
    // 单词单元 (19-21)
    ['word_lesson_0', 19], // 3字母单词
    ['word_lesson_1', 20], // 4字母单词
    ['word_lesson_2', 21], // 5字母单词
  ])

  // 单元起始课程编号 - 中文版本使用全局连续编号
  static readonly UNIT_START_LESSONS = new Map<string, number>([
    ['intro', 1],
    ['alphabet', 3],
    ['numbers', 12],
    ['punctuation', 16],
    ['words', 19]
  ])

  // 单元结束课程编号 - 中文版本使用全局连续编号
  static readonly UNIT_END_LESSONS = new Map<string, number>([
    ['intro', 2],
    ['alphabet', 11],
    ['numbers', 15],
    ['punctuation', 18],
    ['words', 21]
  ])

  // 根据语言获取课程映射（英文版本移除中文摩尔斯电码课程）
  static getLessonMapping(): Map<string, number> {
    if (languageService.isEnglish()) {
      // 英文版本：移除中文摩尔斯电码课程，使用全局连续编号
      const englishMapping = new Map<string, number>()
      
      // 基础单元：只有摩斯密码基础
      englishMapping.set('intro_lesson_0', 1)
      
      // 字母单元：2-10
      englishMapping.set('alphabet_lesson_0', 2)
      englishMapping.set('alphabet_lesson_1', 3)
      englishMapping.set('alphabet_lesson_2', 4)
      englishMapping.set('alphabet_lesson_3', 5)
      englishMapping.set('alphabet_lesson_4', 6)
      englishMapping.set('alphabet_lesson_5', 7)
      englishMapping.set('alphabet_lesson_6', 8)
      englishMapping.set('alphabet_lesson_7', 9)
      englishMapping.set('alphabet_lesson_8', 10)
      
      // 数字单元：11-14
      englishMapping.set('number_lesson_0', 11)
      englishMapping.set('number_lesson_1', 12)
      englishMapping.set('number_lesson_2', 13)
      englishMapping.set('number_lesson_3', 14)
      
      // 符号单元：15-17
      englishMapping.set('punctuation_lesson_0', 15)
      englishMapping.set('punctuation_lesson_1', 16)
      englishMapping.set('punctuation_lesson_2', 17)
      
      // 单词单元：18-20
      englishMapping.set('word_lesson_0', 18)
      englishMapping.set('word_lesson_1', 19)
      englishMapping.set('word_lesson_2', 20)
      
      return englishMapping
    }
    
    return LessonConfig.LESSON_MAPPING
  }

  // 根据语言获取单元起始课程编号
  static getUnitStartLessons(): Map<string, number> {
    if (languageService.isEnglish()) {
      // 英文版本：使用全局连续编号
      return new Map([
        ['intro', 1],
        ['alphabet', 2],
        ['numbers', 11],
        ['punctuation', 15],
        ['words', 18]
      ])
    }
    
    return LessonConfig.UNIT_START_LESSONS
  }

  // 根据语言获取单元结束课程编号
  static getUnitEndLessons(): Map<string, number> {
    if (languageService.isEnglish()) {
      // 英文版本：使用全局连续编号
      return new Map([
        ['intro', 1], // 只有摩斯密码基础
        ['alphabet', 10], // 字母单元2-10
        ['numbers', 14], // 数字单元11-14
        ['punctuation', 17], // 符号单元15-17
        ['words', 20] // 单词单元18-20
      ])
    }
    
    return LessonConfig.UNIT_END_LESSONS
  }

  // 根据语言获取课程编号
  static getLessonNumber(lessonId: string): number {
    const mapping = LessonConfig.getLessonMapping()
    return mapping.get(lessonId) ?? 0
  }

  // 根据语言获取单元起始课程编号
  static getUnitStartLesson(unitId: string): number {
    const mapping = LessonConfig.getUnitStartLessons()
    return mapping.get(unitId) ?? 0
  }

  // 根据语言获取单元结束课程编号
  static getUnitEndLesson(unitId: string): number {
    const mapping = LessonConfig.getUnitEndLessons()
    return mapping.get(unitId) ?? 0
  }

  // 根据语言检查课程是否在指定单元内
  static isLessonInUnit(lessonNumber: number, unitId: string): boolean {
    const start = LessonConfig.getUnitStartLesson(unitId)
    const end = LessonConfig.getUnitEndLesson(unitId)
    return lessonNumber >= start && lessonNumber <= end
  }

  // 根据语言获取所有课程ID列表
  static getAllLessonIds(): string[] {
    const mapping = LessonConfig.getLessonMapping()
    return Array.from(mapping.keys())
  }

  // 根据语言获取总课程数
  static getTotalLessonsForLanguage(): number {
    const mapping = LessonConfig.getLessonMapping()
    return mapping.size
  }
}