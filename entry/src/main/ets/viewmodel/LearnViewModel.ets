import { LessonData } from '../data/LessonData'
import { LessonConfig } from '../data/LessonConfig'
import { globalProgressState } from '../store/GlobalProgressState'
import { LessonItem } from '../types/LessonTypes'
import Context from '@ohos.app.ability.common'

@Observed
export class LearnViewModel {
  // 使用全局状态
  get unitUnlocked(): Map<string, boolean> {
    return globalProgressState.unitUnlocked
  }

  get targetUnitIdx(): number {
    return globalProgressState.targetUnitIdx
  }

  get targetLessonIdx(): number | null {
    return globalProgressState.targetLessonIdx
  }

  // 课程数据 - 响应式
  get introLessons(): LessonItem[] {
    // Reference global state to make this reactive
    const _ = globalProgressState.refreshKey
    
    const lesson1Unlocked = globalProgressState.isLessonUnlocked(1)
    const lesson1Completed = globalProgressState.isLessonCompleted(1)
    const lesson2Unlocked = globalProgressState.isLessonUnlocked(2)
    const lesson2Completed = globalProgressState.isLessonCompleted(2)
    
    return [
      { 
        key: 'intro_0', 
        title: '第 1 课', 
        subtitle: '摩斯密码基础', 
        unlocked: lesson1Unlocked, 
        unitUnlocked: globalProgressState.unitUnlocked.get('intro') ?? false, 
        completed: lesson1Completed 
      },
      { 
        key: 'intro_1', 
        title: '第 2 课', 
        subtitle: '中文摩斯密码基础', 
        unlocked: lesson2Unlocked, 
        unitUnlocked: globalProgressState.unitUnlocked.get('intro') ?? false, 
        completed: lesson2Completed 
      },
      { key: 'intro_p1', title: '占位', unlocked: false, unitUnlocked: false, completed: false },
      { key: 'intro_p2', title: '占位', unlocked: false, unitUnlocked: false, completed: false },
      { key: 'intro_p3', title: '占位', unlocked: false, unitUnlocked: false, completed: false },
      { key: 'intro_p4', title: '占位', unlocked: false, unitUnlocked: false, completed: false },
      { key: 'intro_p5', title: '占位', unlocked: false, unitUnlocked: false, completed: false },
      { key: 'intro_p6', title: '占位', unlocked: false, unitUnlocked: false, completed: false }
    ]
  }

  get alphabetLessons(): LessonItem[] {
    // Reference global state to make this reactive
    const _ = globalProgressState.refreshKey
    
    const items: LessonItem[] = []
    const subtitles: string[] = ['A B C', 'D E F', 'G H I J', '复习：A - J', 'K L M N', 'O P Q R', 'S T U V', 'W X Y Z', '复习：K - Z']
    
    for (let i = 0; i < 9; i++) {
      const lessonNumber = 3 + i // 字母课程从第3课开始
      
      items.push({
        key: `alpha_${i}`,
        title: `第 ${i + 1} 课`,
        subtitle: subtitles[i],
        unlocked: globalProgressState.isLessonUnlocked(lessonNumber),
        unitUnlocked: globalProgressState.unitUnlocked.get('alphabet') ?? false,
        completed: globalProgressState.isLessonCompleted(lessonNumber)
      })
    }
    
    // Add placeholder lessons
    items.push({ key: 'alpha_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    items.push({ key: 'alpha_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    return items
  }

  get numberLessons(): LessonItem[] {
    // Reference global state to make this reactive
    const _ = globalProgressState.refreshKey
    
    const subtitles: string[] = ['1 2 3', '4 5 6', '7 8 9 0', '复习：0-9']
    const items: LessonItem[] = []
    
    for (let i = 0; i < 4; i++) {
      const lessonNumber = 12 + i // 数字课程从第12课开始
      
      items.push({
        key: `num_${i}`,
        title: `第 ${i + 1} 课`,
        subtitle: subtitles[i],
        unlocked: globalProgressState.isLessonUnlocked(lessonNumber),
        unitUnlocked: globalProgressState.unitUnlocked.get('numbers') ?? false,
        completed: globalProgressState.isLessonCompleted(lessonNumber)
      })
    }
    
    // Pad up to 6 entries with placeholder lessons
    while (items.length < 6) {
      items.push({ key: `num_p${items.length}`, title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    }
    return items
  }

  get punctuationLessons(): LessonItem[] {
    // Reference global state to make this reactive
    const _ = globalProgressState.refreshKey
    
    const subtitles: string[] = ['. , ? ! : ;', '= + - _ " \' , ( ) / @', '复习']
    const items: LessonItem[] = []
    
    for (let i = 0; i < 3; i++) {
      const lessonNumber = 16 + i // 符号课程从第16课开始
      
      items.push({
        key: `pun_${i}`,
        title: `第 ${i + 1} 课`,
        subtitle: subtitles[i],
        unlocked: globalProgressState.isLessonUnlocked(lessonNumber),
        unitUnlocked: globalProgressState.unitUnlocked.get('punctuation') ?? false,
        completed: globalProgressState.isLessonCompleted(lessonNumber)
      })
    }
    
    // Pad up to 6 entries with placeholder lessons
    while (items.length < 6) {
      items.push({ key: `pun_p${items.length}`, title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    }
    return items
  }

  get wordLessons(): LessonItem[] {
    // Reference global state to make this reactive
    const _ = globalProgressState.refreshKey
    
    const items: LessonItem[] = []
    
    for (let i = 0; i < 3; i++) {
      const lessonNumber = 19 + i // 单词课程从第19课开始
      
      items.push({
        key: `word_${i}`,
        title: `第 ${i + 1} 课`,
        subtitle: `${i + 3}字母单词`,
        unlocked: globalProgressState.isLessonUnlocked(lessonNumber),
        unitUnlocked: globalProgressState.unitUnlocked.get('words') ?? false,
        completed: globalProgressState.isLessonCompleted(lessonNumber)
      })
    }
    
    // Pad up to 6 entries with placeholder lessons
    while (items.length < 6) {
      items.push({ key: `word_p${items.length}`, title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    }
    return items
  }

  async init(context: Context): Promise<void> {
    console.error('[VM] init() called')
    await globalProgressState.init(context)
  }

  async loadUnlockState(context: Context): Promise<void> {
    console.error('[VM] loadUnlockState: delegating to global state')
    await globalProgressState.loadUnlockState(context)
  }

  async markLessonCompleted(lessonNumber: number, context: Context): Promise<void> {
    console.error(`[VM] markLessonCompleted: delegating to global state for lessonNumber=${lessonNumber}`)
    await globalProgressState.markLessonCompleted(lessonNumber, context)
  }

  // 检查课程是否已解锁
  isLessonUnlocked(lessonNumber: number): boolean {
    return globalProgressState.isLessonUnlocked(lessonNumber)
  }

  // 检查课程是否已完成
  isLessonCompleted(lessonNumber: number): boolean {
    return globalProgressState.isLessonCompleted(lessonNumber)
  }

  // 根据课程ID获取课程编号
  getLessonNumber(lessonId: string): number {
    return LessonConfig.getLessonNumber(lessonId)
  }
}