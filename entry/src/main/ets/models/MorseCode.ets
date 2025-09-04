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
  // 简单的中文转拼音映射表（常用字）
  private static chineseToPinyin: Map<string, string> = new Map([
    // 常用汉字拼音映射
    ['你', 'NI'], ['好', 'HAO'], ['我', 'WO'], ['是', 'SHI'], ['的', 'DE'],
    ['在', 'ZAI'], ['有', 'YOU'], ['不', 'BU'], ['了', 'LE'], ['人', 'REN'],
    ['他', 'TA'], ['她', 'TA'], ['它', 'TA'], ['这', 'ZHE'], ['那', 'NA'],
    ['什', 'SHEN'], ['么', 'ME'], ['时', 'SHI'], ['候', 'HOU'], ['地', 'DI'],
    ['方', 'FANG'], ['年', 'NIAN'], ['月', 'YUE'], ['日', 'RI'], ['天', 'TIAN'],
    ['上', 'SHANG'], ['下', 'XIA'], ['左', 'ZUO'], ['右', 'YOU'], ['前', 'QIAN'],
    ['后', 'HOU'], ['中', 'ZHONG'], ['国', 'GUO'], ['家', 'JIA'], ['学', 'XUE'],
    ['校', 'XIAO'], ['老', 'LAO'], ['师', 'SHI'], ['同', 'TONG'], ['学', 'XUE'],
    ['朋', 'PENG'], ['友', 'YOU'], ['爱', 'AI'], ['喜', 'XI'], ['欢', 'HUAN'],
    ['吃', 'CHI'], ['喝', 'HE'], ['睡', 'SHUI'], ['觉', 'JIAO'], ['工', 'GONG'],
    ['作', 'ZUO'], ['学', 'XUE'], ['习', 'XI'], ['看', 'KAN'], ['书', 'SHU'],
    ['电', 'DIAN'], ['话', 'HUA'], ['手', 'SHOU'], ['机', 'JI'], ['电', 'DIAN'],
    ['脑', 'NAO'], ['网', 'WANG'], ['络', 'LUO'], ['信', 'XIN'], ['息', 'XI'],
    ['摩', 'MO'], ['斯', 'SI'], ['密', 'MI'], ['码', 'MA'], ['练', 'LIAN'],
    ['习', 'XI'], ['学', 'XUE'], ['会', 'HUI'], ['知', 'ZHI'], ['道', 'DAO']
  ])

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

  // 检查是否为中文字符
  private static isChinese(char: string): boolean {
    return /[\u4e00-\u9fff]/.test(char)
  }

  // 将中文字符转换为拼音
  private static chineseToPinyinString(char: string): string | null {
    return MorseCodeData.chineseToPinyin.get(char) || null
  }

  static textToMorse(text: string, onChineseNotFound?: (char: string) => void): string {
    const codes = MorseCodeData.getAllCodes()
    const result: string[] = []
    
    for (let i = 0; i < text.length; i++) {
      const ch = text[i]
      
      if (ch === ' ') {
        result.push('/')
        continue
      }
      
      // 检查是否为中文字符
      if (MorseCodeData.isChinese(ch)) {
        const pinyin = MorseCodeData.chineseToPinyinString(ch)
        if (pinyin) {
          // 将拼音转换为摩斯码
          const pinyinMorse: string[] = []
          for (let j = 0; j < pinyin.length; j++) {
            const pinyinChar = pinyin[j]
            const found = codes.find(c => c.character === pinyinChar)
            if (found) {
              pinyinMorse.push(found.morse.split('.').join('·'))
            }
          }
          if (pinyinMorse.length > 0) {
            result.push(pinyinMorse.join(' '))
          } else {
            result.push(ch) // 如果拼音无法转换，保持原字符
          }
        } else {
          // 中文字符不在拼音表中，保持原样并触发回调
          result.push(ch)
          if (onChineseNotFound) {
            onChineseNotFound(ch)
          }
        }
      } else {
        // 处理英文字符
        const searchChar = ch.toUpperCase()
        const found = codes.find(c => c.character === searchChar)
        if (found) {
          result.push(found.morse.split('.').join('·'))
        } else {
          result.push(ch)
        }
      }
      
      // 添加字符间隔
      if (i < text.length - 1 && text[i + 1] !== ' ') {
        result.push(' ')
      }
    }
    return result.join('')
  }

  static morseToText(morse: string): string {
    const codes = MorseCodeData.getAllCodes()
    const normalized = morse.split('·').join('.')
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
