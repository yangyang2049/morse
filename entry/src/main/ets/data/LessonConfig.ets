import { languageService } from '../services/LanguageService'

// 课程配置和编号系统
export class LessonConfig {
  // 课程编号映射 - 每个单元内部从1开始
  static readonly LESSON_MAPPING = new Map<string, number>([
    // 基础单元 (1-2)
    ['intro_lesson_0', 1], // 摩斯密码基础
    ['intro_lesson_1', 2], // 中文摩尔斯电码
    
    // 字母单元 (1-9)
    ['alphabet_lesson_0', 1], // ABC
    ['alphabet_lesson_1', 2], // DEF
    ['alphabet_lesson_2', 3], // GHIJ
    ['alphabet_lesson_3', 4], // 复习：A-J
    ['alphabet_lesson_4', 5], // KLMN
    ['alphabet_lesson_5', 6], // OPQR
    ['alphabet_lesson_6', 7], // STUV
    ['alphabet_lesson_7', 8], // WXYZ
    ['alphabet_lesson_8', 9], // 复习：K-Z
    
    // 数字单元 (1-4)
    ['number_lesson_0', 1], // 1 2 3
    ['number_lesson_1', 2], // 4 5 6
    ['number_lesson_2', 3], // 7 8 9 0
    ['number_lesson_3', 4], // 复习：0-9
    
    // 符号单元 (1-3)
    ['punctuation_lesson_0', 1], // . , ? ! : ;
    ['punctuation_lesson_1', 2], // = + - _ " ' ( ) / @
    ['punctuation_lesson_2', 3], // 复习
    
    // 单词单元 (1-3)
    ['word_lesson_0', 1], // 3字母单词
    ['word_lesson_1', 2], // 4字母单词
    ['word_lesson_2', 3], // 5字母单词
  ])

  // 单元起始课程编号 - 每个单元都从1开始
  static readonly UNIT_START_LESSONS = new Map<string, number>([
    ['intro', 1],
    ['alphabet', 1],
    ['numbers', 1],
    ['punctuation', 1],
    ['words', 1]
  ])

  // 单元结束课程编号
  static readonly UNIT_END_LESSONS = new Map<string, number>([
    ['intro', 2],
    ['alphabet', 9],
    ['numbers', 4],
    ['punctuation', 3],
    ['words', 3]
  ])

  // 根据语言获取课程映射（英文版本移除中文摩尔斯电码课程）
  static getLessonMapping(): Map<string, number> {
    if (languageService.isEnglish()) {
      // 英文版本：移除中文摩尔斯电码课程，每个单元内部从1开始
      const englishMapping = new Map<string, number>()
      
      // 基础单元：只有摩斯密码基础
      englishMapping.set('intro_lesson_0', 1)
      
      // 字母单元：1-9
      englishMapping.set('alphabet_lesson_0', 1)
      englishMapping.set('alphabet_lesson_1', 2)
      englishMapping.set('alphabet_lesson_2', 3)
      englishMapping.set('alphabet_lesson_3', 4)
      englishMapping.set('alphabet_lesson_4', 5)
      englishMapping.set('alphabet_lesson_5', 6)
      englishMapping.set('alphabet_lesson_6', 7)
      englishMapping.set('alphabet_lesson_7', 8)
      englishMapping.set('alphabet_lesson_8', 9)
      
      // 数字单元：1-4
      englishMapping.set('number_lesson_0', 1)
      englishMapping.set('number_lesson_1', 2)
      englishMapping.set('number_lesson_2', 3)
      englishMapping.set('number_lesson_3', 4)
      
      // 符号单元：1-3
      englishMapping.set('punctuation_lesson_0', 1)
      englishMapping.set('punctuation_lesson_1', 2)
      englishMapping.set('punctuation_lesson_2', 3)
      
      // 单词单元：1-3
      englishMapping.set('word_lesson_0', 1)
      englishMapping.set('word_lesson_1', 2)
      englishMapping.set('word_lesson_2', 3)
      
      return englishMapping
    }
    
    return LessonConfig.LESSON_MAPPING
  }

  // 根据语言获取单元起始课程编号
  static getUnitStartLessons(): Map<string, number> {
    if (languageService.isEnglish()) {
      // 英文版本：移除中文摩尔斯电码课程，每个单元都从1开始
      return new Map([
        ['intro', 1],
        ['alphabet', 1],
        ['numbers', 1],
        ['punctuation', 1],
        ['words', 1]
      ])
    }
    
    return LessonConfig.UNIT_START_LESSONS
  }

  // 根据语言获取单元结束课程编号
  static getUnitEndLessons(): Map<string, number> {
    if (languageService.isEnglish()) {
      // 英文版本：移除中文摩尔斯电码课程，调整结束编号
      return new Map([
        ['intro', 1], // 只有摩斯密码基础
        ['alphabet', 9], // 字母单元1-9
        ['numbers', 4], // 数字单元1-4
        ['punctuation', 3], // 符号单元1-3
        ['words', 3] // 单词单元1-3
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