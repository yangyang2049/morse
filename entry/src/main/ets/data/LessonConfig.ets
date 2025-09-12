
// 课程配置和编号系统
export class LessonConfig {
  // 缓存英文版本的 Map 对象，避免重复创建
  private static readonly UNIT_START_LESSONS_EN = new Map<string, number>([
    ['intro', 1],
    ['alphabet', 2],
    ['numbers', 11],
    ['punctuation', 15],
    ['words', 18]
  ])

  private static readonly UNIT_END_LESSONS_EN = new Map<string, number>([
    ['intro', 1], // 只有摩斯密码基础
    ['alphabet', 10], // 字母单元2-10
    ['numbers', 14], // 数字单元11-14
    ['punctuation', 17], // 符号单元15-17
    ['words', 20] // 单词单元18-20
  ])
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

  // 检查当前语言是否为英文
  private static isEnglish(): boolean {
    const currentLang: string = AppStorage.get<string>('currentLanguage') || 'zh-CN'
    return currentLang.startsWith('en')
  }

  // 根据语言获取课程映射（保持中文摩尔斯电码课程在所有语言中可见）
  static getLessonMapping(): Map<string, number> {
    // 所有语言都使用相同的课程映射，包含中文摩尔斯电码课程
    return LessonConfig.LESSON_MAPPING
  }

  // 根据语言获取单元起始课程编号
  static getUnitStartLessons(): Map<string, number> {
    return LessonConfig.isEnglish() ? LessonConfig.UNIT_START_LESSONS_EN : LessonConfig.UNIT_START_LESSONS
  }

  // 根据语言获取单元结束课程编号
  static getUnitEndLessons(): Map<string, number> {
    return LessonConfig.isEnglish() ? LessonConfig.UNIT_END_LESSONS_EN : LessonConfig.UNIT_END_LESSONS
  }

  // 根据语言获取课程编号
  static getLessonNumber(lessonId: string): number {
    return LessonConfig.LESSON_MAPPING.get(lessonId) ?? 0
  }

  // 根据语言获取单元起始课程编号
  static getUnitStartLesson(unitId: string): number {
    return LessonConfig.getUnitStartLessons().get(unitId) ?? 0
  }

  // 根据语言获取单元结束课程编号
  static getUnitEndLesson(unitId: string): number {
    return LessonConfig.getUnitEndLessons().get(unitId) ?? 0
  }

  // 根据语言检查课程是否在指定单元内
  static isLessonInUnit(lessonNumber: number, unitId: string): boolean {
    const start = LessonConfig.getUnitStartLesson(unitId)
    const end = LessonConfig.getUnitEndLesson(unitId)
    return lessonNumber >= start && lessonNumber <= end
  }

  // 根据语言获取所有课程ID列表
  static getAllLessonIds(): string[] {
    return Array.from(LessonConfig.LESSON_MAPPING.keys())
  }

  // 根据语言获取总课程数
  static getTotalLessonsForLanguage(): number {
    return LessonConfig.LESSON_MAPPING.size
  }
}