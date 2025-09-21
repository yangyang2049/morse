import { LearnViewModel } from '../../viewmodel/LearnViewModel'
import { LessonConfig } from '../../data/LessonConfig'
import { LessonItem, LearnPageStrings } from '../../types/LessonTypes'
import { router } from '@kit.ArkUI'
import { eventHub, Events } from '../../utils/EventHub'
import { i18nService } from '../../services/I18nService'

@Component
export struct LearnPage {
  private scroller: Scroller = new Scroller()
  @State vm: LearnViewModel = new LearnViewModel()
  @State private isInitialized: boolean = false
  private languageChangeListener: ((lang: string) => void) | null = null
  @StorageLink('currentLanguage') @Watch('onLanguageChange') currentLanguage: string = 'zh-CN'
  // 语言强制刷新触发器（由 i18nService 维护）
  @StorageLink('languageRefreshTrigger') @Watch('onLanguageRefreshTrigger') languageRefreshTrigger: number = 0
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

  aboutToAppear(): void {
    // 添加语言变化监听器
    this.languageChangeListener = (lang: string) => {
      console.log(`[LearnPage] Language changed to: ${lang}`)
      
      // 延迟500ms刷新，确保语言切换完成
      setTimeout(() => {
        // 强制同步语言到 i18nService
        i18nService.setLanguage(lang).then(() => {
          console.log(`[LearnPage] i18nService language updated to: ${lang}`)
          // 更新缓存的本地化字符串
          this.strings = this.computeStrings()
          // 刷新课程数据
          this.vm.refreshLessons()
          this.updateLessonData()
          
          // 额外的调试信息
          console.log(`[LearnPage] After refresh - isChinese: ${i18nService.isChinese()}, intro count: ${this.vm.getIntroLessons().length}`)
        }).catch((error: Error) => {
          console.warn(`[LearnPage] Failed to set language: ${error.message}`)
          // 即使失败也尝试刷新
          this.strings = this.computeStrings()
          this.vm.refreshLessons()
          this.updateLessonData()
        })
      }, 500)
    }
    
    // 由 StorageLink + @Watch 实时监听语言变化，无需轮询
    
    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()
    if (hostContext) {
      // 课程完成监听
      this.lessonCompletedCallback = (data?: Object) => {
        console.log('[LearnPage] Lesson completed event received, refreshing UI')
        this.vm.refreshLessons()
        this.updateLessonData()
      }
      eventHub.on(Events.LESSON_COMPLETED, this.lessonCompletedCallback)
      
      this.vm.init(hostContext).then(() => {
        this.strings = this.computeStrings()
        this.updateLessonData()
        this.isInitialized = true
      })
    }
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

  // 语言变化时的处理方法（由 @Watch 触发）
  onLanguageChange(): void {
    const lang = this.currentLanguage
    console.log(`[LearnPage] onLanguageChange -> ${lang}`)
    if (this.languageChangeListener) {
      this.languageChangeListener(lang)
    } else {
      // 兜底：延迟500ms刷新，确保语言切换完成
      setTimeout(() => {
        i18nService.setLanguage(lang).then(() => {
          this.strings = this.computeStrings()
          this.vm.refreshLessons()
          this.updateLessonData()
        }).catch(() => {
          this.strings = this.computeStrings()
          this.vm.refreshLessons()
          this.updateLessonData()
        })
      }, 500)
    }
  }

  // 当全局语言刷新触发器变化时，强制刷新内容
  onLanguageRefreshTrigger(): void {
    console.log('[LearnPage] onLanguageRefreshTrigger -> force refresh')
    // 延迟500ms刷新，确保语言切换完成
    setTimeout(() => {
      this.strings = this.computeStrings()
      this.vm.refreshLessons()
      this.updateLessonData()
    }, 500)
  }

  // ViewModel变化时的处理方法
  onViewModelChange(): void {
    console.log('[LearnPage] ViewModel changed, triggering UI refresh')
    this.langTick++
  }

  // 更新课程数据 - 现在只需要触发UI刷新
  private updateLessonData(): void {
    // 触发UI刷新，确保标题和副标题重新计算
    this.langTick++
    console.log('[LearnPage] Triggering UI refresh, langTick:', this.langTick)
    console.log('[LearnPage] Current language:', i18nService.getCurrentLanguage(), 'isChinese:', i18nService.isChinese())
    
    // 直接从ViewModel获取最新数据进行调试
    const introLessons = this.vm.getIntroLessons()
    console.log('[LearnPage] Fresh intro lessons from VM:', introLessons.map(l => `${l.key}:${l.title}`).join(', '))
  }

  // 处理课程点击事件
  private handleLessonClick(item: LessonItem): void {
    // Block navigation for placeholder lessons
    if (item.title === '占位') { return }
    
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
      console.warn(`[LEARN] Unknown lesson type: ${item.key}`)
    }
  }



  aboutToDisappear(): void {
    // 清理语言变化监听器
    if (this.languageChangeListener) {
      this.languageChangeListener = null
    }
    // 清理事件监听
    if (this.lessonCompletedCallback) {
      eventHub.off(Events.LESSON_COMPLETED, this.lessonCompletedCallback)
      this.lessonCompletedCallback = null
    }
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

  // 动态获取课程标题 - 强制重新获取最新翻译
  private getDynamicLessonTitle(item: LessonItem): string {
    // 根据课程key动态获取标题，每次都重新调用i18nService
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

  // 动态获取课程副标题 - 强制重新获取最新翻译
  private getDynamicLessonSubtitle(item: LessonItem): string {
    // 根据课程key动态获取副标题，每次都重新调用i18nService
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



  @Builder
  private LessonCard(item: LessonItem, unitLocked: boolean) {
    Stack({ alignContent: Alignment.Center }) {
      // 占位课程不显示任何内容
      if (item.title !== '占位') {
        // 中间内容：标题/副标题始终居中
        Column() {
          // 隐藏的langTick触发器引用
          Text(this.langTick.toString()).opacity(0).width(0).height(0)
          
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
      // 隐藏的langTick触发器
      Text(this.langTick.toString())
        .opacity(0)
        .width(0)
        .height(0)
      
      Text(this.strings.learn || i18nService.t('learn'))
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

      {
        Row() {
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
            // 引用ViewModel的dataVersion和语言变化来确保响应式更新
            Text(this.vm.dataVersion.toString()).opacity(0).width(0).height(0)
            Text(this.currentLanguage).opacity(0).width(0).height(0)
            Text(this.langTick.toString()).opacity(0).width(0).height(0)
            
            ForEach(this.getLessonsForUnit(unitKey), (l: LessonItem, idx: number) => {
              Column() {
                this.LessonCard(l, false) // All lessons are unlocked
                if (idx < this.getLessonsForUnit(unitKey).length - 1) { Blank().height(12) }
              }
              .opacity(l.title === '占位' ? 0.0 : 1.0)
              .onClick(() => {
                if (l.title !== '占位') {
                  this.handleLessonClick(l)
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
