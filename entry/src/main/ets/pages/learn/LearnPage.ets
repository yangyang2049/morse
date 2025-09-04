import { LearnViewModel } from '../../viewmodel/LearnViewModel'
import { LessonItem } from '../../types/LessonTypes'
import { router } from '@kit.ArkUI'
import window from '@ohos.window'

@Component
export struct LearnPage {
  private scroller: Scroller = new Scroller()
  @State vm: LearnViewModel = new LearnViewModel()
  @State private isInitialized: boolean = false

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
        this.isInitialized = true
        console.error('[LEARN] aboutToAppear: initialized')
      })
    }
  }

  onPageShow(): void {
    // Refresh state when returning to this page
    console.error('[LEARN] onPageShow: refreshing state')
    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()
    if (hostContext) {
      this.vm.loadUnlockState(hostContext)
    }
  }

  aboutToDisappear(): void {
    console.error('[LEARN] aboutToDisappear')
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
          router.push({
            url: 'pages/learn/KnowledgeLessonPage',
            params: {
              title: '中文摩尔斯电码',
              testTitle: '中文电码测试',
              lessonCompletedKey: '2'
            }
          })
        } else if (item.key.startsWith('intro_')) {
          // Navigate to lesson page for the 1st intro lesson (Basics)
          console.error('[LEARN] Navigating to Intro lesson page')
          router.push({
            url: 'pages/learn/KnowledgeLessonPage',
            params: {
              title: '摩斯密码基础课程',
              testTitle: '基础知识测试',
              lessonCompletedKey: '1'
            }
          })
        } else if (item.key.startsWith('alpha_')) {
          // 字母课程 - 路由到LetterLessonPage
          const lessonIndex = parseInt(item.key.replace('alpha_', ''))
          const lessonNumber = 3 + lessonIndex // 字母课程从第3课开始
          console.error(`[LEARN] Navigating to alphabet lesson: ${lessonNumber}`)
          router.push({
            url: 'pages/learn/LetterLessonPage',
            params: {
              lessonId: lessonNumber.toString(),
              title: item.title
            }
          })
        } else if (item.key.startsWith('num_')) {
          // 数字课程 - 路由到LetterLessonPage
          const lessonIndex = parseInt(item.key.replace('num_', ''))
          const lessonId = `number_lesson_${lessonIndex}`
          console.error(`[LEARN] Navigating to number lesson: ${lessonId}`)
          router.push({
            url: 'pages/learn/LetterLessonPage',
            params: {
              lessonId: lessonId,
              title: item.title
            }
          })
        } else if (item.key.startsWith('pun_')) {
          // 符号课程 - 路由到LetterLessonPage
          const lessonIndex = parseInt(item.key.replace('pun_', ''))
          const lessonId = `punctuation_lesson_${lessonIndex}`
          console.error(`[LEARN] Navigating to punctuation lesson: ${lessonId}`)
          router.push({
            url: 'pages/learn/LetterLessonPage',
            params: {
              lessonId: lessonId,
              title: item.title
            }
          })
        } else if (item.key.startsWith('word_')) {
          // 单词课程 - 路由到LetterLessonPage
          const lessonIndex = parseInt(item.key.replace('word_', ''))
          const lessonId = `word_lesson_${lessonIndex}`
          console.error(`[LEARN] Navigating to word lesson: ${lessonId}`)
          router.push({
            url: 'pages/learn/LetterLessonPage',
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
            Column() { this.UnitCard('摩斯密码基础', 1, this.vm.introLessons, true) }
              .width(320).height(500).margin({ right: 16 })

            // Alphabet unit (9)
            Column() { this.UnitCard('字母', 2, this.vm.alphabetLessons, this.vm.unitUnlocked.get('alphabet') ?? false) }
              .width(320).height(500).margin({ right: 16 })

            // Numbers unit (4)
            Column() { this.UnitCard('数字', 3, this.vm.numberLessons, this.vm.unitUnlocked.get('numbers') ?? false) }
              .width(320).height(500).margin({ right: 16 })

            // Punctuation unit (3 + pad)
            Column() { this.UnitCard('符号', 4, this.vm.punctuationLessons, this.vm.unitUnlocked.get('punctuation') ?? false) }
              .width(320).height(500).margin({ right: 16 })

            // Words unit (3 + pad)
            Column() { this.UnitCard('单词', 5, this.vm.wordLessons, this.vm.unitUnlocked.get('words') ?? false) }
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
