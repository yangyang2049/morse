import { preferences } from '@kit.ArkData'

export interface ProgressTarget {
  unitIdx: number
  lessonIdx: number | null
}

export class ProgressStore {
  // Base/unit completion flags
  introCompleted: boolean = false
  chineseCompleted: boolean = false
  introTestCompleted: boolean = false
  chineseTestCompleted: boolean = false

  // Per-lesson completion
  alphabetLessonsCompleted: Map<string, boolean> = new Map()
  numberLessonsCompleted: Map<string, boolean> = new Map()
  punctuationLessonsCompleted: Map<string, boolean> = new Map()
  wordLessonsCompleted: Map<string, boolean> = new Map()

  async load(): Promise<void> {
    console.error('[STORE] load: begin')
    const prefs = await preferences.getPreferences(getContext(), 'learn_progress')

    // Base flags
    this.introCompleted = await prefs.get('intro_completed', false) as boolean
    this.chineseCompleted = await prefs.get('chinese_completed', false) as boolean
    this.introTestCompleted = await prefs.get('intro_test_completed', false) as boolean
    this.chineseTestCompleted = await prefs.get('chinese_test_completed', false) as boolean

    // Lessons
    this.alphabetLessonsCompleted.clear()
    for (let i = 0; i < 9; i++) {
      const id = `alphabet_lesson_${i}`
      this.alphabetLessonsCompleted.set(id, await prefs.get(`${id}_completed`, false) as boolean)
    }

    this.numberLessonsCompleted.clear()
    for (let i = 0; i < 4; i++) {
      const id = `number_lesson_${i}`
      this.numberLessonsCompleted.set(id, await prefs.get(`${id}_completed`, false) as boolean)
    }

    this.punctuationLessonsCompleted.clear()
    for (let i = 0; i < 3; i++) {
      const id = `punctuation_lesson_${i}`
      this.punctuationLessonsCompleted.set(id, await prefs.get(`${id}_completed`, false) as boolean)
    }

    this.wordLessonsCompleted.clear()
    for (let i = 0; i < 3; i++) {
      const id = `word_lesson_${i}`
      this.wordLessonsCompleted.set(id, await prefs.get(`${id}_completed`, false) as boolean)
    }
    console.error(`[STORE] load: flags introCompleted=${this.introCompleted} introTestCompleted=${this.introTestCompleted} chineseCompleted=${this.chineseCompleted} chineseTestCompleted=${this.chineseTestCompleted}`)
  }

  async saveLessonCompleted(lessonId: string): Promise<void> {
    console.error(`[STORE] saveLessonCompleted: ${lessonId}`)
    const prefs = await preferences.getPreferences(getContext(), 'learn_progress')
    await prefs.put(`${lessonId}_completed`, true)
    await prefs.flush()

    if (lessonId.startsWith('alphabet_')) this.alphabetLessonsCompleted.set(lessonId, true)
    else if (lessonId.startsWith('number_')) this.numberLessonsCompleted.set(lessonId, true)
    else if (lessonId.startsWith('punctuation_')) this.punctuationLessonsCompleted.set(lessonId, true)
    else if (lessonId.startsWith('word_')) this.wordLessonsCompleted.set(lessonId, true)
  }

  async saveTestCompleted(testKey: string): Promise<void> {
    console.error(`[STORE] saveTestCompleted: ${testKey}`)
    const prefs = await preferences.getPreferences(getContext(), 'learn_progress')
    await prefs.put(testKey, true)
    await prefs.flush()

    if (testKey === 'intro_test_completed') this.introTestCompleted = true
    else if (testKey === 'chinese_test_completed') this.chineseTestCompleted = true
  }

  async saveLessonContentCompleted(lessonKey: string): Promise<void> {
    console.error(`[STORE] saveLessonContentCompleted: ${lessonKey}`)
    const prefs = await preferences.getPreferences(getContext(), 'learn_progress')
    await prefs.put(lessonKey, true)
    await prefs.flush()

    if (lessonKey === 'intro_completed') this.introCompleted = true
    else if (lessonKey === 'chinese_completed') this.chineseCompleted = true
  }

  private allCompleted(map: Map<string, boolean>): boolean {
    return Array.from(map.values()).every(v => v === true)
  }

  getUnitUnlocked(): Map<string, boolean> {
    const unitUnlocked: Map<string, boolean> = new Map([
      ['intro', true],
      ['alphabet', false],
      ['numbers', false],
      ['punctuation', false],
      ['words', false]
    ])

    const isIntroUnitCompleted = (this.introCompleted && this.chineseCompleted && this.introTestCompleted && this.chineseTestCompleted)
    const isAlphabetUnitCompleted = this.allCompleted(this.alphabetLessonsCompleted)
    const isNumberUnitCompleted = this.allCompleted(this.numberLessonsCompleted)

    unitUnlocked.set('alphabet', isIntroUnitCompleted)
    unitUnlocked.set('numbers', isAlphabetUnitCompleted)
    unitUnlocked.set('punctuation', isNumberUnitCompleted)
    unitUnlocked.set('words', isNumberUnitCompleted)

    return unitUnlocked
  }

  // Utility to compute target position (unit and next lesson index)
  computeTarget(): ProgressTarget {
    // Unit order: 0 intro, 1 alphabet, 2 numbers, 3 punctuation, 4 words
    const unitUnlocked = this.getUnitUnlocked()

    let unitIdx = 0
    if (this.introCompleted && this.introTestCompleted && this.chineseCompleted && this.chineseTestCompleted) {
      if (!unitUnlocked.get('numbers')) unitIdx = 1
      else if (!unitUnlocked.get('punctuation') || !unitUnlocked.get('words')) unitIdx = 2
      else {
        // Numbers completed; prefer punctuation, then words
        const punctDone = this.allCompleted(this.punctuationLessonsCompleted)
        const wordDone = this.allCompleted(this.wordLessonsCompleted)
        unitIdx = !punctDone ? 3 : (!wordDone ? 4 : 4)
      }
    }

    let lessonIdx: number | null = null
    if (unitIdx === 0) {
      if (!this.introTestCompleted) lessonIdx = 0
      else if (!this.chineseTestCompleted) lessonIdx = 1
    } else if (unitIdx === 1) {
      for (let i = 0; i < 9; i++) { if (!(this.alphabetLessonsCompleted.get(`alphabet_lesson_${i}`) ?? false)) { lessonIdx = i; break } }
    } else if (unitIdx === 2) {
      for (let i = 0; i < 4; i++) { if (!(this.numberLessonsCompleted.get(`number_lesson_${i}`) ?? false)) { lessonIdx = i; break } }
    } else if (unitIdx === 3) {
      for (let i = 0; i < 3; i++) { if (!(this.punctuationLessonsCompleted.get(`punctuation_lesson_${i}`) ?? false)) { lessonIdx = i; break } }
    } else if (unitIdx === 4) {
      for (let i = 0; i < 3; i++) { if (!(this.wordLessonsCompleted.get(`word_lesson_${i}`) ?? false)) { lessonIdx = i; break } }
    }

    const target: ProgressTarget = { unitIdx: unitIdx, lessonIdx: lessonIdx }
    return target
  }
}
