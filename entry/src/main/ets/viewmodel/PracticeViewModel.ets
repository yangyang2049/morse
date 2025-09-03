import { MorseCode, MorseCodeData } from '../models/MorseCode'
import { promptAction } from '@kit.ArkUI'

@Observed
export class PracticeViewModel {
  // Game state
  @Track currentCharacter: string = ''
  @Track currentMorse: string = ''
  @Track userInput: string = ''
  @Track isCorrect: boolean = false
  @Track showResult: boolean = false
  @Track hintRevealed: boolean = false
  @Track showCorrectAnswer: boolean = false
  @Track showHint: boolean = false
  @Track isFavorite: boolean = false
  @Track correctCount: number = 0 // Track correct attempts for current character
  @Track difficulty: string = '简单'
  @Track hasIncorrectAttempt: boolean = false // Track if user made incorrect attempt
  @Track characterChangeId: number = 0 // 用于触发字符变化动画的唯一ID
  
  private checkTimer: number | null = null
  private hintTimer: number | null = null
  @Track currentCodes: MorseCode[] = []
  private currentIndex: number = 0
  @Track completionCount: Map<number, number> = new Map()
  @Track hadIncorrectOnCompletion: Map<number, boolean> = new Map()

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
  getCurrentCodes(): MorseCode[] { 
    return this.currentCodes 
  }
  getCompletionCount(): Map<number, number> { 
    return this.completionCount 
  }
  getHadIncorrectOnCompletion(): Map<number, boolean> { 
    return this.hadIncorrectOnCompletion 
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
  getHintRevealed(): boolean { return this.hintRevealed }
  getIsFavorite(): boolean { return this.isFavorite }
  getCorrectCount(): number { return this.correctCount }
  getDifficulty(): string { return this.difficulty }
  getShowCorrectAnswer(): boolean { return this.showCorrectAnswer }
  getHasIncorrectAttempt(): boolean { return this.hasIncorrectAttempt }
  getShowHint(): boolean { return this.showHint }

  // Initialize practice session
  init(difficulty: string = '简单'): void {
    this.difficulty = difficulty
    this.loadCodes()
  }

  // Load codes based on difficulty
  private loadCodes(): void {
    switch (this.difficulty) {
      case '简单':
        this.currentCodes = MorseCodeData.englishAlphabet
        break
      case '中等':
        this.currentCodes = [
          ...MorseCodeData.englishAlphabet,
          ...MorseCodeData.numbers
        ]
        break
      case '困难':
        // Exclude Chinese characters; include only English letters, numbers, and common symbols
        this.currentCodes = [
          ...MorseCodeData.englishAlphabet,
          ...MorseCodeData.numbers,
          ...MorseCodeData.punctuation,
        ]
        break
    }
    // Reset session completion tracking when loading new code set
    this.completionCount = new Map()
    this.hadIncorrectOnCompletion = new Map()
    this.currentIndex = -1
    this.generateNewCharacter()
  }

  // Generate new character for practice
  generateNewCharacter(): void {
    if (this.currentCodes.length === 0) return

    // Pick a random index and remember it so we can mark practiced later
    this.currentIndex = Math.floor(Math.random() * this.currentCodes.length)
    const randomCode = this.currentCodes[this.currentIndex]
    this.currentCharacter = randomCode.character
    this.currentMorse = randomCode.morse
    this.userInput = ''
    this.showResult = false
    this.isCorrect = false
    this.hintRevealed = false
    this.isFavorite = false
    this.correctCount = 0 // Reset correct count for new character
    this.showCorrectAnswer = false
    this.hasIncorrectAttempt = false // Reset incorrect attempt flag
    this.showHint = false
    this.characterChangeId++ // 增加字符变化ID以触发动画
  }

  // Add dot to user input
  addDot(): void {
    // TODO: Add vibration feedback
    this.userInput += '.'
    this.startAutoCheck()
  }

  // Add dash to user input
  addDash(): void {
    // TODO: Add vibration feedback
    this.userInput += '-'
    this.startAutoCheck()
  }

  // Start auto-check timer
  private startAutoCheck(): void {
    if (this.checkTimer !== null) {
      clearTimeout(this.checkTimer)
    }
    this.checkTimer = setTimeout(() => {
      this.checkAnswer()
    }, 600)
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
      // Wrong answer, show system toast at bottom
      promptAction.showToast({
        message: '再试一次',
        duration: 1500
        // Remove bottom property to show at default bottom position
      })
      
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

  // Toggle favorite status
  toggleFavorite(): void {
    this.isFavorite = !this.isFavorite
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
