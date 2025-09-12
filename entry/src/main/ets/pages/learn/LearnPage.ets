import { LearnViewModel } from '../../viewmodel/LearnViewModel'
import { LessonConfig } from '../../data/LessonConfig'
import { LessonItem, LearnPageStrings } from '../../types/LessonTypes'
import { router } from '@kit.ArkUI'
import { eventHub, Events } from '../../utils/EventHub'
import { promptAction } from '@kit.ArkUI'
import { i18nService } from '../../services/I18nService'
// 使用$r()函数替代I18n
// System bar colors are set globally in EntryAbility

// 本地化字符串接口
interface LocalizedStrings {
  learn: string
  loading: string
  morse_code_basics: string
  alphabet_lesson: string
  number_lesson: string
  punctuation_lesson: string
  word_lesson: string
  please_complete_previous_lessons: string
  chinese_morse_code: string
  chinese_code_test: string
  basics_test: string
}

@Component
export struct LearnPage {
  private scroller: Scroller = new Scroller()
  @State @Watch('onViewModelChanged') vm: LearnViewModel = new LearnViewModel()
  @State private isInitialized: boolean = false
  @State private refreshTrigger: number = 0
  @State private forceRefresh: number = 0
  // 使用 StorageLink 监听语言变化
  @StorageLink('currentLanguage') currentLanguage: string = 'zh-CN'
  // 语言变化计数器，用于强制UI刷新
  @State langTick: number = 0
  // 缓存本地化字符串
  @State strings: LearnPageStrings = {
    learn: '',
    loading: '',
    morse_code_basics: '',
    alphabet_lesson: '',
    number_lesson: '',
    punctuation_lesson: '',
    word_lesson: '',
    please_complete_previous_lessons: '',
    chinese_morse_code: '',
    chinese_code_test: '',
    basics_test: ''
  }
  private lessonCompletedCallback: ((data?: Object) => void) | null = null
  private languageChangeListener: ((lang: string) => void) | null = null

  aboutToAppear(): void {
    // System bar colors are set globally in EntryAbility
    const uiContext2 = this.getUIContext()
    const hostContext2 = uiContext2.getHostContext()
    if (hostContext2) {
      // 简化的课程完成监听
      this.lessonCompletedCallback = (data?: Object) => {
        console.log('[LearnPage] Lesson completed event received, refreshing UI')
        this.forceRefreshUI()
      }
      eventHub.on(Events.LESSON_COMPLETED, this.lessonCompletedCallback)
      
      // 启动定时刷新机制 - 确保UI始终是最新的
      this.startPeriodicRefresh()
      
      // 添加语言变化监听器 - 使用定时器检查语言变化
      this.languageChangeListener = (lang: string) => {
        console.log(`[LearnPage] Language changed to: ${lang}`)
        // 同时刷新ViewModel中的课程数据
        this.vm.refreshLessons()
      }
      
      // 启动语言变化监听
      this.startLanguageWatcher()
      
      this.vm.init(hostContext2).then(() => {
        // 初始化本地化字符串
        this.strings = this.computeStrings()
        this.isInitialized = true
      })

    }
  }

  onPageShow(): void {
    // 简化：只在页面显示时刷新状态
    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()
    if (hostContext) {
      this.vm.loadUnlockState(hostContext).then(() => {
        this.refreshTrigger++
      }).catch((error: Error) => {
        // 静默处理错误
      })
    }
  }

  aboutToDisappear(): void {
    // 清理事件监听
    if (this.lessonCompletedCallback) {
      eventHub.off(Events.LESSON_COMPLETED, this.lessonCompletedCallback)
      this.lessonCompletedCallback = null
    }
    // 清理语言变化监听器
    if (this.languageChangeListener) {
      this.languageChangeListener = null
    }
  }

  // 启动语言变化监听器
  private startLanguageWatcher(): void {
    let lastLanguage = this.currentLanguage
    const checkLanguageChange = () => {
      if (this.currentLanguage !== lastLanguage) {
        console.log(`[LearnPage] Language changed from ${lastLanguage} to ${this.currentLanguage}`)
        lastLanguage = this.currentLanguage
        // 立即更新缓存的本地化字符串
        this.strings = this.computeStrings()
        // 触发UI强制刷新
        this.langTick++
        this.refreshTrigger++
        if (this.languageChangeListener) {
          this.languageChangeListener(this.currentLanguage)
        }
      }
      // 继续监听
      setTimeout(checkLanguageChange, 100)
    }
    checkLanguageChange()
  }

