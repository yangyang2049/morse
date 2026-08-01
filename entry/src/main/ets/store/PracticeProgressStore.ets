import { common, Context } from '@kit.AbilityKit'
import { learningRepositoryV2, LearningCounter, LearningSnapshot } from '../repository/LearningRepositoryV2'

export class PracticeProgressStore {
  private static instance: PracticeProgressStore | null = null
  private progressMap: Map<string, LearningCounter> = new Map()
  private snapshotListener: ((snapshot: LearningSnapshot) => void) | null = null

  private constructor() {}

  static getInstance(): PracticeProgressStore {
    if (!PracticeProgressStore.instance) {
      PracticeProgressStore.instance = new PracticeProgressStore()
    }
    return PracticeProgressStore.instance
  }

  async init(context: Context): Promise<void> {
    await learningRepositoryV2.init(context as common.UIAbilityContext, learningRepositoryV2.isDistributedSyncEnabled())
    this.applySnapshot(await learningRepositoryV2.getSnapshot())
    if (!this.snapshotListener) {
      this.snapshotListener = (snapshot: LearningSnapshot) => this.applySnapshot(snapshot)
      learningRepositoryV2.subscribe(this.snapshotListener)
    }
  }

  async recordCorrect(character: string): Promise<void> {
    await learningRepositoryV2.recordPracticeAttempt(character, true)
  }

  async recordIncorrect(character: string): Promise<void> {
    await learningRepositoryV2.recordPracticeAttempt(character, false)
  }

  getCharacterWeight(character: string): number {
    const progress = this.progressMap.get(character)
    if (!progress || progress.totalAttempts === 0) {
      return 10.0
    }
    const accuracy = progress.correctAttempts / progress.totalAttempts
    let weight = accuracy < 0.3 ? 5.0 : accuracy < 0.5 ? 3.0 : accuracy < 0.7 ? 2.0 : accuracy < 0.9 ? 1.5 : 0.5
    if (progress.totalAttempts < 5) {
      weight *= 2.0
    } else if (progress.totalAttempts < 10) {
      weight *= 1.5
    } else if (progress.totalAttempts > 30) {
      weight *= 0.7
    }
    return weight
  }

  private applySnapshot(snapshot: LearningSnapshot): void {
    const next: Map<string, LearningCounter> = new Map()
    for (const counter of snapshot.counters) {
      next.set(counter.itemId, counter)
    }
    this.progressMap = next
  }
}
