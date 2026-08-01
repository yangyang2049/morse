export enum CourseId {
  INTRO_MORSE = 'intro.morse',
  INTRO_CHINESE = 'intro.chinese',
  ALPHABET_ABC = 'alphabet.abc',
  ALPHABET_DEF = 'alphabet.def',
  ALPHABET_GHI = 'alphabet.ghi',
  ALPHABET_JKL = 'alphabet.jkl',
  ALPHABET_REVIEW_A_L = 'alphabet.review_a_l',
  ALPHABET_MNO = 'alphabet.mno',
  ALPHABET_PQR = 'alphabet.pqr',
  ALPHABET_STU = 'alphabet.stu',
  ALPHABET_VWX = 'alphabet.vwx',
  ALPHABET_YZ = 'alphabet.yz',
  ALPHABET_REVIEW_M_Z = 'alphabet.review_m_z',
  NUMBERS_012 = 'numbers.012',
  NUMBERS_345 = 'numbers.345',
  NUMBERS_6789 = 'numbers.6789',
  NUMBERS_REVIEW = 'numbers.review',
  PUNCTUATION_1 = 'punctuation.group_1',
  PUNCTUATION_2 = 'punctuation.group_2',
  PUNCTUATION_3 = 'punctuation.group_3',
  PUNCTUATION_REVIEW = 'punctuation.review',
  WORDS_3 = 'words.length_3',
  WORDS_4 = 'words.length_4',
  WORDS_5 = 'words.length_5'
}

export type CourseUnitId = 'intro' | 'alphabet' | 'numbers' | 'punctuation' | 'words'
export type CourseKind = 'knowledge' | 'practice' | 'review'

export interface CourseDefinition {
  id: CourseId
  unitId: CourseUnitId
  kind: CourseKind
  items: string[]
  titleKey: string
  subtitleKey: string
  zhOnly: boolean
}

const PUNCTUATION_GROUP_1: string[] = ['.', ',', '?', '!']
const PUNCTUATION_GROUP_2: string[] = [':', ';', '-', '/']
const PUNCTUATION_GROUP_3: string[] = ['(', ')']
const ALL_PUNCTUATION: string[] = [...PUNCTUATION_GROUP_1, ...PUNCTUATION_GROUP_2, ...PUNCTUATION_GROUP_3]

const WORDS: string[] = [
  'THE', 'AND', 'FOR', 'ARE', 'BUT', 'NOT', 'YOU', 'ALL', 'CAN', 'HAD', 'HER', 'WAS', 'ONE', 'OUR', 'OUT',
  'THAT', 'WITH', 'HAVE', 'THIS', 'WILL', 'YOUR', 'FROM', 'THEY', 'KNOW', 'WANT', 'BEEN', 'GOOD', 'MUCH', 'SOME',
  'TIME', 'WOULD', 'THERE', 'COULD', 'OTHER', 'AFTER', 'FIRST', 'NEVER', 'THESE', 'THINK', 'WHERE', 'BEING',
  'EVERY', 'GREAT', 'MIGHT', 'SHALL'
]