  // 计算本地化字符串
  private computeStrings(): LearnPageStrings {
    return {
      learn: i18nService.t('learn'),
      loading: i18nService.t('loading'),
      morse_code_basics: i18nService.t('morse_code_basics'),
      alphabet_lesson: i18nService.t('alphabet_lesson'),
      number_lesson: i18nService.t('number_lesson'),
      punctuation_lesson: i18nService.t('punctuation_lesson'),
      word_lesson: i18nService.t('word_lesson'),
      please_complete_previous_lessons: i18nService.t('please_complete_previous_lessons'),
      chinese_morse_code: i18nService.t('chinese_morse_code'),
      chinese_code_test: i18nService.t('chinese_code_test'),
      basics_test: i18nService.t('basics_test')
    }
  }

  // 获取本地化字符串的辅助方法
  private getLocalizedString(key: string): string {
    switch (key) {
      case 'learn': return this.strings.learn || i18nService.t('learn')
      case 'loading': return this.strings.loading || i18nService.t('loading')
      case 'morse_code_basics': return this.strings.morse_code_basics || i18nService.t('morse_code_basics')
      case 'alphabet_lesson': return this.strings.alphabet_lesson || i18nService.t('alphabet_lesson')
      case 'number_lesson': return this.strings.number_lesson || i18nService.t('number_lesson')
      case 'punctuation_lesson': return this.strings.punctuation_lesson || i18nService.t('punctuation_lesson')
      case 'word_lesson': return this.strings.word_lesson || i18nService.t('word_lesson')
      case 'please_complete_previous_lessons': return this.strings.please_complete_previous_lessons || i18nService.t('please_complete_previous_lessons')
      case 'chinese_morse_code': return this.strings.chinese_morse_code || i18nService.t('chinese_morse_code')
      case 'chinese_code_test': return this.strings.chinese_code_test || i18nService.t('chinese_code_test')
      case 'basics_test': return this.strings.basics_test || i18nService.t('basics_test')
      default: return i18nService.t(key)
    }
  }

  // 动态获取课程标题
  private getDynamicLessonTitle(item: LessonItem): string {
    // 引用langTick确保响应语言变化
    const _ = this.langTick
    
    // 根据课程key动态获取标题
    if (item.key.startsWith('intro_')) {
      const lessonNumber = parseInt(item.key.replace('intro_', '')) + 1
      return i18nService.t(`lesson_${lessonNumber}`)
    } else if (item.key.startsWith('alpha_')) {
      const lessonNumber = parseInt(item.key.replace('alpha_', '')) + 1
      return i18nService.t(`lesson_${lessonNumber}`)
    } else if (item.key.startsWith('number_')) {
      const lessonNumber = parseInt(item.key.replace('number_', '')) + 1
      return i18nService.t(`lesson_${lessonNumber}`)
    } else if (item.key.startsWith('punctuation_')) {
      const lessonNumber = parseInt(item.key.replace('punctuation_', '')) + 1
      return i18nService.t(`lesson_${lessonNumber}`)
    } else if (item.key.startsWith('word_')) {
      const lessonNumber = parseInt(item.key.replace('word_', '')) + 1
      return i18nService.t(`lesson_${lessonNumber}`)
    }
    
    // 占位课程或其他情况，返回原标题
    return typeof item.title === 'string' ? item.title : ''
  }

