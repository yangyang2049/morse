import { MorseCode, MorseCodeData } from '../models/MorseCode'
import { common, Context } from '@kit.AbilityKit'
import { learningRepositoryV2, LearningSnapshot } from '../repository/LearningRepositoryV2'

@Observed
export class FavoritesStore {
  @Track favoriteCharacters: Set<string> = new Set()
  @Track mistakeCharacters: Set<string> = new Set()
  @Track consecutiveCorrectCount: Map<string, number> = new Map()

  private static instance: FavoritesStore | null = null
  private snapshotListener: ((snapshot: LearningSnapshot) => void) | null = null

  private constructor() {}

  static getInstance(): FavoritesStore {
    if (!FavoritesStore.instance) {
      FavoritesStore.instance = new FavoritesStore()
    }
    return FavoritesStore.instance
  }

  async init(context: Context): Promise<void> {
    await learningRepositoryV2.init(context as common.UIAbilityContext, learningRepositoryV2.isDistributedSyncEnabled())
    this.applySnapshot(await learningRepositoryV2.getSnapshot())
    if (!this.snapshotListener) {
      this.snapshotListener = (snapshot: LearningSnapshot) => this.applySnapshot(snapshot)
      learningRepositoryV2.subscribe(this.snapshotListener)
    }
  }

  async addToFavorites(character: string): Promise<void> {
    await learningRepositoryV2.setFavorite(character, true)
  }

  async removeFromFavorites(character: string): Promise<void> {
    await learningRepositoryV2.setFavorite(character, false)
  }

  isFavorite(character: string): boolean {
    return this.favoriteCharacters.has(character)
  }

  async toggleFavorite(character: string): Promise<void> {
    await learningRepositoryV2.setFavorite(character, !this.isFavorite(character))
  }

  getFavoriteCharacters(): string[] {
    return Array.from(this.favoriteCharacters)
  }

  async addToMistakes(character: string): Promise<void> {
    this.consecutiveCorrectCount = new Map(this.consecutiveCorrectCount).set(character, 0)
    await learningRepositoryV2.setMistake(character, true)
  }

  async removeFromMistakes(character: string): Promise<void> {
    await learningRepositoryV2.setMistake(character, false)
  }

  isMistake(character: string): boolean {
    return this.mistakeCharacters.has(character)
  }

  getMistakeCharacters(): string[] {
    return Array.from(this.mistakeCharacters)
  }

  async incrementConsecutiveCorrect(character: string): Promise<number> {
    const count = (this.consecutiveCorrectCount.get(character) || 0) + 1
    this.consecutiveCorrectCount = new Map(this.consecutiveCorrectCount).set(character, count)
    return count
  }

  async resetConsecutiveCorrect(character: string): Promise<void> {
    this.consecutiveCorrectCount = new Map(this.consecutiveCorrectCount).set(character, 0)
  }

  getConsecutiveCorrectCount(character: string): number {
    return this.consecutiveCorrectCount.get(character) || 0
  }

  shouldRemoveFromMistakes(character: string): boolean {
    return this.getConsecutiveCorrectCount(character) >= 3
  }

  async tryRemoveFromMistakes(character: string): Promise<boolean> {
    if (this.shouldRemoveFromMistakes(character) && this.isMistake(character)) {
      await learningRepositoryV2.setMistake(character, false)
      this.consecutiveCorrectCount = new Map(this.consecutiveCorrectCount).set(character, 0)
      return true
    }
    return false
  }

  getMistakeMorseCodes(): MorseCode[] {
    const allCodes = [...MorseCodeData.englishAlphabet, ...MorseCodeData.numbers, ...MorseCodeData.punctuation]
    return allCodes.filter((code: MorseCode) => this.mistakeCharacters.has(code.character))
  }

  private applySnapshot(snapshot: LearningSnapshot): void {
    this.favoriteCharacters = new Set(snapshot.favoriteItemIds)
    this.mistakeCharacters = new Set(snapshot.mistakeItemIds)
  }
}
