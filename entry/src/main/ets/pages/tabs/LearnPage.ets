import { LearnViewModel } from '../../viewmodel/LearnViewModel'
import { router } from '@kit.ArkUI'
import window from '@ohos.window'
import { LessonConfig } from '../../data/LessonConfig'
import emitter from '@ohos.events.emitter'

interface LessonItem {
  key: string
  title: string
  subtitle?: string
  unlocked: boolean
  unitUnlocked: boolean
  completed: boolean
}

@Component
export struct LearnPage {
  private scroller: Scroller = new Scroller()
  @State vm: LearnViewModel = new LearnViewModel()
  @State private refreshTick: number = 0
  @State private refreshKey: number = 0  // Force refresh key
  @State private isInitialized: boolean = false  // Track initialization state
  @State private introLessonsData: LessonItem[] = []  // Cached lessons data
  @State private alphabetLessonsData: LessonItem[] = []  // Cached alphabet lessons
  @State private numberLessonsData: LessonItem[] = []  // Cached number lessons
  @State private punctuationLessonsData: LessonItem[] = []  // Cached punctuation lessons
  @State private wordLessonsData: LessonItem[] = []  // Cached word lessons

  aboutToAppear(): void {
    // Set status bar color
    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()
    if (hostContext) {
      window.getLastWindow(hostContext).then((windowClass) => {
        windowClass.setWindowSystemBarProperties({
          statusBarColor: '#000000',
          statusBarContentColor: '#FFFFFF'
        })
      })
    }

    console.error('[LEARN] aboutToAppear: init()')
    const uiContext2 = this.getUIContext()
    const hostContext2 = uiContext2.getHostContext()
    if (hostContext2) {
      this.vm.init(hostContext2).then(() => {
        this.refreshTick++
        this.isInitialized = true  // Mark as initialized
        this.updateAllLessonData()  // Update lesson data after initialization
        console.error(`[LEARN] aboutToAppear: refreshed after init, tick=${this.refreshTick}`)
      })
    }

    // 订阅课程完成事件，强制刷新页面
    this.subscribeToProgressUpdates()
  }

  onPageShow(): void {
    // Refresh state when returning to this page
    console.error('[LEARN] onPageShow: loadUnlockState() immediate')
    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()
    if (hostContext) {
      this.vm.loadUnlockState(hostContext).then(() => {
        this.updateAllLessonData()  // Update lesson data after loading state
        this.refreshTick++
        console.error(`[LEARN] onPageShow: refreshed immediate, tick=${this.refreshTick}`)
      })
      // In case of async preference flush race, refresh again shortly after
      setTimeout(() => {
        console.error('[LEARN] onPageShow: loadUnlockState() delayed 100ms')
        this.vm.loadUnlockState(hostContext).then(() => {
          this.updateAllLessonData()  // Update lesson data after delayed loading
          this.refreshTick++
          console.error(`[LEARN] onPageShow: refreshed delayed, tick=${this.refreshTick}`)
        })
      }, 100)
    }
  }

  private updateAllLessonData(): void {
    console.error('[LEARN] Updating all lesson data')
    this.introLessonsData = this.introLessons()
    this.alphabetLessonsData = this.alphabetLessons()
    this.numberLessonsData = this.numberLessons()
    this.punctuationLessonsData = this.punctuationLessons()
    this.wordLessonsData = this.wordLessons()
    
    // Log the updated lesson data for debugging
    console.error(`[LEARN] Updated lesson data - intro: ${this.introLessonsData.length} lessons, first lesson unlocked=${this.introLessonsData[0]?.unlocked}, second lesson unlocked=${this.introLessonsData[1]?.unlocked}`)
    console.error(`[LEARN] Updated lesson data - alphabet: ${this.alphabetLessonsData.length} lessons, first lesson unlocked=${this.alphabetLessonsData[0]?.unlocked}`)
    console.error(`[LEARN] Updated lesson data - numbers: ${this.numberLessonsData.length} lessons, first lesson unlocked=${this.numberLessonsData[0]?.unlocked}`)
  }

