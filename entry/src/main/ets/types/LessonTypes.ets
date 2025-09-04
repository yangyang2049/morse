// 共享的课程相关类型定义

export interface LessonItem {
  key: string
  title: string
  subtitle?: string
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
}

export interface QuizNavParams {
  pageTitle?: string
  lessonCompletedKey?: string
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
