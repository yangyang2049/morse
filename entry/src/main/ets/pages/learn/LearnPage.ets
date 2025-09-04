import { LearnViewModel } from '../../viewmodel/LearnViewModel'
import { LessonItem } from '../../types/LessonTypes'
import { router } from '@kit.ArkUI'
// System bar colors are set globally in EntryAbility

@Component
export struct LearnPage {
  private scroller: Scroller = new Scroller()
  @State vm: LearnViewModel = new LearnViewModel()
  @State private isInitialized: boolean = false
  @State private refreshTrigger: number = 0

  aboutToAppear(): void {
    // System bar colors are set globally in EntryAbility
    const uiContext2 = this.getUIContext()
    const hostContext2 = uiContext2.getHostContext()
    if (hostContext2) {
      // 设置页面刷新回调
      this.vm.setPageRefreshCallback(() => {
        console.error(`[LEARN] Page refresh triggered by ViewModel`)
        this.refreshTrigger++
      })
      
      this.vm.init(hostContext2).then(() => {
        this.isInitialized = true
      })
    }
  }

  onPageShow(): void {
    // Refresh state when returning to this page
    console.error(`[LEARN] onPageShow: triggered - refreshing state after lesson completion`)
    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()
    if (hostContext) {
      this.vm.loadUnlockState(hostContext).then(() => {

      }).catch((error: Error) => {
        console.error('[LEARN] onPageShow: loadUnlockState failed:', error)
      })
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
          .fontColor(Color.White)
          .margin({ bottom: item.subtitle ? 8 : 0 })

        if (item.subtitle) {
          Text(item.subtitle)
            .fontSize(14)
            .fontColor('#B0B0B0')
        }
      }
      .layoutWeight(1)

      // Icon logic: show ✓ for completed, › for available
      if (item.completed) {
        Text('✓').fontSize(20).fontColor(Color.Green)
      } else {
        Text('›').fontSize(16).fontColor(Color.White)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1A1A1A')
    .border({ width: 1, color: '#333333' })
    .borderRadius(12)
    .opacity(1.0) // All lessons are now fully visible
    .onClick(() => {
      // All lessons are now unlocked, only check if it's not a placeholder
      if (item.title !== '占位') {
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
        } else if (item.key.startsWith('number_')) {
          // 数字课程 - 路由到LetterLessonPage
          const lessonIndex = parseInt(item.key.replace('number_', ''))
          const lessonNumber = 12 + lessonIndex // 数字课程从第12课开始
          console.error(`[LEARN] Navigating to number lesson: ${lessonNumber}`)
          router.push({
            url: 'pages/learn/LetterLessonPage',
            params: {
              lessonId: lessonNumber.toString(),
              title: item.title
            }
          })
        } else if (item.key.startsWith('punctuation_')) {
          // 符号课程 - 路由到LetterLessonPage
          const lessonIndex = parseInt(item.key.replace('punctuation_', ''))
          const lessonNumber = 16 + lessonIndex // 符号课程从第16课开始
          console.error(`[LEARN] Navigating to punctuation lesson: ${lessonNumber}`)
          router.push({
            url: 'pages/learn/LetterLessonPage',
            params: {
              lessonId: lessonNumber.toString(),
              title: item.title
            }
          })
        } else if (item.key.startsWith('word_')) {
          // 单词课程 - 路由到LetterLessonPage
          const lessonIndex = parseInt(item.key.replace('word_', ''))
          const lessonNumber = 19 + lessonIndex // 单词课程从第19课开始
          console.error(`[LEARN] Navigating to word lesson: ${lessonNumber}`)
          router.push({
            url: 'pages/learn/LetterLessonPage',
            params: {
              lessonId: lessonNumber.toString(),
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
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
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
        .opacity(1.0)
        .enabled(true)  // 所有单元都启用滚动
      }
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .backgroundColor('#1A1A1A')
    .border({ width: 1, color: '#333333' })
    .borderRadius(12)
    .onClick(() => {
      // 所有单元都已解锁，无需特殊处理
      console.info(`单元 ${unitNumber} 已解锁`)
    })
  }

  build() {
    Column() {
      if (this.isInitialized) {
        // Title bar - 引用refreshTrigger使其响应式
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
        .opacity(this.refreshTrigger >= 0 ? 1 : 1) // 引用refreshTrigger

        // Horizontal scroll of unit cards - 让所有课程卡片都引用refreshTrigger
        Scroll(this.scroller) {
          Row() {
            // Intro unit (2 lessons + padding)
            Column() { 
              this.UnitCard('摩斯密码基础', 1, this.vm.introLessons, true) 
            }
            .width(320).height(500).margin({ right: 16 })
            .opacity(this.refreshTrigger >= 0 ? 1 : 1) // 引用refreshTrigger

            // Alphabet unit (9)
            Column() { 
              this.UnitCard('字母', 2, this.vm.alphabetLessons, true) 
            }
            .width(320).height(500).margin({ right: 16 })
            .opacity(this.refreshTrigger >= 0 ? 1 : 1) // 引用refreshTrigger

            // Numbers unit (4)
            Column() { 
              this.UnitCard('数字', 3, this.vm.numberLessons, true) 
            }
            .width(320).height(500).margin({ right: 16 })
            .opacity(this.refreshTrigger >= 0 ? 1 : 1) // 引用refreshTrigger

            // Punctuation unit (3 + pad)
            Column() { 
              this.UnitCard('符号', 4, this.vm.punctuationLessons, true) 
            }
            .width(320).height(500).margin({ right: 16 })
            .opacity(this.refreshTrigger >= 0 ? 1 : 1) // 引用refreshTrigger

            // Words unit (3 + pad)
            Column() { 
              this.UnitCard('单词', 5, this.vm.wordLessons, true) 
            }
            .width(320).height(500)
            .opacity(this.refreshTrigger >= 0 ? 1 : 1) // 引用refreshTrigger
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
