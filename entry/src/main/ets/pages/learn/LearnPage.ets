import { LearnViewModel } from '../../viewmodel/LearnViewModel'
import { LessonConfig } from '../../data/LessonConfig'
import { LessonItem } from '../../types/Types'
import { router } from '@kit.ArkUI'
import { eventHub, Events } from '../../utils/EventHub'

@Component
export struct LearnPage {
  private scroller: Scroller = new Scroller()
  @State vm: LearnViewModel = new LearnViewModel()
  @State private isInitialized: boolean = false
  @State private isLanguageReady: boolean = false
  @StorageLink('currentLanguage') @Watch('onLanguageChange') currentLanguage: string = ''
  private lessonCompletedCallback: ((data?: Object) => void) | null = null

  onLanguageChange(): void {
    // 调用ViewModel刷新课程数据
    this.vm.refreshLessons()
  }


  async aboutToAppear(): Promise<void> {
    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()
    if (hostContext) {
      // 课程完成监听
      this.lessonCompletedCallback = (data?: Object) => {
        console.log('[LearnPage] Lesson completed event received, refreshing UI')
        this.vm.refreshLessons()
      }
      eventHub.on(Events.LESSON_COMPLETED, this.lessonCompletedCallback)

      // Wait for language to be ready, then load data
      await this.waitForLanguageReady()

      await this.vm.init(hostContext)

      // Add 200ms delay for smooth rendering
      setTimeout(() => {
        this.isInitialized = true
      }, 200)
    }
  }

  // Wait for language to be ready from AppStorage
  private async waitForLanguageReady(): Promise<void> {
    return new Promise((resolve) => {
      // Add 200ms delay to ensure EntryAbility has set the language
      setTimeout(() => {
        const lang = AppStorage.get<string>('currentLanguage')
        console.log(`[LearnPage] Language after 200ms delay: ${lang}`)
        // Update currentLanguage to match AppStorage
        this.currentLanguage = lang || 'zh-CN'
        this.isLanguageReady = true
        resolve()
      }, 200)
    })
  }

  // 根据单元键实时获取课程列表，避免快照导致的过期数据
  private getLessonsForUnit(unitKey: string): LessonItem[] {
    switch (unitKey) {
      case 'intro':
        return this.vm.getIntroLessons()
      case 'alphabet':
        return this.vm.getAlphabetLessons()
      case 'numbers':
        return this.vm.getNumberLessons()
      case 'punctuation':
        return this.vm.getPunctuationLessons()
      case 'words':
        return this.vm.getWordLessons()
      default:
        return []
    }
  }


  // 处理课程点击事件
  private async handleLessonClick(item: LessonItem): Promise<void> {
    // Block navigation for placeholder lessons
    if (item.title === '占位') { return }

    if (item.key === 'intro_1') {
      // Navigate to lesson page for the 2nd intro lesson (Chinese)
      // Use hardcoded strings for title
      const currentLanguage = AppStorage.get<string>('currentLanguage') || 'zh-CN'
      const isChinese = currentLanguage.startsWith('zh')
      const title = isChinese ? '中文摩斯电码' : 'Chinese Morse Code'
      const testTitle = isChinese ? '中文摩斯电码测试' : 'Chinese Code Test'

      router.push({
        url: 'pages/learn/KnowledgeLessonPage',
        params: {
          title: title,
          testTitle: testTitle,
          lessonCompletedKey: 'intro_lesson_1',
          currentLanguage: currentLanguage
        }
      })
    } else if (item.key.startsWith('intro_')) {
      // Navigate to lesson page for the 1st intro lesson (Basics)
      // Use hardcoded strings for title
      const currentLanguage = AppStorage.get<string>('currentLanguage') || 'zh-CN'
      const isChinese = currentLanguage.startsWith('zh')
      const title = isChinese ? '摩斯电码基础' : 'Morse Code Basics'
      const testTitle = isChinese ? '基础测试' : 'Basics Test'

      router.push({
        url: 'pages/learn/KnowledgeLessonPage',
        params: {
          title: title,
          testTitle: testTitle,
          lessonCompletedKey: 'intro_lesson_0',
          currentLanguage: currentLanguage
        }
      })
    } else if (item.key.startsWith('alpha_')) {
      // 字母课程 - 路由到LetterLessonPage
      const lessonIndex = parseInt(item.key.replace('alpha_', ''))
      const lessonNumber = LessonConfig.getLessonNumber(`alphabet_lesson_${lessonIndex}`)
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
      const lessonNumber = LessonConfig.getLessonNumber(`number_lesson_${lessonIndex}`)
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
      const lessonNumber = LessonConfig.getLessonNumber(`punctuation_lesson_${lessonIndex}`)
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
      const lessonNumber = LessonConfig.getLessonNumber(`word_lesson_${lessonIndex}`)
      console.error(`[LEARN] Navigating to word lesson: ${lessonNumber}`)
      router.push({
        url: 'pages/learn/LetterLessonPage',
        params: {
          lessonId: lessonNumber.toString(),
          title: item.title
        }
      })
    } else {
      console.warn(`[LEARN] Unknown lesson type: ${item.key}`)
    }
  }



  aboutToDisappear(): void {
    // 清理事件监听
    if (this.lessonCompletedCallback) {
      eventHub.off(Events.LESSON_COMPLETED, this.lessonCompletedCallback)
      this.lessonCompletedCallback = null
    }
  }



