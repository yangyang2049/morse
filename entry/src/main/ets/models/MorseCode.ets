export class MorseCode {
  character: string
  morse: string
  description?: string

  constructor(character: string, morse: string, description?: string) {
    this.character = character
    this.morse = morse
    this.description = description
  }
}

export class MorseCodeData {
  static englishAlphabet: MorseCode[] = [
    new MorseCode('A', '.-', 'Alpha'),
    new MorseCode('B', '-...', 'Bravo'),
    new MorseCode('C', '-.-.', 'Charlie'),
    new MorseCode('D', '-..', 'Delta'),
    new MorseCode('E', '.', 'Echo'),
    new MorseCode('F', '..-.', 'Foxtrot'),
    new MorseCode('G', '--.', 'Golf'),
    new MorseCode('H', '....', 'Hotel'),
    new MorseCode('I', '..', 'India'),
    new MorseCode('J', '.---', 'Juliet'),
    new MorseCode('K', '-.-', 'Kilo'),
    new MorseCode('L', '.-..', 'Lima'),
    new MorseCode('M', '--', 'Mike'),
    new MorseCode('N', '-.', 'November'),
    new MorseCode('O', '---', 'Oscar'),
    new MorseCode('P', '.--.', 'Papa'),
    new MorseCode('Q', '--.-', 'Quebec'),
    new MorseCode('R', '.-.', 'Romeo'),
    new MorseCode('S', '...', 'Sierra'),
    new MorseCode('T', '-', 'Tango'),
    new MorseCode('U', '..-', 'Uniform'),
    new MorseCode('V', '...-', 'Victor'),
    new MorseCode('W', '.--', 'Whiskey'),
    new MorseCode('X', '-..-', 'X-ray'),
    new MorseCode('Y', '-.--', 'Yankee'),
    new MorseCode('Z', '--..', 'Zulu'),
  ]

  static numbers: MorseCode[] = [
    new MorseCode('0', '-----'),
    new MorseCode('1', '.----'),
    new MorseCode('2', '..---'),
    new MorseCode('3', '...--'),
    new MorseCode('4', '....-'),
    new MorseCode('5', '.....'),
    new MorseCode('6', '-....'),
    new MorseCode('7', '--...'),
    new MorseCode('8', '---..'),
    new MorseCode('9', '----.'),
  ]

  static punctuation: MorseCode[] = [
    new MorseCode('.', '.-.-.-'),
    new MorseCode(',', '--..--'),
    new MorseCode('?', '..--..'),
    new MorseCode('!', '-.-.--'),
    new MorseCode(':', '---...'),
    new MorseCode(';', '-.-.-.'),
    new MorseCode('=', '-...-'),
    new MorseCode('+', '.-.-.'),
    new MorseCode('-', '-....-'),
    new MorseCode('_', '..--.-'),
    new MorseCode('"', '.-..-.'),
    new MorseCode("'", '.----.'),
    new MorseCode('(', '-.--.'),
    new MorseCode(')', '-.--.-'),
    new MorseCode('/', '-..-.'),
    new MorseCode('@', '.--.-.'),
  ]

  static getAllCodes(): MorseCode[] {
    return [...MorseCodeData.englishAlphabet, ...MorseCodeData.numbers, ...MorseCodeData.punctuation]
  }

  static textToMorse(text: string): string {
    const codes = MorseCodeData.getAllCodes()
    const result: string[] = []
    for (let i = 0; i < text.length; i++) {
      const ch = text[i]
      const searchChar = ch.toUpperCase()
      if (ch === ' ') {
        result.push('/')
        continue
      }
      const found = codes.find(c => c.character === searchChar)
      if (found) {
        result.push(found.morse.replaceAll('.', '·'))
      } else {
        result.push(ch)
      }
      if (i < text.length - 1 && text[i + 1] !== ' ') {
        result.push(' ')
      }
    }
    return result.join('')
  }

  static morseToText(morse: string): string {
    const codes = MorseCodeData.getAllCodes()
    const normalized = morse.replaceAll('·', '.')
    const words = normalized.split('/')
    const outWords: string[] = []
    for (const word of words) {
      const letters = word.trim().split(' ')
      const buf: string[] = []
      for (const letter of letters) {
        if (!letter) continue
        const found = codes.find(c => c.morse === letter)
        buf.push(found ? found.character : letter)
      }
      outWords.push(buf.join(''))
    }
    return outWords.join(' ')
  }
}
