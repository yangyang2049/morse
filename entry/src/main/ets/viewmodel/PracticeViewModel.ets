import { MorseCode, MorseCodeData } from '../models/MorseCode'

@Observed
export class PracticeViewModel {
  // Game state
  currentCharacter: string = ''
  currentMorse: string = ''
  userInput: string = ''
  isCorrect: boolean = false
  showResult: boolean = false
  hintRevealed: boolean = false
  showCorrectAnswer: boolean = false
  showHint: boolean = false
  isFavorite: boolean = false
  correctCount: number = 0
  difficulty: string = '简单'
  hasIncorrectAttempt: boolean = false
  
  // Progress tracking
  progress: number = 0.0
  currentCodes: MorseCode[] = []
  currentIndex: number = 0
  completionCount: Map<number, number> = new Map()
  hadIncorrectOnCompletion: Map<number, boolean> = new Map()
  
  // Timers
  private checkTimer: number | null = null
  private hintTimer: number | null = null
  

  // Getters
  get requiredAttempts(): number {
    return this.hasIncorrectAttempt ? 2 : 1
  }

  get hadIncorrect(): Map<number, boolean> {
    return this.hadIncorrectOnCompletion
  }

  init(): void {
    this.initializePractice('简单')
  }

  // Initialize practice session
  initializePractice(difficulty: string): void {
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
  }

  // Add dot to user input
  addDot(): void {
    this.userInput += '.'
    this.startAutoCheck()
  }

  // Add dash to user input
  addDash(): void {
    this.userInput += '-'
    this.startAutoCheck()
  }

  // Start auto-check timer
  private startAutoCheck(): void {
    if (this.checkTimer) {
      clearTimeout(this.checkTimer)
    }
    this.checkTimer = setTimeout(() => {
      this.checkAnswer()
    }, 800)
  }

  // Check if the answer is correct
  checkAnswer(): void {
    if (this.userInput.trim().length === 0) return

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
      // Wrong answer, mark that user made incorrect attempt (if not already marked)
      if (!this.hasIncorrectAttempt) {
        this.hasIncorrectAttempt = true
        this.correctCount = 0 // Only reset counter on first incorrect attempt
      }
      // After 1 second, show correct answer
      setTimeout(() => {
        this.showCorrectAnswer = true
      }, 1000)
      // Auto-hide error note after 2 seconds total (1 second red + 1 second correct answer)
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

  // Show hint for 1 second
  flashHint(): void {
    if (this.hintTimer) {
      clearTimeout(this.hintTimer)
    }
    this.showHint = true

    this.hintTimer = setTimeout(() => {
      this.showHint = false
    }, 1000)
  }

  // Play morse code audio (stubbed)
  playMorseCode(): void {}

  // Change difficulty
  changeDifficulty(newDifficulty: string): void {
    if (this.difficulty !== newDifficulty) {
      this.difficulty = newDifficulty
      this.loadCodes()
    }
  }

  // Legacy methods for compatibility
  next(): void {
    this.passCharacter()
  }

  private normalizeDots(s: string): string {
    // convert middle dot to '.' for comparison
    return s.split('·').join('.')
  }

  private evaluate(): void {
    const target = this.currentMorse
    const input = this.normalizeDots(this.userInput)
    // correctness when input equals target
    if (input === target) {
      this.isCorrect = true
      this.showResult = true
      this.progress = 1.0
    } else {
      this.isCorrect = false
      // Simple progress: proportion of matched prefix
      let matched = 0
      const n = Math.min(input.length, target.length)
      for (let i = 0; i < n; i++) {
        if (input[i] === target[i]) matched++
        else break
      }
      this.progress = target.length > 0 ? matched / target.length : 0
      this.showResult = input.length >= target.length
    }
  }

  // Cleanup timers
  destroy(): void {
    if (this.checkTimer) {
      clearTimeout(this.checkTimer)
    }
    if (this.hintTimer) {
      clearTimeout(this.hintTimer)
    }
    // no-op
  }
}
