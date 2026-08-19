import { LearnViewModel } from '../../viewmodel/LearnViewModel'
import { CourseCatalogV2 } from '../../data/CourseCatalogV2'
import { LessonItem } from '../../types/Types'
import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { eventHub, Events } from '../../utils/EventHub'
import { LocalizationHelper } from '../../utils/LocalizationHelper'
import { SystemBarHelper } from '../../utils/SystemBarHelper'
import { DistributedSyncPermissionHelper } from '../../utils/DistributedSyncPermissionHelper'
import { RecommendAppsDismissHelper } from '../../helpers/recommendAppsDismissHelper'

@Component
export struct LearnPage {
  private scroller: Scroller = new Scroller()
  @State vm: LearnViewModel = new LearnViewModel()
  @State private isInitialized: boolean = false
  @State private isLanguageReady: boolean = false
  @State private recommendAppsDismissed: boolean = false
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

      const abilityContext = hostContext as common.UIAbilityContext
      const syncGranted = await DistributedSyncPermissionHelper.requestOnLearnEntry(abilityContext)
      await this.vm.init(abilityContext, syncGranted)

      // 加载推荐应用入口隐藏状态
      try {
        this.recommendAppsDismissed = await RecommendAppsDismissHelper.isDismissed(abilityContext)
      } catch (err) {
        console.warn('[LearnPage] Failed to load recommend apps dismissed flag:', JSON.stringify(err))
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
        this.currentLanguage = lang || LocalizationHelper.DEFAULT_LANGUAGE
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
    const course = CourseCatalogV2.get(item.key)
    if (!course) { return }

    // 跳转前先刷深色系统栏，减轻二级页过渡时底部闪白
    SystemBarHelper.applyDarkFromUIContext(this.getUIContext())

    const title = await this.resolveString(course.titleKey)
    if (course.kind === 'knowledge') {
      router.push({
        url: 'pages/learn/KnowledgeLessonPage',
        params: {
          title: title,
          testTitle: title,
          lessonCompletedKey: course.id,
          currentLanguage: LocalizationHelper.getCurrentLanguage()
        }
      })
    } else {
      router.push({
        url: 'pages/learn/LetterLessonPage',
        params: {
          lessonId: course.id,
          title: title
        }
      })
    }
  }

  private async resolveString(key: string): Promise<string> {
    try {
      const context = this.getUIContext().getHostContext()
      if (context) {
        return await context.resourceManager.getStringByName(key)
      }
    } catch (error) {
      console.warn(`[LearnPage] Failed to resolve ${key}:`, error)
    }
    return key
  }



  aboutToDisappear(): void {
    // 清理事件监听
    if (this.lessonCompletedCallback) {
      eventHub.off(Events.LESSON_COMPLETED, this.lessonCompletedCallback)
      this.lessonCompletedCallback = null
    }
    this.vm.destroy()
  }



  // 获取课程标题
  private getLessonTitle(item: LessonItem): Resource | string {
    return item.title
  }

  // 获取课程副标题
  private getLessonSubtitle(item: LessonItem): Resource | string {
    return item.subtitle || ''
  }

  // 检查是否为占位课程（支持简体和繁体）
  private isPlaceholderLesson(_title: Resource | string): boolean {
    return false
  }

  // 获取本地化标题
  private getLocalizedTitle(titleKey: string): string {
    const currentLanguage = AppStorage.get<string>('currentLanguage') || LocalizationHelper.DEFAULT_LANGUAGE

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
    let langKey = 'en-US'
    if (currentLanguage.startsWith('en')) {
      langKey = 'en-US'
    } else if (currentLanguage === 'zh-HK' || currentLanguage === 'zh-TW') {
      langKey = 'zh-HK'
    } else if (currentLanguage.startsWith('zh')) {
      langKey = 'zh-CN'
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
    Stack({ alignContent: Alignment.Center }) {
      Text($r('app.string.learn'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')

      Row() {
        Blank()

        // 推荐应用入口：点过一次后永久隐藏（跨版本、跨重启持久化）
        if (!this.recommendAppsDismissed) {
          Row({ space: 6 }) {
            Image($rawfile('ic_recommend_apps.svg'))
              .width(16)
              .height(16)
            Text('推荐应用')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.Black)
          }
          .height(30)
          .padding({ left: 12, right: 12 })
          .backgroundColor('#FFD700')
          .borderRadius(15)
          .shadow({ radius: 8, color: 'rgba(255, 215, 0, 0.25)', offsetX: 0, offsetY: 2 })
          .onClick(() => {
            this.recommendAppsDismissed = true
            const context = this.getUIContext().getHostContext() as common.UIAbilityContext
            if (context) {
              void RecommendAppsDismissHelper.markDismissed(context)
            }
            router.push({ url: 'pages/me/AppFamilyPage' })
          })
          .hoverEffect(HoverEffect.Scale)
          .focusable(true)
        }
      }
      .width('100%')
        .height('100%')
        .padding({ left: 16, right: 16 })
    }
    .height(56)
      .width('100%')
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
