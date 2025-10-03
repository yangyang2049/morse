// 共享的课程相关类型定义

export interface LessonItem {
  key: string
  title: Resource | string
  subtitle?: Resource | string
  unlocked: boolean
  unitUnlocked: boolean
  completed: boolean
}

export interface UnitData {
  title: string
  lessons: LessonItem[]
  unlocked: boolean
}

export interface LessonNavParams {
  title?: string
  testTitle?: string
  lessonCompletedKey?: string
  currentLanguage?: string
}

export interface QuizNavParams {
  pageTitle?: string
  lessonCompletedKey?: string
  currentLanguage?: string
}

export interface QuestionItem {
  type: string
  question: string
  answer: boolean | number
  points: number
  options?: string[]
}

export interface ExplanationItem {
  title: string
  content: string
}

export interface ButtonStyle {
  backgroundColor: string
  textColor: string
  borderColor: string
}

export interface LearnPageStrings {
  learn: string
  loading: string
  morse_code_basics: string
  alphabet_lesson: string
  number_lesson: string
  punctuation_lesson: string
  word_lesson: string
  please_complete_previous_lessons: string
  chinese_morse_code: string
  chinese_code_test: string
  basics_test: string
}