  // 动态获取课程副标题
  private getDynamicLessonSubtitle(item: LessonItem): string {
    // 引用langTick确保响应语言变化
    const _ = this.langTick
    
    // 根据课程key动态获取副标题
    if (item.key === 'intro_0') {
      return i18nService.t('morse_code_basics')
    } else if (item.key === 'intro_1') {
      return i18nService.t('chinese_morse_code')
    } else if (item.key === 'alpha_0') {
      return i18nService.t('alphabet_abc')
    } else if (item.key === 'alpha_1') {
      return i18nService.t('alphabet_def')
    } else if (item.key === 'alpha_2') {
      return i18nService.t('alphabet_ghij')
    } else if (item.key === 'alpha_3') {
      return i18nService.t('alphabet_review_aj')
    } else if (item.key === 'alpha_4') {
      return i18nService.t('alphabet_klmn')
    } else if (item.key === 'alpha_5') {
      return i18nService.t('alphabet_opqr')
    } else if (item.key === 'alpha_6') {
      return i18nService.t('alphabet_stuv')
    } else if (item.key === 'alpha_7') {
      return i18nService.t('alphabet_wxyz')
    } else if (item.key === 'alpha_8') {
      return i18nService.t('alphabet_review_kz')
    } else if (item.key === 'number_0') {
      return i18nService.t('numbers_123')
    } else if (item.key === 'number_1') {
      return i18nService.t('numbers_456')
    } else if (item.key === 'number_2') {
      return i18nService.t('numbers_7890')
    } else if (item.key === 'number_3') {
      return i18nService.t('numbers_review')
    } else if (item.key === 'punctuation_0') {
      return i18nService.t('punctuation_basic')
    } else if (item.key === 'punctuation_1') {
      return i18nService.t('punctuation_advanced')
    } else if (item.key === 'punctuation_2') {
      return i18nService.t('punctuation_review')
    } else if (item.key === 'word_0') {
      return i18nService.t('words_3letter')
    } else if (item.key === 'word_1') {
      return i18nService.t('words_4letter')
    } else if (item.key === 'word_2') {
      return i18nService.t('words_5letter')
    }
    
    // 占位课程或其他情况，返回原副标题
    return (typeof item.subtitle === 'string' ? item.subtitle : '') || ''
  }

  // ViewModel变化监听器
  onViewModelChanged(): void {
    console.log('[LearnPage] ViewModel changed, triggering UI refresh')
    this.refreshTrigger++
  }

  // 强制刷新UI
  private forceRefreshUI(): void {
    console.log('[LearnPage] Force refreshing UI')
    // 刷新ViewModel数据
    this.vm.refreshLessons()
    // 触发UI更新
    this.refreshTrigger++
    this.forceRefresh++
  }

  // 启动定时刷新机制
  private startPeriodicRefresh(): void {
    const refreshInterval = () => {
      // 每2秒检查一次是否需要刷新
      this.forceRefreshUI()
      setTimeout(refreshInterval, 2000)
    }
    // 延迟1秒后开始定时刷新
    setTimeout(refreshInterval, 1000)
  }