  private subscribeToProgressUpdates(): void {
    try {
      console.error('[LEARN-TABS] subscribeToProgressUpdates: Starting subscription to LESSON_PROGRESS_UPDATED')
      emitter.on('LESSON_PROGRESS_UPDATED', async (data?: emitter.EventData) => {
        console.error('[LEARN-TABS] Progress update event received, forcing refresh')
        
        const uiContext = this.getUIContext()
        const hostContext = uiContext.getHostContext()
        if (hostContext) {
          console.error('[LEARN-TABS] HostContext available, starting refresh process')
          // 重新加载状态
          console.error('[LEARN-TABS] Loading unlock state...')
          await this.vm.loadUnlockState(hostContext)
          console.error('[LEARN-TABS] Unlock state loaded, updating lesson data...')
          // 更新所有课程数据
          this.updateAllLessonData()
          // 强制刷新整个页面
          this.refreshKey++
          this.refreshTick++
          console.error(`[LEARN-TABS] Forced refresh completed, refreshKey=${this.refreshKey}, tick=${this.refreshTick}`)
          console.error(`[LEARN-TABS] Current unit states: intro=${this.vm.unitUnlocked.get('intro')}, alphabet=${this.vm.unitUnlocked.get('alphabet')}, numbers=${this.vm.unitUnlocked.get('numbers')}`)
        } else {
          console.error('[LEARN-TABS] No hostContext available for refresh')
        }
      })
      console.error('[LEARN-TABS] Successfully subscribed to progress update events')
    } catch (e) {
      console.error('[LEARN-TABS] Failed to subscribe to progress updates:', e)
    }
  }

  aboutToDisappear(): void {
    // 取消订阅，避免内存泄露
    try {
      console.error('[LEARN-TABS] aboutToDisappear: Unsubscribing from progress update events')
      emitter.off('LESSON_PROGRESS_UPDATED')
      console.error('[LEARN-TABS] Successfully unsubscribed from progress update events')
    } catch (e) {
      console.error('[LEARN-TABS] Failed to unsubscribe from progress updates:', e)
    }
  }

