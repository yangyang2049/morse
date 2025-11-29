import { MorseCode, MorseCodeData } from '../models/MorseCode'
import { preferences } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'

const PREFS_NAME = 'favorites_store'
const KEY_FAVORITES = 'favorite_characters'
const KEY_MISTAKES = 'mistake_characters'
const KEY_CONSECUTIVE_CORRECT = 'consecutive_correct_count'

@Observed
export class FavoritesStore {
  @Track favoriteCharacters: Set<string> = new Set()
  @Track mistakeCharacters: Set<string> = new Set()
  @Track consecutiveCorrectCount: Map<string, number> = new Map() // 跟踪每个字符的连续正确次数
  
  private static instance: FavoritesStore | null = null
  private preferencesStore: preferences.Preferences | null = null
  
  private constructor() {}
  
  static getInstance(): FavoritesStore {
    if (!FavoritesStore.instance) {
      FavoritesStore.instance = new FavoritesStore()
    }
    return FavoritesStore.instance
  }

  // 初始化存储
  async init(context: Context): Promise<void> {
    try {
      this.preferencesStore = await preferences.getPreferences(context, PREFS_NAME)
      await this.load()
      console.log('[FavoritesStore] Initialized successfully')
    } catch (error) {
      console.error('[FavoritesStore] Failed to initialize:', error)
    }
  }
  
  // 收藏相关方法
  async addToFavorites(character: string): Promise<void> {
    this.favoriteCharacters.add(character)
    await this.save()
  }
  
  async removeFromFavorites(character: string): Promise<void> {
    this.favoriteCharacters.delete(character)
    await this.save()
  }
  
  isFavorite(character: string): boolean {
    return this.favoriteCharacters.has(character)
  }
  
  async toggleFavorite(character: string): Promise<void> {
    if (this.isFavorite(character)) {
      await this.removeFromFavorites(character)
    } else {
      await this.addToFavorites(character)
    }
  }
  
  getFavoriteCharacters(): string[] {
    return Array.from(this.favoriteCharacters)
  }
  
  // 错题相关方法
  async addToMistakes(character: string): Promise<void> {
    this.mistakeCharacters.add(character)
    await this.save()
  }
  
  async removeFromMistakes(character: string): Promise<void> {
    this.mistakeCharacters.delete(character)
    await this.save()
  }
  
  isMistake(character: string): boolean {
    return this.mistakeCharacters.has(character)
  }
  
  getMistakeCharacters(): string[] {
    return Array.from(this.mistakeCharacters)
  }
  
  // 连续正确次数管理
  async incrementConsecutiveCorrect(character: string): Promise<number> {
    const currentCount = this.consecutiveCorrectCount.get(character) || 0
    const newCount = currentCount + 1
    this.consecutiveCorrectCount.set(character, newCount)
    await this.save()
    return newCount
  }
  
  async resetConsecutiveCorrect(character: string): Promise<void> {
    this.consecutiveCorrectCount.set(character, 0)
    await this.save()
  }
  
  getConsecutiveCorrectCount(character: string): number {
    return this.consecutiveCorrectCount.get(character) || 0
  }
  
  // 检查是否应该从错题本移除（连续3次正确）
  shouldRemoveFromMistakes(character: string): boolean {
    return this.getConsecutiveCorrectCount(character) >= 3
  }
  
  // 从错题本移除字符（如果连续正确3次）
  async tryRemoveFromMistakes(character: string): Promise<boolean> {
    if (this.shouldRemoveFromMistakes(character) && this.isMistake(character)) {
      await this.removeFromMistakes(character)
      await this.resetConsecutiveCorrect(character) // 重置计数
      return true
    }
    return false
  }
  
  // 获取收藏的摩斯码对象
  getFavoriteMorseCodes(): MorseCode[] {
    const allCodes = [...MorseCodeData.englishAlphabet, ...MorseCodeData.numbers, ...MorseCodeData.punctuation]
    return allCodes.filter(code => this.favoriteCharacters.has(code.character))
  }
  
  // 获取错题的摩斯码对象
  getMistakeMorseCodes(): MorseCode[] {
    const allCodes = [...MorseCodeData.englishAlphabet, ...MorseCodeData.numbers, ...MorseCodeData.punctuation]
    return allCodes.filter(code => this.mistakeCharacters.has(code.character))
  }
  
  // 从本地存储加载数据
  private async load(): Promise<void> {
    if (!this.preferencesStore) return

    try {
      // 加载收藏字符
      const favoritesJson = await this.preferencesStore.get(KEY_FAVORITES, '[]') as string
      const favoritesArray = JSON.parse(favoritesJson) as string[]
      this.favoriteCharacters = new Set(favoritesArray)

      // 加载错题字符
      const mistakesJson = await this.preferencesStore.get(KEY_MISTAKES, '[]') as string
      const mistakesArray = JSON.parse(mistakesJson) as string[]
      this.mistakeCharacters = new Set(mistakesArray)

      // 加载连续正确次数
      const consecutiveJson = await this.preferencesStore.get(KEY_CONSECUTIVE_CORRECT, '[]') as string
      const consecutiveArray = JSON.parse(consecutiveJson) as [string, number][]
      this.consecutiveCorrectCount = new Map(consecutiveArray)

      console.log(`[FavoritesStore] Loaded ${this.favoriteCharacters.size} favorites, ${this.mistakeCharacters.size} mistakes`)
    } catch (error) {
      console.error('[FavoritesStore] Failed to load from storage:', error)
    }
  }

  // 保存数据到本地存储
  private async save(): Promise<void> {
    if (!this.preferencesStore) return

    try {
      // 保存收藏字符
      const favoritesArray = Array.from(this.favoriteCharacters)
      const favoritesJson = JSON.stringify(favoritesArray)
      await this.preferencesStore.put(KEY_FAVORITES, favoritesJson)

      // 保存错题字符
      const mistakesArray = Array.from(this.mistakeCharacters)
      const mistakesJson = JSON.stringify(mistakesArray)
      await this.preferencesStore.put(KEY_MISTAKES, mistakesJson)

      // 保存连续正确次数
      const consecutiveArray = Array.from(this.consecutiveCorrectCount.entries())
      const consecutiveJson = JSON.stringify(consecutiveArray)
      await this.preferencesStore.put(KEY_CONSECUTIVE_CORRECT, consecutiveJson)

      await this.preferencesStore.flush()
      console.log('[FavoritesStore] Data saved successfully')
    } catch (error) {
      console.error('[FavoritesStore] Failed to save to storage:', error)
    }
  }
  
  // 清空所有数据
  async clearAll(): Promise<void> {
    this.favoriteCharacters.clear()
    this.mistakeCharacters.clear()
    this.consecutiveCorrectCount.clear()
    await this.save()
  }
}
