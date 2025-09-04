import util from '@ohos.util'
import Context from '@ohos.app.ability.common'

export class PinyinService {
  private static loaded: boolean = false
  private static charMap: Map<string, string> = new Map()
  private static toneMap: Map<string, string> = new Map([
    ['ā','a'], ['á','a'], ['ǎ','a'], ['à','a'],
    ['ē','e'], ['é','e'], ['ě','e'], ['è','e'],
    ['ī','i'], ['í','i'], ['ǐ','i'], ['ì','i'],
    ['ō','o'], ['ó','o'], ['ǒ','o'], ['ò','o'],
    ['ū','u'], ['ú','u'], ['ǔ','u'], ['ù','u'],
    ['ǖ','v'], ['ǘ','v'], ['ǚ','v'], ['ǜ','v'], ['ü','v']
  ])

  static isLoaded(): boolean {
    return PinyinService.loaded
  }

  static async load(context: Context): Promise<void> {
    if (PinyinService.loaded) return
    try {
      const data = await context.resourceManager.getRawFileContent('pinyin.txt')
      const decoder = new util.TextDecoder('utf-8')
      const content = decoder.decodeWithStream(new Uint8Array(data))
      PinyinService.parse(content)
      PinyinService.loaded = true
      console.info(`[PinyinService] Loaded pinyin.txt with ${PinyinService.charMap.size} entries`)
      
      // 测试一些常见字符
      const testChars = ['华', '民', '共', '和']
      for (const char of testChars) {
        const pinyin = PinyinService.getCharPinyin(char)
        console.info(`[PinyinService] Test: ${char} -> ${pinyin}`)
      }
    } catch (e) {
      console.error('[PinyinService] Failed to load pinyin.txt', e)
      PinyinService.loaded = true // avoid retry storm
    }
  }

  private static stripTonesAndNormalize(py: string): string {
    let out = ''
    for (let i = 0; i < py.length; i++) {
      const ch = py[i]
      const rep = PinyinService.toneMap.get(ch)
      out += rep ? rep : ch
    }
    return out.replace(/\s+/g, '').toUpperCase()
  }

  private static parse(text: string): void {
    const lines = text.split(/\r?\n/)
    for (const line of lines) {
      if (!line || line[0] !== 'U' || line.indexOf(':') < 0) continue
      
      // Format: U+4F60: nǐ
      const parts = line.split(':')
      if (parts.length < 2) continue
      const left = parts[0] // U+4F60
      const right = parts.slice(1).join(':').trim()
      const hex = left.slice(2).trim()
      
      if (!hex || !right) continue
      const cp = parseInt(hex, 16)
      if (isNaN(cp)) continue
      const char = String.fromCodePoint(cp)
      // Take first pinyin token if multiple are present (space-delimited)
      const pyRaw = right.split(/\s+/)[0]
      const py = PinyinService.stripTonesAndNormalize(pyRaw)
      if (py) PinyinService.charMap.set(char, py)
    }
  }

  static getCharPinyin(char: string): string | null {
    if (!char || char.length === 0) return null
    return PinyinService.charMap.get(char) ?? null
  }
}