  private introLessons(): LessonItem[] {
    // Reference refreshKey to make this method reactive to state changes
    const _ = this.refreshKey
    
    const lesson1Unlocked = this.vm.isLessonUnlocked(1)
    const lesson1Completed = this.vm.isLessonCompleted(1)
    const lesson2Unlocked = this.vm.isLessonUnlocked(2)
    const lesson2Completed = this.vm.isLessonCompleted(2)
    
    console.error(`[LEARN] introLessons: lesson1 unlocked=${lesson1Unlocked} completed=${lesson1Completed}`)
    console.error(`[LEARN] introLessons: lesson2 unlocked=${lesson2Unlocked} completed=${lesson2Completed}`)
    
    return [
      { 
        key: 'intro_0', 
        title: '第 1 课', 
        subtitle: '摩斯密码基础', 
        unlocked: lesson1Unlocked, 
        unitUnlocked: this.vm.unitUnlocked.get('intro') ?? false, 
        completed: lesson1Completed 
      },
      { 
        key: 'intro_1', 
        title: '第 2 课', 
        subtitle: '中文摩斯密码基础', 
        unlocked: lesson2Unlocked, 
        unitUnlocked: this.vm.unitUnlocked.get('intro') ?? false, 
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

  private alphabetLessons(): LessonItem[] {
    const items: LessonItem[] = []
    // 在字母分组之间加入空格，风格与数字课程一致
    const subtitles: string[] = ['A B C', 'D E F', 'G H I J', '复习：A - J', 'K L M N', 'O P Q R', 'S T U V', 'W X Y Z', '复习：K - Z']
    
    for (let i = 0; i < 9; i++) {
      const lessonNumber = 3 + i // 字母课程从第3课开始
      const isReview = i === 3 || i === 8
      
      items.push({
        key: `alpha_${i}`,
        title: `第 ${i + 1} 课`,
        subtitle: subtitles[i],
        unlocked: this.vm.isLessonUnlocked(lessonNumber),
        unitUnlocked: this.vm.unitUnlocked.get('alphabet') ?? false,
        completed: this.vm.isLessonCompleted(lessonNumber)
      })
    }
    
    // Add placeholder lessons as completed
    items.push({ key: 'alpha_p1', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    items.push({ key: 'alpha_p2', title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    return items
  }

  private numberLessons(): LessonItem[] {
    const subtitles: string[] = ['1 2 3', '4 5 6', '7 8 9 0', '复习：0-9']
    const items: LessonItem[] = []
    
    for (let i = 0; i < 4; i++) {
      const lessonNumber = 12 + i // 数字课程从第12课开始
      const isReview = i === 3
      
      items.push({
        key: `num_${i}`,
        title: `第 ${i + 1} 课`,
        subtitle: subtitles[i],
        unlocked: this.vm.isLessonUnlocked(lessonNumber),
        unitUnlocked: this.vm.unitUnlocked.get('numbers') ?? false,
        completed: this.vm.isLessonCompleted(lessonNumber)
      })
    }
    
    // Pad up to 6 entries with placeholder lessons as completed
    while (items.length < 6) {
      items.push({ key: `num_p${items.length}`, title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    }
    return items
  }

  private punctuationLessons(): LessonItem[] {
    // 在符号之间加入空格，确保每个符号独立展示
    const subtitles: string[] = ['. , ? ! : ;', '= + - _ " \' , ( ) / @', '复习']
    const items: LessonItem[] = []
    
    for (let i = 0; i < 3; i++) {
      const lessonNumber = 16 + i // 符号课程从第16课开始
      
      items.push({
        key: `pun_${i}`,
        title: `第 ${i + 1} 课`,
        subtitle: subtitles[i],
        unlocked: this.vm.isLessonUnlocked(lessonNumber),
        unitUnlocked: this.vm.unitUnlocked.get('punctuation') ?? false,
        completed: this.vm.isLessonCompleted(lessonNumber)
      })
    }
    
    // Pad up to 6 entries with placeholder lessons as completed
    while (items.length < 6) {
      items.push({ key: `pun_p${items.length}`, title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    }
    return items
  }

  private wordLessons(): LessonItem[] {
    const items: LessonItem[] = []
    
    for (let i = 0; i < 3; i++) {
      const lessonNumber = 19 + i // 单词课程从第19课开始
      
      items.push({
        key: `word_${i}`,
        title: `第 ${i + 1} 课`,
        subtitle: `${i + 3}字母单词`,
        unlocked: this.vm.isLessonUnlocked(lessonNumber),
        unitUnlocked: this.vm.unitUnlocked.get('words') ?? false,
        completed: this.vm.isLessonCompleted(lessonNumber)
      })
    }
    
    // Pad up to 6 entries with placeholder lessons as completed
    while (items.length < 6) {
      items.push({ key: `word_p${items.length}`, title: '占位', unlocked: true, unitUnlocked: true, completed: true })
    }
    return items
  }

  @Builder
  private LessonCard(item: LessonItem, unitLocked: boolean) {
    Row() {
      Column() {
        Text(item.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor((!unitLocked && item.unlocked) ? Color.White : '#B0B0B0') // Gray when lesson or unit locked
          .margin({ bottom: item.subtitle ? 8 : 0 })

        if (item.subtitle) {
          Text(item.subtitle)
            .fontSize(14)
            .fontColor((!unitLocked && item.unlocked) ? '#B0B0B0' : '#808080') // Gray for locked
        }
      }
      .layoutWeight(1)

      // Icon logic: when unit is locked, suppress per-lesson icon (just gray out);
      // otherwise show ✓ for completed, › for next unlocked, 🔒 for locked lesson
      if (unitLocked) {
        Text('').fontSize(16)
      } else if (item.completed) {
        Text('✓').fontSize(20).fontColor(Color.Green)
      } else if (item.unlocked) {
        Text('›').fontSize(16).fontColor(Color.White)
      } else {
        Text('🔒').fontSize(16).fontColor('#FFFFFF80')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1A1A1A')
    .border({ width: 1, color: '#333333' })
    .borderRadius(12)
    .opacity((!unitLocked && item.unlocked) ? 1.0 : 0.6) // Gray out locked or unit-locked lessons
    .onClick(() => {
      // Only navigate if the lesson and unit are unlocked
      if (!unitLocked && item.unlocked) {
        console.error(`[LEARN] LessonCard click: key=${item.key} unlocked=${item.unlocked} unitLocked=${unitLocked}`)
        if (item.key === 'intro_1') {
          // Navigate to lesson page for the 2nd intro lesson (Chinese)
          console.error('[LEARN] Navigating to Chinese lesson page')
          router.pushUrl({
            url: 'pages/LessonPage',
            params: {
              title: '中文摩尔斯电码',
              testType: 'chinese',
              testTitle: '中文电码测试',
              testCompletedKey: 'chinese_test_completed',
              lessonCompletedKey: 'chinese_completed'
            }
          })
        } else if (item.key.startsWith('intro_')) {
          // Navigate to lesson page for the 1st intro lesson (Basics)
          console.error('[LEARN] Navigating to Intro lesson page')
          router.pushUrl({
            url: 'pages/LessonPage',
            params: {
              title: '摩斯密码基础课程',
              testType: 'intro',
              testTitle: '基础知识测试',
              testCompletedKey: 'intro_test_completed',
              lessonCompletedKey: 'intro_completed'
            }
          })
        } else if (item.key.startsWith('alpha_')) {
          // 字母课程 - 路由到LetterLessonPage
          const lessonIndex = parseInt(item.key.replace('alpha_', ''))
          const lessonId = `alpha_${lessonIndex}`
          console.error(`[LEARN] Navigating to alphabet lesson: ${lessonId}`)
          router.pushUrl({
            url: 'pages/LetterLessonPage',
            params: {
              lessonId: lessonId,
              title: item.title
            }
          })
        } else if (item.key.startsWith('num_')) {
          // 数字课程 - 路由到LetterLessonPage
          const lessonIndex = parseInt(item.key.replace('num_', ''))
          const lessonId = `num_${lessonIndex}`
          console.error(`[LEARN] Navigating to number lesson: ${lessonId}`)
          router.pushUrl({
            url: 'pages/LetterLessonPage',
            params: {
              lessonId: lessonId,
              title: item.title
            }
          })
        } else if (item.key.startsWith('pun_')) {
          // 符号课程 - 路由到LetterLessonPage
          const lessonIndex = parseInt(item.key.replace('pun_', ''))
          const lessonId = `pun_${lessonIndex}`
          console.error(`[LEARN] Navigating to punctuation lesson: ${lessonId}`)
          router.pushUrl({
            url: 'pages/LetterLessonPage',
            params: {
              lessonId: lessonId,
              title: item.title
            }
          })
        } else if (item.key.startsWith('word_')) {
          // 单词课程 - 路由到LetterLessonPage
          const lessonIndex = parseInt(item.key.replace('word_', ''))
          const lessonId = `word_${lessonIndex}`
          console.error(`[LEARN] Navigating to word lesson: ${lessonId}`)
          router.pushUrl({
            url: 'pages/LetterLessonPage',
            params: {
              lessonId: lessonId,
              title: item.title
            }
          })
        } else {
          // For other lessons, show a placeholder message
          console.error(`[LEARN] Navigating to other lesson: ${item.key}`)
        }
      }
    })
  }

  @Builder
  private UnitCard(title: string, unitNumber: number, lessons: LessonItem[], isUnlocked: boolean) {
    RelativeContainer() {
      // Reference anchor filling the card (use empty Column due to Blank restriction)
      Column() {}
        .id('card')
        .width('100%')
        .height('100%')

      // Big faded number anchored to bottom-right of the card
      Text(`${unitNumber}`)
        .fontSize(80)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .opacity(0.25)  // 25% opacity
        .alignRules({
          bottom: { anchor: 'card', align: VerticalAlign.Bottom },
          right:  { anchor: 'card', align: HorizontalAlign.End }
        })
        .margin({ right: 0, bottom: -10 })  // Negative bottom margin to move it closer
        .zIndex(0)

      Column()
        .alignRules({
          top:  { anchor: 'card', align: VerticalAlign.Top },
          left: { anchor: 'card', align: HorizontalAlign.Start }
        })
        .zIndex(1)
      {
        Row() {
          Text(title)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          if (!isUnlocked) {
            Text('🔒').fontSize(24).fontColor('#FFFFFF99')
          }
        }
        .margin({ top: 24, bottom: 32 })

        // Lessons list (scroll within card); render placeholders with opacity 0 to keep vertical alignment
        Scroll() {
          Column() {
            ForEach(lessons, (l: LessonItem, idx: number) => {
              Column() {
                this.LessonCard(l, !isUnlocked) // Pass unit lock status
                if (idx < lessons.length - 1) { Blank().height(12) }
              }
              .opacity(l.title === '占位' ? 0.0 : 1.0)
            }, (l: LessonItem) => `${l.key}-${l.unlocked ? 'u' : 'l'}-${l.completed ? 'c' : 'n'}`)
          }
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)  // 移除滚动条
        .edgeEffect(EdgeEffect.Spring)  // 添加弹性效果
        .opacity(isUnlocked ? 1.0 : 0.45)
        .enabled(isUnlocked)  // 禁用滚动如果单元未解锁
      }
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .backgroundColor('#1A1A1A')
    .border({ width: 1, color: '#333333' })
    .borderRadius(12)
    .onClick(() => {
      if (!isUnlocked) {
        // 可以添加一个提示，告知用户需要先解锁该单元
        console.info(`单元 ${unitNumber} 尚未解锁`)
      }
    })
  }

  build() {
    Column() {
      // Invisible tick to force recomposition when refreshTick or refreshKey changes
      Text('')
        .opacity(0)
        .fontSize(1)
        .id(`tick-${this.refreshTick}-key-${this.refreshKey}`)
      
      if (this.isInitialized) {
        // Title bar
        Row() {
          Text('学习')
            .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        
      }
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.Black)

      // Horizontal scroll of unit cards
      Scroll(this.scroller) {
        Row() {
          // Intro unit (2 lessons + padding)
          Column() { this.UnitCard('摩斯密码基础', 1, this.introLessonsData, true) }
            .width(320).height(500).margin({ right: 16 })

          // Alphabet unit (9)
          Column() { this.UnitCard('字母', 2, this.alphabetLessonsData, this.vm.unitUnlocked.get('alphabet') ?? false) }
            .width(320).height(500).margin({ right: 16 })

          // Numbers unit (4)
          Column() { this.UnitCard('数字', 3, this.numberLessonsData, this.vm.unitUnlocked.get('numbers') ?? false) }
            .width(320).height(500).margin({ right: 16 })

          // Punctuation unit (3 + pad)
          Column() { this.UnitCard('符号', 4, this.punctuationLessonsData, this.vm.unitUnlocked.get('punctuation') ?? false) }
            .width(320).height(500).margin({ right: 16 })

          // Words unit (3 + pad)
          Column() { this.UnitCard('单词', 5, this.wordLessonsData, this.vm.unitUnlocked.get('words') ?? false) }
            .width(320).height(500)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 16, bottom: 24 })
      } else {
        // Loading state
        Column() {
          Text('加载中...')
            .fontSize(16)
            .fontColor(Color.White)
            .margin({ top: 200 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
