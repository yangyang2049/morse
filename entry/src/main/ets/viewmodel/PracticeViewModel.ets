import { MorseCode, MorseCodeData } from '../models/MorseCode'
import { promptAction } from '@kit.ArkUI'
import { FavoritesStore } from '../store/FavoritesStore'
import { PracticeProgressStore } from '../store/PracticeProgressStore'
import { i18n } from '@kit.LocalizationKit'
// 使用$r()函数替代I18n

@Observed
export class PracticeViewModel {
  // Core game state (UI-tracked)
  @Track currentCharacter: string = ''
  @Track currentMorse: string = ''
  @Track userInput: string = ''
  @Track isCorrect: boolean = false
  @Track showResult: boolean = false
  @Track showCorrectAnswer: boolean = false
  @Track showHint: boolean = false
  @Track isFavorite: boolean = false
  @Track hasIncorrectAttempt: boolean = false
  @Track characterChangeId: number = 0
  @Track correctCount: number = 0
  @Track currentCodes: MorseCode[] = []
  @Track completionCount: Map<number, number> = new Map()
  @Track hadIncorrectOnCompletion: Map<number, boolean> = new Map()

  // Internal state
  private checkTimer: number | null = null
  private hintTimer: number | null = null
  private currentIndex: number = 0
  private difficulty: string = '简单'
  private favoritesStore: FavoritesStore = FavoritesStore.getInstance()
  private practiceProgressStore: PracticeProgressStore = PracticeProgressStore.getInstance()
  private autoCheckDelay: number = 600

  // Derived values (methods for compatibility with existing pages)
  getProgress(): number {
    // 只有在用户出现错误后才显示进度环
    // 第一次正确：进度 = 0.5 (半圆)
    // 第二次正确：进度 = 1.0 (完整圆)
    if (!this.hasIncorrectAttempt) {
      return 0.0
    }

    // 当有错误尝试时，根据正确次数计算进度
    if (this.correctCount === 1) {
      return 0.5 // 第一次正确：填充半圆
    } else if (this.correctCount >= 2) {
      return 1.0 // 第二次正确：填充完整圆
    }

    return 0.0
  }
  getRequiredAttempts(): number {
    return this.hasIncorrectAttempt ? 2 : 1
  }

  // 获取当前字符的连续正确次数
  getConsecutiveCorrectCount(): number {
    return this.favoritesStore.getConsecutiveCorrectCount(this.currentCharacter)
  }

  getCharacterChangeId(): number {
    return this.characterChangeId
  }
  // Field accessors (compat methods expected by PracticePage.ets)
  getCurrentCharacter(): string { return this.currentCharacter }
  getCurrentMorse(): string { return this.currentMorse }
  getUserInput(): string { return this.userInput }
  getIsCorrect(): boolean { return this.isCorrect }
  getShowResult(): boolean { return this.showResult }
  getIsFavorite(): boolean { return this.isFavorite }
  getShowCorrectAnswer(): boolean { return this.showCorrectAnswer }
  getHasIncorrectAttempt(): boolean { return this.hasIncorrectAttempt }
  getShowHint(): boolean { return this.showHint }
  getCorrectCount(): number { return this.correctCount }
  getCurrentCodes(): MorseCode[] { return this.currentCodes }
  getCompletionCount(): Map<number, number> { return this.completionCount }
  getHadIncorrectOnCompletion(): Map<number, boolean> { return this.hadIncorrectOnCompletion }

  // Initialize practice session
  init(difficulty: string = '简单'): void {
    this.difficulty = difficulty
    this.loadCodes()
  }

  // Initialize with specific characters (for favorites and mistakes)
  initWithCharacters(difficulty: string, characters: string[]): void {
    this.difficulty = difficulty
    this.loadCodesFromCharacters(characters)
  }

