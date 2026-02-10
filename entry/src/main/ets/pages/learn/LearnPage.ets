import { LearnViewModel } from '../../viewmodel/LearnViewModel'
import { LessonConfig } from '../../data/LessonConfig'
import { LessonItem } from '../../types/Types'
import { router } from '@kit.ArkUI'
import { eventHub, Events } from '../../utils/EventHub'
import { progressStore } from '../../store/ProgressStoreSingleton'
import { common, Want } from '@kit.AbilityKit'
import { FunctionComponent } from '@kit.AgentFrameworkKit'
import { BusinessError } from '@kit.BasicServicesKit'

// 小艺智能体：摩斯电码冷知识（HMAF 文档 https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hmaf-function）
const AGENT_MORSE_FUN_FACTS_ID = 'agentbe59df1493d7411e91a8a30bb4dc8c22'
// 浏览器回退 URL（当 HMAF 调起失败时使用）
const AGENT_MORSE_FUN_FACTS_FALLBACK_URL =
  'https://developer.huawei.com/consumer/cn/hag/abilityportal/#/agent/detail?agentId=agentbe59df1493d7411e91a8a30bb4dc8c22&agentUuid=25ace2bca2ad4274a6332f3193f5d5b4'

@Component
export struct LearnPage {
  private scroller: Scroller = new Scroller()
  @State vm: LearnViewModel = new LearnViewModel()
  @State private isInitialized: boolean = false
  @State private isLanguageReady: boolean = false
  @StorageLink('currentLanguage') @Watch('onLanguageChange') currentLanguage: string = ''
  private lessonCompletedCallback: ((data?: Object) => void) | null = null
  @State private agentEntryTitle: string = ''
  @State private agentEntryQueryText: string = ''

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

      // 加载智能体入口文案与指令（供 HMAF Function 组件使用）
      try {
        const ctx = hostContext as common.UIAbilityContext
        this.agentEntryTitle = await ctx.resourceManager.getStringByName('agent_morse_fun_facts')
        this.agentEntryQueryText = await ctx.resourceManager.getStringByName('agent_morse_fun_facts_prompt')
      } catch (e) {
        console.error('[LearnPage] Failed to load agent strings:', e)
      }

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
    if (this.isPlaceholderLesson(this.getLessonTitle(item))) { return }