const COURSES: CourseDefinition[] = [
  { id: CourseId.INTRO_MORSE, unitId: 'intro', kind: 'knowledge', items: [], titleKey: 'course_intro_morse', subtitleKey: 'course_intro_morse_desc', zhOnly: false },
  { id: CourseId.INTRO_CHINESE, unitId: 'intro', kind: 'knowledge', items: [], titleKey: 'course_intro_chinese', subtitleKey: 'course_intro_chinese_desc', zhOnly: true },
  { id: CourseId.ALPHABET_ABC, unitId: 'alphabet', kind: 'practice', items: ['A', 'B', 'C'], titleKey: 'course_alphabet_abc', subtitleKey: 'course_alphabet_abc_desc', zhOnly: false },
  { id: CourseId.ALPHABET_DEF, unitId: 'alphabet', kind: 'practice', items: ['D', 'E', 'F'], titleKey: 'course_alphabet_def', subtitleKey: 'course_alphabet_def_desc', zhOnly: false },
  { id: CourseId.ALPHABET_GHI, unitId: 'alphabet', kind: 'practice', items: ['G', 'H', 'I'], titleKey: 'course_alphabet_ghi', subtitleKey: 'course_alphabet_ghi_desc', zhOnly: false },
  { id: CourseId.ALPHABET_JKL, unitId: 'alphabet', kind: 'practice', items: ['J', 'K', 'L'], titleKey: 'course_alphabet_jkl', subtitleKey: 'course_alphabet_jkl_desc', zhOnly: false },
  { id: CourseId.ALPHABET_REVIEW_A_L, unitId: 'alphabet', kind: 'review', items: 'ABCDEFGHIJKL'.split(''), titleKey: 'course_alphabet_review_a_l', subtitleKey: 'course_review_desc', zhOnly: false },
  { id: CourseId.ALPHABET_MNO, unitId: 'alphabet', kind: 'practice', items: ['M', 'N', 'O'], titleKey: 'course_alphabet_mno', subtitleKey: 'course_alphabet_mno_desc', zhOnly: false },
  { id: CourseId.ALPHABET_PQR, unitId: 'alphabet', kind: 'practice', items: ['P', 'Q', 'R'], titleKey: 'course_alphabet_pqr', subtitleKey: 'course_alphabet_pqr_desc', zhOnly: false },
  { id: CourseId.ALPHABET_STU, unitId: 'alphabet', kind: 'practice', items: ['S', 'T', 'U'], titleKey: 'course_alphabet_stu', subtitleKey: 'course_alphabet_stu_desc', zhOnly: false },
  { id: CourseId.ALPHABET_VWX, unitId: 'alphabet', kind: 'practice', items: ['V', 'W', 'X'], titleKey: 'course_alphabet_vwx', subtitleKey: 'course_alphabet_vwx_desc', zhOnly: false },
  { id: CourseId.ALPHABET_YZ, unitId: 'alphabet', kind: 'practice', items: ['Y', 'Z'], titleKey: 'course_alphabet_yz', subtitleKey: 'course_alphabet_yz_desc', zhOnly: false },
  { id: CourseId.ALPHABET_REVIEW_M_Z, unitId: 'alphabet', kind: 'review', items: 'MNOPQRSTUVWXYZ'.split(''), titleKey: 'course_alphabet_review_m_z', subtitleKey: 'course_review_desc', zhOnly: false },
  { id: CourseId.NUMBERS_012, unitId: 'numbers', kind: 'practice', items: ['0', '1', '2'], titleKey: 'course_numbers_012', subtitleKey: 'course_numbers_012_desc', zhOnly: false },
  { id: CourseId.NUMBERS_345, unitId: 'numbers', kind: 'practice', items: ['3', '4', '5'], titleKey: 'course_numbers_345', subtitleKey: 'course_numbers_345_desc', zhOnly: false },
  { id: CourseId.NUMBERS_6789, unitId: 'numbers', kind: 'practice', items: ['6', '7', '8', '9'], titleKey: 'course_numbers_6789', subtitleKey: 'course_numbers_6789_desc', zhOnly: false },
  { id: CourseId.NUMBERS_REVIEW, unitId: 'numbers', kind: 'review', items: '0123456789'.split(''), titleKey: 'course_numbers_review', subtitleKey: 'course_review_desc', zhOnly: false },
  { id: CourseId.PUNCTUATION_1, unitId: 'punctuation', kind: 'practice', items: PUNCTUATION_GROUP_1, titleKey: 'course_punctuation_1', subtitleKey: 'course_punctuation_1_desc', zhOnly: false },
  { id: CourseId.PUNCTUATION_2, unitId: 'punctuation', kind: 'practice', items: PUNCTUATION_GROUP_2, titleKey: 'course_punctuation_2', subtitleKey: 'course_punctuation_2_desc', zhOnly: false },
  { id: CourseId.PUNCTUATION_3, unitId: 'punctuation', kind: 'practice', items: PUNCTUATION_GROUP_3, titleKey: 'course_punctuation_3', subtitleKey: 'course_punctuation_3_desc', zhOnly: false },
  { id: CourseId.PUNCTUATION_REVIEW, unitId: 'punctuation', kind: 'review', items: ALL_PUNCTUATION, titleKey: 'course_punctuation_review', subtitleKey: 'course_review_desc', zhOnly: false },
  { id: CourseId.WORDS_3, unitId: 'words', kind: 'practice', items: WORDS.filter((word: string) => word.length === 3), titleKey: 'course_words_3', subtitleKey: 'course_words_3_desc', zhOnly: false },
  { id: CourseId.WORDS_4, unitId: 'words', kind: 'practice', items: WORDS.filter((word: string) => word.length === 4), titleKey: 'course_words_4', subtitleKey: 'course_words_4_desc', zhOnly: false },
  { id: CourseId.WORDS_5, unitId: 'words', kind: 'practice', items: WORDS.filter((word: string) => word.length === 5), titleKey: 'course_words_5', subtitleKey: 'course_words_5_desc', zhOnly: false }
]

export class CourseCatalogV2 {
  static getAll(): CourseDefinition[] {
    return COURSES.slice()
  }

  static getVisible(language: string): CourseDefinition[] {
    const isChinese = language.startsWith('zh')
    return CourseCatalogV2.getAll().filter((course: CourseDefinition) => !course.zhOnly || isChinese)
  }

  static getByUnit(unitId: CourseUnitId, language: string): CourseDefinition[] {
    return CourseCatalogV2.getVisible(language).filter((course: CourseDefinition) => course.unitId === unitId)
  }

  static get(courseId: string): CourseDefinition | null {
    const course = COURSES.find((item: CourseDefinition) => item.id === courseId)
    return course || null
  }

  static isCourseId(courseId: string): boolean {
    return COURSES.some((course: CourseDefinition) => course.id === courseId)
  }

  static getIndexInUnit(courseId: string): number {
    const course = CourseCatalogV2.get(courseId)
    if (!course) {
      return -1
    }
    return COURSES.filter((item: CourseDefinition) => item.unitId === course.unitId)
      .findIndex((item: CourseDefinition) => item.id === courseId)
  }
}