  // Load codes based on difficulty
  private loadCodes(): void {
    const d = (this.difficulty || '').toLowerCase()
    // Normalize difficulty: support zh/en labels and code keys
    const isEasy = d === 'easy' || d === '简单'
      || d === 'easy'.toLowerCase()
    const isMedium = d === 'medium' || d === '中等'
    const isHard = d === 'hard' || d === '困难'

    if (isEasy) {
      this.currentCodes = MorseCodeData.englishAlphabet
    } else if (isMedium) {
      this.currentCodes = [
        ...MorseCodeData.englishAlphabet,
        ...MorseCodeData.numbers
      ]
    } else if (isHard) {
      // Exclude Chinese characters; include only English letters, numbers, and common symbols
      this.currentCodes = [
        ...MorseCodeData.englishAlphabet,
        ...MorseCodeData.numbers,
        ...MorseCodeData.punctuation,
      ]
    } else {
      // Default fallback
      this.currentCodes = MorseCodeData.englishAlphabet
    }
    this.currentIndex = -1
    this.completionCount = new Map()
    this.hadIncorrectOnCompletion = new Map()
    this.generateNewCharacter()
  }

  // Load codes from specific characters (for favorites and mistakes)
  private loadCodesFromCharacters(characters: string[]): void {
    const allCodes = [...MorseCodeData.englishAlphabet, ...MorseCodeData.numbers, ...MorseCodeData.punctuation]
    this.currentCodes = allCodes.filter(code => characters.includes(code.character))

    this.currentIndex = -1
    this.completionCount = new Map()
    this.hadIncorrectOnCompletion = new Map()
    this.generateNewCharacter()
  }

  // Set current codes (for category filtering)
  setCurrentCodes(codes: MorseCode[]): void {
    this.currentCodes = codes
    this.currentIndex = -1
    this.generateNewCharacter()
  }

  // Generate new character for practice
  generateNewCharacter(): void {
    if (this.currentCodes.length === 0) return

    // 使用加权随机选择
    this.currentIndex = this.weightedRandomSelection()
    const randomCode = this.currentCodes[this.currentIndex]
    this.currentCharacter = randomCode.character
    this.currentMorse = randomCode.morse
    this.userInput = ''
    this.showResult = false
    this.isCorrect = false
    // 初始化收藏状态为当前字符在收藏夹中的真实状态
    this.isFavorite = this.favoritesStore.isFavorite(this.currentCharacter)
    this.correctCount = 0 // Reset correct count for new character
    this.showCorrectAnswer = false
    this.hasIncorrectAttempt = false // Reset incorrect attempt flag
    this.showHint = false
    this.characterChangeId++ // 增加字符变化ID以触发动画
  }

  // 加权随机选择字符索引
  private weightedRandomSelection(): number {
    if (this.currentCodes.length === 0) return 0

    // 计算每个字符的权重
    const weights: number[] = []
    let totalWeight = 0

    for (const code of this.currentCodes) {
      const weight = this.practiceProgressStore.getCharacterWeight(code.character)
      weights.push(weight)
      totalWeight += weight
    }

    // 使用权重进行随机选择
    let random = Math.random() * totalWeight
    for (let i = 0; i < weights.length; i++) {
      random -= weights[i]
      if (random <= 0) {
        return i
      }
    }

    // 备用方案（理论上不应该到达这里）
    return Math.floor(Math.random() * this.currentCodes.length)
  }

  // Add dot to user input
  addDot(): void {
    // TODO: Add vibration feedback
    this.userInput += '.'
    this.scheduleAutoCheck()
  }

  // Add dash to user input
  addDash(): void {
    // TODO: Add vibration feedback
    this.userInput += '-'
    this.scheduleAutoCheck()
  }

  // Schedule auto-check timer (resets on each input)
  private scheduleAutoCheck(): void {
    if (this.checkTimer !== null) {
      clearTimeout(this.checkTimer)
    }
    this.checkTimer = setTimeout(() => {
      this.checkAnswer()
    }, this.autoCheckDelay)
  }

  // Set auto-check delay for different modes
  setAutoCheckDelay(delay: number): void {
    this.autoCheckDelay = delay
  }