  // 获取课程标题
  private getLessonTitle(item: LessonItem): string {
    return typeof item.title === 'string' ? item.title : ''
  }

  // 获取课程副标题
  private getLessonSubtitle(item: LessonItem): string {
    return (typeof item.subtitle === 'string' ? item.subtitle : '') || ''
  }

  // 获取本地化标题
  private getLocalizedTitle(titleKey: string): string {
    const currentLanguage = AppStorage.get<string>('currentLanguage') || 'zh-CN'
    const isChinese = currentLanguage.startsWith('zh')

    // 硬编码本地化字符串
    const localizedStrings: Record<string, Record<string, string>> = {
      'zh-CN': {
        'morse_code_basics': '摩斯电码基础',
        'alphabet_lesson': '字母',
        'number_lesson': '数字',
        'punctuation_lesson': '标点符号',
        'word_lesson': '单词'
      },
      'en-US': {
        'morse_code_basics': 'Basics',
        'alphabet_lesson': 'Letters',
        'number_lesson': 'Numbers',
        'punctuation_lesson': 'Punctuation',
        'word_lesson': 'Words'
      }
    }

    const langKey = isChinese ? 'zh-CN' : 'en-US'
    return localizedStrings[langKey]?.[titleKey] || titleKey
  }



  @Builder
  private LessonCard(item: LessonItem, unitLocked: boolean) {
    Stack({ alignContent: Alignment.Center }) {
      // 占位课程不显示任何内容
      if (item.title !== '占位') {
        // 中间内容：标题/副标题始终居中
        Column() {
          Text(this.getLessonTitle(item))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .margin({ bottom: this.getLessonSubtitle(item) ? 8 : 0 })

          if (this.getLessonSubtitle(item)) {
            Text(this.getLessonSubtitle(item))
              .fontSize(14)
              .fontColor('#B0B0B0')
              .textAlign(TextAlign.Center)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

        // 右侧悬浮图标：✓ 或 右箭头
        Row() {
          if (item.completed) {
            Text('✓').fontSize(20).fontColor(Color.Green)
          } else {
            Image($rawfile('ic_arrow_right.svg'))
              .width(16)
              .height(16)
              .fillColor(Color.White)
          }
        }
        .width('100%')
          .justifyContent(FlexAlign.End)
          .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
      .padding(16)
      .backgroundColor(item.title === '占位' ? Color.Transparent : '#1A1A1A')
      .border({ width: item.title === '占位' ? 0 : 1, color: item.title === '占位' ? Color.Transparent : '#333333' })
      .borderRadius(12)
  }

  @Builder
  private TitleBar() {
    Row() {

      Text($r('app.string.learn'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
    }
    .height(56)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#000000')
  }

  @Builder
  private UnitCard(titleKey: string, unitNumber: number, unitKey: string) {
    RelativeContainer() {
      // Reference anchor filling the card (use empty Column due to Blank restriction)
      Column() { }
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
          right: { anchor: 'card', align: HorizontalAlign.End }
        })
        .margin({ right: 0, bottom: -10 })  // Negative bottom margin to move it closer
        .zIndex(0)

      Column() {


        Row() {
          Text(this.getLocalizedTitle(titleKey))
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
            ForEach(this.getLessonsForUnit(unitKey), (l: LessonItem, idx: number) => {
              Column() {
                this.LessonCard(l, false) // All lessons are unlocked
                if (idx < this.getLessonsForUnit(unitKey).length - 1) { Blank().height(12) }
              }
              .opacity(l.title === '占位' ? 0.0 : 1.0)
                .onClick(async () => {
                  if (l.title !== '占位') {
                    await this.handleLessonClick(l)
                  }
                })
            }, (l: LessonItem) => `${l.key}-${l.completed ? 'c' : 'n'}-${this.vm.dataVersion}`)
          }
        }
        .layoutWeight(1)
          .scrollBar(BarState.Off)  // 移除滚动条
          .edgeEffect(EdgeEffect.None)  // 移除弹性效果
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
  }

  build() {
    Column() {
      if (this.isInitialized) {
        this.TitleBar()

        // Horizontal scroll of unit cards
        Scroll(this.scroller) {
          Row() {
            // Intro unit (2 lessons + padding) - 直接从ViewModel获取最新数据
            Column() {
              this.UnitCard('morse_code_basics', 1, 'intro')
            }
            .width(320).height(500).margin({ right: 16 })

            // Alphabet unit (9) - 直接从ViewModel获取最新数据
            Column() {
              this.UnitCard('alphabet_lesson', 2, 'alphabet')
            }
            .width(320).height(500).margin({ right: 16 })

            // Numbers unit (4) - 直接从ViewModel获取最新数据
            Column() {
              this.UnitCard('number_lesson', 3, 'numbers')
            }
            .width(320).height(500).margin({ right: 16 })

            // Punctuation unit (3 + pad) - 直接从ViewModel获取最新数据
            Column() {
              this.UnitCard('punctuation_lesson', 4, 'punctuation')
            }
            .width(320).height(500).margin({ right: 16 })

            // Words unit (3 + pad) - 直接从ViewModel获取最新数据
            Column() {
              this.UnitCard('word_lesson', 5, 'words')
            }
            .width(320).height(500)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
          .edgeEffect(EdgeEffect.None)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 16, bottom: 24 })
      } else {
        // Loading state - Pure black screen
        Column() {
        }
        .width('100%')
          .height('100%')
          .backgroundColor(Color.Black)
      }
    }
    .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
