// 课程配置和编号系统
export class LessonConfig {
  // 课程编号映射 (1-18)
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
    ['punctuation_lesson_0', 16], // ., ? ! : ;
    ['punctuation_lesson_1', 17], // = + - _ " ' , ( ) / @
    ['punctuation_lesson_2', 18], // 复习
    
    // 单词单元 (19-21) - 预留
    ['word_lesson_0', 19], // 3字母单词
    ['word_lesson_1', 20], // 4字母单词
    ['word_lesson_2', 21], // 5字母单词
  ])

  // 单元起始课程编号
  static readonly UNIT_START_LESSONS = new Map<string, number>([
    ['intro', 1],
    ['alphabet', 3],
    ['numbers', 12],
    ['punctuation', 16],
    ['words', 19]
  ])

  // 单元结束课程编号
  static readonly UNIT_END_LESSONS = new Map<string, number>([
    ['intro', 2],
    ['alphabet', 11],
    ['numbers', 15],
    ['punctuation', 18],
    ['words', 21]
  ])

  // 获取课程编号
  static getLessonNumber(lessonId: string): number {
    return LessonConfig.LESSON_MAPPING.get(lessonId) ?? 0
  }

  // 获取单元起始课程编号
  static getUnitStartLesson(unitId: string): number {
    return LessonConfig.UNIT_START_LESSONS.get(unitId) ?? 0
  }

  // 获取单元结束课程编号
  static getUnitEndLesson(unitId: string): number {
    return LessonConfig.UNIT_END_LESSONS.get(unitId) ?? 0
  }

  // 检查课程是否在指定单元内
  static isLessonInUnit(lessonNumber: number, unitId: string): boolean {
    const start = LessonConfig.getUnitStartLesson(unitId)
    const end = LessonConfig.getUnitEndLesson(unitId)
    return lessonNumber >= start && lessonNumber <= end
  }

  // 获取所有课程ID列表
  static getAllLessonIds(): string[] {
    return Array.from(LessonConfig.LESSON_MAPPING.keys())
  }

  // 获取总课程数
  static getTotalLessons(): number {
    return LessonConfig.LESSON_MAPPING.size
  }
}
