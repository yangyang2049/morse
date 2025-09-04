import { MorseCode, MorseCodeData } from '../models/MorseCode'

@Observed
export class FavoritesStore {
  @Track favoriteCharacters: Set<string> = new Set()
  @Track mistakeCharacters: Set<string> = new Set()
  
  private static instance: FavoritesStore | null = null
  
  static getInstance(): FavoritesStore {
    if (!FavoritesStore.instance) {
      FavoritesStore.instance = new FavoritesStore()
    }
    return FavoritesStore.instance
  }
  
  // 收藏相关方法
  addToFavorites(character: string): void {
    this.favoriteCharacters.add(character)
    this.saveToStorage()
  }
  
  removeFromFavorites(character: string): void {
    this.favoriteCharacters.delete(character)
    this.saveToStorage()
  }
  
  isFavorite(character: string): boolean {
    return this.favoriteCharacters.has(character)
  }
  
  toggleFavorite(character: string): void {
    if (this.isFavorite(character)) {
      this.removeFromFavorites(character)
    } else {
      this.addToFavorites(character)
    }
  }
  
  getFavoriteCharacters(): string[] {
    return Array.from(this.favoriteCharacters)
  }
  
  // 错题相关方法
  addToMistakes(character: string): void {
    this.mistakeCharacters.add(character)
    this.saveToStorage()
  }
  
  removeFromMistakes(character: string): void {
    this.mistakeCharacters.delete(character)
    this.saveToStorage()
  }
  
  isMistake(character: string): boolean {
    return this.mistakeCharacters.has(character)
  }
  
  getMistakeCharacters(): string[] {
    return Array.from(this.mistakeCharacters)
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
  
  // 存储到本地存储
  private saveToStorage(): void {
    try {
      const favoritesData = JSON.stringify(Array.from(this.favoriteCharacters))
      const mistakesData = JSON.stringify(Array.from(this.mistakeCharacters))
      
      // 这里可以使用preferences或其他存储方式
      // 暂时使用console.log模拟存储
      console.log('Saving favorites:', favoritesData)
      console.log('Saving mistakes:', mistakesData)
    } catch (error) {
      console.error('Failed to save to storage:', error)
    }
  }
  
  // 从本地存储加载
  loadFromStorage(): void {
    try {
      // 这里可以从preferences加载数据
      // 暂时使用空数据
      console.log('Loading from storage')
    } catch (error) {
      console.error('Failed to load from storage:', error)
    }
  }
  
  // 清空所有数据
  clearAll(): void {
    this.favoriteCharacters.clear()
    this.mistakeCharacters.clear()
    this.saveToStorage()
  }
}