  @Builder
  private LessonCard(item: LessonItem, unitLocked: boolean) {
    Stack({ alignContent: Alignment.Center }) {
      // 占位课程不显示任何内容
      if (item.title !== '占位') {
        // 中间内容：标题/副标题始终居中
        Column() {
          // 隐藏的langTick触发器确保课程标题响应语言变化
          Text(this.langTick.toString())
            .opacity(0)
            .width(0)
            .height(0)
          
          Text(this.getDynamicLessonTitle(item))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .margin({ bottom: this.getDynamicLessonSubtitle(item) ? 8 : 0 })

          if (this.getDynamicLessonSubtitle(item)) {
            Text(this.getDynamicLessonSubtitle(item))
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

        // 右侧悬浮图标：✓ 或 右箭头 - 引用refreshTrigger确保响应式更新
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
        .opacity(this.refreshTrigger >= 0 ? 1 : 1) // 引用refreshTrigger确保响应式更新
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(item.title === '占位' ? Color.Transparent : '#1A1A1A')
    .border({ width: item.title === '占位' ? 0 : 1, color: item.title === '占位' ? Color.Transparent : '#333333' })
    .borderRadius(12)
    .opacity(this.refreshTrigger >= 0 ? 1 : 1) // 引用refreshTrigger确保响应式更新
    .onClick(() => {
      // Block navigation for placeholder lessons
      if (item.title === '占位') { return }
      if (item.title !== '占位') {
        if (item.key === 'intro_1') {
          // Navigate to lesson page for the 2nd intro lesson (Chinese)
          router.push({
            url: 'pages/learn/KnowledgeLessonPage',
            params: {
              title: this.strings.chinese_morse_code || i18nService.t('chinese_morse_code'),
              testTitle: this.strings.chinese_code_test || i18nService.t('chinese_code_test'),
              // Use lesson ID for correct mapping
              lessonCompletedKey: 'intro_lesson_1'
            }
          })
        } else if (item.key.startsWith('intro_')) {
          // Navigate to lesson page for the 1st intro lesson (Basics)
          router.push({
            url: 'pages/learn/KnowledgeLessonPage',
            params: {
              title: this.strings.morse_code_basics || i18nService.t('morse_code_basics'),
              testTitle: this.strings.basics_test || i18nService.t('basics_test'),
              lessonCompletedKey: 'intro_lesson_0'
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
          // For other lessons, show a placeholder message
          console.error(`[LEARN] Navigating to other lesson: ${item.key}`)
        }
      }
    })
  }

  @Builder
  private UnitCard(titleKey: string, unitNumber: number, lessons: LessonItem[], isUnlocked: boolean) {
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
          // 隐藏的langTick触发器确保标题响应语言变化
          Text(this.langTick.toString())
            .opacity(0)
            .width(0)
            .height(0)
          
          Text(this.getLocalizedString(titleKey))
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
              .opacity(l.title === '占位' ? 0.0 : 1.0) // 占位课程不可见但占据空间
              .opacity(this.refreshTrigger >= 0 ? 1 : 1) // 引用refreshTrigger确保响应式更新
            }, (l: LessonItem) => `${l.key}-${l.unlocked ? 'u' : 'l'}-${l.completed ? 'c' : 'n'}-${this.refreshTrigger}-${this.forceRefresh}`) // 在key中包含刷新触发器
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
    .onClick(() => {
      // 所有单元都已解锁，无需特殊处理
      console.info(`单元 ${unitNumber} 已解锁`)
    })
  }

  build() {
    Column() {
      if (this.isInitialized) {
        // Title bar - 引用langTick和refreshTrigger使其响应式
        Row() {
          // 隐藏的langTick触发器
          Text(this.langTick.toString())
            .opacity(0)
            .width(0)
            .height(0)
          
          Text(this.strings.learn || i18nService.t('learn'))
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

        // Horizontal scroll of unit cards - 让所有课程卡片都引用refreshTrigger和langTick
        Scroll(this.scroller) {
          Row() {
            // Intro unit (2 lessons + padding)
            Column() { 
              this.UnitCard('morse_code_basics', 1, this.vm.introLessons, true) 
            }
            .width(320).height(500).margin({ right: 16 })
            .opacity(this.refreshTrigger >= 0 ? 1 : 1) // 引用refreshTrigger

            // Alphabet unit (9)
            Column() { 
              this.UnitCard('alphabet_lesson', 2, this.vm.alphabetLessons, true) 
            }
            .width(320).height(500).margin({ right: 16 })
            .opacity(this.refreshTrigger >= 0 ? 1 : 1) // 引用refreshTrigger

            // Numbers unit (4)
            Column() { 
              this.UnitCard('number_lesson', 3, this.vm.numberLessons, true) 
            }
            .width(320).height(500).margin({ right: 16 })
            .opacity(this.refreshTrigger >= 0 ? 1 : 1) // 引用refreshTrigger

            // Punctuation unit (3 + pad)
            Column() { 
              this.UnitCard('punctuation_lesson', 4, this.vm.punctuationLessons, true) 
            }
            .width(320).height(500).margin({ right: 16 })
            .opacity(this.refreshTrigger >= 0 ? 1 : 1) // 引用refreshTrigger

            // Words unit (3 + pad)
            Column() { 
              this.UnitCard('word_lesson', 5, this.vm.wordLessons, true) 
            }
            .width(320).height(500)
            .opacity(this.refreshTrigger >= 0 ? 1 : 1) // 引用refreshTrigger
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .edgeEffect(EdgeEffect.None)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 16, bottom: 24 })
      } else {
        // Loading state
        Column() {
          Text(this.strings.loading || i18nService.t('loading'))
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