  // Check if the answer is correct
  checkAnswer(): void {
    if (this.userInput.trim() === '') return

    const isCorrect = this.userInput.trim() === this.currentMorse
    this.isCorrect = isCorrect
    this.showResult = true

    if (isCorrect) {
      this.correctCount++
      const requiredCount = this.hasIncorrectAttempt ? 2 : 1

      // 记录正确答案到练习进度
      this.practiceProgressStore.recordCorrect(this.currentCharacter)

      // 增加连续正确次数（仅在错题本中时）
      if (this.favoritesStore.isMistake(this.currentCharacter)) {
        const consecutiveCount = this.favoritesStore.incrementConsecutiveCorrect(this.currentCharacter)
        console.log(`Character ${this.currentCharacter} consecutive correct: ${consecutiveCount}`)

        // 检查是否应该从错题本移除
        if (this.favoritesStore.tryRemoveFromMistakes(this.currentCharacter)) {
          console.log(`Character ${this.currentCharacter} removed from mistakes after 3 consecutive correct answers`)
          // 显示移除提示
          try {
            const currentLocale = i18n.System.getSystemLocale()
            const message = currentLocale.startsWith('zh')
              ? `🎉 ${this.currentCharacter} 已从错题本移除！`
              : `🎉 ${this.currentCharacter} Removed from mistakes!`
            promptAction.showToast({
              message: message,
              duration: 2000,
              bottom: '70%'
            })
          } catch (error) {
            console.error('[PracticeViewModel] Failed to show toast:', error)
          }
        }
      }

      if (this.correctCount >= requiredCount) {
        // Character completed, move to next
        // Mark this character as practiced in this session
        if (this.currentIndex >= 0) {
          const currentCount = this.completionCount.get(this.currentIndex) || 0
          this.completionCount.set(this.currentIndex, currentCount + 1)
          // Record whether this completion had an incorrect attempt beforehand
          this.hadIncorrectOnCompletion.set(this.currentIndex, this.hasIncorrectAttempt)
        }

        setTimeout(() => {
          this.generateNewCharacter()
        }, 1500)
      } else {
        // Need more correct attempts, reset for next attempt
        setTimeout(() => {
          this.userInput = ''
          this.showResult = false
          this.isCorrect = false
        }, 1500)
      }
    } else {
      // 记录错误答案到练习进度
      this.practiceProgressStore.recordIncorrect(this.currentCharacter)

      // Wrong answer, show system toast at top of screen
      try {
        const currentLocale = i18n.System.getSystemLocale()
        const message = currentLocale.startsWith('zh') ? '再试一次' : 'Try again'
        promptAction.showToast({
          message: message,
          duration: 1500,
          bottom: '80%'
        })
      } catch (error) {
        console.error('[PracticeViewModel] Failed to show toast:', error)
      }

      // Add to mistakes if not already there
      this.favoritesStore.addToMistakes(this.currentCharacter)

      // 重置连续正确次数（因为答错了）
      this.favoritesStore.resetConsecutiveCorrect(this.currentCharacter)

      // Mark that user made incorrect attempt (if not already marked)
      if (!this.hasIncorrectAttempt) {
        this.hasIncorrectAttempt = true
        this.correctCount = 0 // Only reset counter on first incorrect attempt
      }

      // After 500ms, show correct answer
      setTimeout(() => {
        this.showCorrectAnswer = true
      }, 500)

      // Auto-hide error state after 2 seconds total (500ms red + 1.5s correct answer)
      setTimeout(() => {
        this.showResult = false
        this.showCorrectAnswer = false
        this.userInput = ''
      }, 2000)
    }
  }

  // Clear user input
  clearInput(): void {
    this.userInput = ''
  }

  // Toggle favorite status (sync with store state)
  toggleFavorite(): void {
    this.isFavorite = this.favoritesStore.isFavorite(this.currentCharacter)
  }

  // Skip to next character
  passCharacter(): void {
    this.generateNewCharacter()
  }

  // Play morse code audio
  playMorseCode(): void {
    // TODO: Implement audio playback
    console.log(`Playing morse code: ${this.currentMorse}`)
  }

  // Show hint for 1 second
  flashHint(): void {
    if (this.hintTimer !== null) {
      clearTimeout(this.hintTimer)
    }
    this.showHint = true

    this.hintTimer = setTimeout(() => {
      this.showHint = false
    }, 1000)
  }

  // Change difficulty
  changeDifficulty(newDifficulty: string): void {
    if (this.difficulty !== newDifficulty) {
      this.difficulty = newDifficulty
      this.loadCodes()
    }
  }

  // Dispose
  destroy(): void {
    if (this.checkTimer !== null) {
      clearTimeout(this.checkTimer)
    }
    if (this.hintTimer !== null) {
      clearTimeout(this.hintTimer)
    }
  }

  // Backward-compat alias methods for older pages
  initializePractice(difficulty: string): void { this.init(difficulty) }
  dispose(): void { this.destroy() }
}
