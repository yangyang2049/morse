import { common } from '@kit.AbilityKit'
import { CourseCatalogV2, CourseDefinition, CourseUnitId } from '../data/CourseCatalogV2'
import { learningRepositoryV2, LearningSnapshot } from '../repository/LearningRepositoryV2'
import { LessonItem } from '../types/Types'
import { LocalizationHelper } from '../utils/LocalizationHelper'

@Observed
export class LearnViewModel {
  @Track private introLessons: LessonItem[] = []
  @Track private alphabetLessons: LessonItem[] = []
  @Track private numberLessons: LessonItem[] = []
  @Track private punctuationLessons: LessonItem[] = []
  @Track private wordLessons: LessonItem[] = []
  @Track public dataVersion: number = 0

  private completedCourseIds: Set<string> = new Set()
  private snapshotListener: ((snapshot: LearningSnapshot) => void) | null = null

  async init(context: common.UIAbilityContext, enableDistributedSync: boolean = false): Promise<void> {
    await learningRepositoryV2.init(context, enableDistributedSync)
    const snapshot = await learningRepositoryV2.getSnapshot()
    this.applySnapshot(snapshot)
    if (!this.snapshotListener) {
      this.snapshotListener = (updated: LearningSnapshot) => {
        this.applySnapshot(updated)
      }
      learningRepositoryV2.subscribe(this.snapshotListener)
    }
  }

  destroy(): void {
    if (this.snapshotListener) {
      learningRepositoryV2.unsubscribe(this.snapshotListener)
      this.snapshotListener = null
    }
  }

  refreshLessons(): void {
    this.rebuildLessons()
  }

  private applySnapshot(snapshot: LearningSnapshot): void {
    this.completedCourseIds = new Set(snapshot.completedCourseIds)
    this.rebuildLessons()
  }

  private rebuildLessons(): void {
    const language = LocalizationHelper.getCurrentLanguage()
    this.introLessons = this.buildUnit('intro', language)
    this.alphabetLessons = this.buildUnit('alphabet', language)
    this.numberLessons = this.buildUnit('numbers', language)
    this.punctuationLessons = this.buildUnit('punctuation', language)
    this.wordLessons = this.buildUnit('words', language)
    this.dataVersion++
  }

  private buildUnit(unitId: CourseUnitId, language: string): LessonItem[] {
    return CourseCatalogV2.getByUnit(unitId, language).map((course: CourseDefinition) => this.buildLessonItem(course))
  }

  private buildLessonItem(course: CourseDefinition): LessonItem {
    const item: LessonItem = {
      key: course.id,
      title: LocalizationHelper.getString(course.titleKey),
      subtitle: LocalizationHelper.getString(course.subtitleKey),
      unlocked: true,
      unitUnlocked: true,
      completed: this.completedCourseIds.has(course.id)
    }
    return item
  }

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