    if (item.key === 'intro_1') {
      // Navigate to lesson page for the 2nd intro lesson (Chinese)
      // Use hardcoded strings for title
      const currentLanguage = AppStorage.get<string>('currentLanguage') || 'zh-CN'
      let title = '中文摩斯电码'
      let testTitle = '中文摩斯电码测试'

      if (currentLanguage.startsWith('en')) {
        title = 'Chinese Morse Code'
        testTitle = 'Chinese Code Test'
      } else if (currentLanguage === 'zh-HK' || currentLanguage === 'zh-TW') {
        title = '中文摩斯電碼'
        testTitle = '中文摩斯電碼測試'
      }

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
      let title = '摩斯电码基础'
      let testTitle = '基础测试'

      if (currentLanguage.startsWith('en')) {
        title = 'Morse Code Basics'
        testTitle = 'Basics Test'
      } else if (currentLanguage === 'zh-HK' || currentLanguage === 'zh-TW') {
        title = '摩斯電碼基礎'
        testTitle = '基礎測試'
      }

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

  // 检查是否为占位课程（支持简体和繁体）
  private isPlaceholderLesson(title: string): boolean {
    return title === '占位' || title === '佔位'
  }

  // HMAF 调起失败时通过浏览器打开智能体页（带本地化 prompt）
  private async openMorseFunFactsAgentFallback(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const prompt = await context.resourceManager.getStringByName('agent_morse_fun_facts_prompt')
      const uri = `${AGENT_MORSE_FUN_FACTS_FALLBACK_URL}&prompt=${encodeURIComponent(prompt)}`
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: uri
      }
      await context.startAbility(want)
    } catch (error) {
      console.error('[LearnPage] Failed to open Morse fun facts agent fallback:', error)
    }
  }

  private onAgentError(err: BusinessError): void {
    console.error('[LearnPage] HMAF agent error:', err?.code, err?.message)
    this.openMorseFunFactsAgentFallback()
  }

  // 获取本地化标题
  private getLocalizedTitle(titleKey: string): string {
    const currentLanguage = AppStorage.get<string>('currentLanguage') || 'zh-CN'

    // 硬编码本地化字符串
    const localizedStrings: Record<string, Record<string, string>> = {
      'zh-CN': {
        'morse_code_basics': '摩斯电码基础',
        'alphabet_lesson': '字母',
        'number_lesson': '数字',
        'punctuation_lesson': '标点符号',
        'word_lesson': '单词'
      },
      'zh-HK': {
        'morse_code_basics': '摩斯電碼基礎',
        'alphabet_lesson': '字母',
        'number_lesson': '數字',
        'punctuation_lesson': '標點符號',
        'word_lesson': '單詞'
      },
      'zh-TW': {
        'morse_code_basics': '摩斯電碼基礎',
        'alphabet_lesson': '字母',
        'number_lesson': '數字',
        'punctuation_lesson': '標點符號',
        'word_lesson': '單詞'
      },
      'en-US': {
        'morse_code_basics': 'Basics',
        'alphabet_lesson': 'Letters',
        'number_lesson': 'Numbers',
        'punctuation_lesson': 'Punctuation',
        'word_lesson': 'Words'
      }
    }

    // 根据语言选择对应的字符串集
    let langKey = 'zh-CN'
    if (currentLanguage.startsWith('en')) {
      langKey = 'en-US'
    } else if (currentLanguage === 'zh-HK') {
      langKey = 'zh-HK'
    } else if (currentLanguage === 'zh-TW') {
      langKey = 'zh-TW'
    }

    return localizedStrings[langKey]?.[titleKey] || titleKey
  }

  // 获取单元进度文本（格式：completed/total）
  private getUnitProgress(unitKey: string): string {
    const lessons = this.getLessonsForUnit(unitKey)
    // 过滤掉占位课程
    const realLessons = lessons.filter(l => !this.isPlaceholderLesson(this.getLessonTitle(l)))
    const total = realLessons.length
    const completed = realLessons.filter(l => l.completed).length
    return `${completed}/${total}`
  }



  @Builder
  private LessonCard(item: LessonItem, unitLocked: boolean) {
    Stack({ alignContent: Alignment.Center }) {
      // 占位课程不显示任何内容
      if (!this.isPlaceholderLesson(this.getLessonTitle(item))) {
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
      .backgroundColor(this.isPlaceholderLesson(this.getLessonTitle(item)) ? Color.Transparent : '#1A1A1A')
      .border({
        width: this.isPlaceholderLesson(this.getLessonTitle(item)) ? 0 : 1,
        color: this.isPlaceholderLesson(this.getLessonTitle(item)) ? Color.Transparent : '#333333'
      })
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
            .fontColor('#FFD700')
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
              .opacity(this.isPlaceholderLesson(this.getLessonTitle(l)) ? 0.0 : 1.0)
                .onClick(async () => {
                  if (!this.isPlaceholderLesson(this.getLessonTitle(l))) {
                    await this.handleLessonClick(l)
                  }
                })
            }, (l: LessonItem) => `${l.key}-${l.completed ? 'c' : 'n'}-${this.vm.dataVersion}`)
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
          .edgeEffect(EdgeEffect.Spring)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        // 底部：小艺智能体「摩斯电码冷知识」（HMAF Function 组件，见 hmaf-function 文档）
        FunctionComponent({
          agentId: AGENT_MORSE_FUN_FACTS_ID,
          onError: (err: BusinessError) => {
            this.onAgentError(err)
          },
          options: {
            title: this.agentEntryTitle,
            queryText: this.agentEntryQueryText
          }
        })
        .padding({ bottom: 24 })
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
