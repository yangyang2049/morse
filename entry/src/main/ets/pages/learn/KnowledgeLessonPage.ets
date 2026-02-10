import { router } from '@kit.ArkUI'
// System bar colors are set globally in EntryAbility
import { KnowledgeLessonViewModel } from '../../viewmodel/KnowledgeLessonViewModel'
import { LessonNavParams } from '../../types/Types'
import { resourceManager, i18n } from '@kit.LocalizationKit'

@Entry
@Component
  struct KnowledgeLessonPage {
  @State viewModel: KnowledgeLessonViewModel = new KnowledgeLessonViewModel()
  @State title: Resource | string = $r('app.string.morse_code_basics')
  @State content: Resource | string = $r('app.string.morse_code_intro')
  @State customSections: string[] = []
  @StorageLink('currentLanguage') currentLanguage: string = 'zh-CN'

  // Quiz card localized strings
  @State testYourMasteryText: string = ''
  @State testContentText: string = ''
  @State trueFalseQuestionsText: string = ''
  @State multipleChoiceQuestionsText: string = ''
  @State need100ToPassText: string = ''
  @State startTestText: string = ''
  // 资源管理器
  private resourceMgr: resourceManager.ResourceManager | null = null

  async aboutToAppear(): Promise<void> {
    // 初始化资源管理器
    try {
      this.resourceMgr = getContext(this).resourceManager
    } catch (error) {
      console.error('[KnowledgeLessonPage] Failed to get resource manager:', error)
    }

    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()

    // Read navigation params and initialize ViewModel
    try {
      const params: LessonNavParams = (router.getParams() as Record<string, Object>) as LessonNavParams ?? {} as LessonNavParams
      console.error(`[KNOWLEDGE_LESSON] aboutToAppear: Raw params=`, JSON.stringify(params))

      // Update language from params if provided
      if (params.currentLanguage) {
        this.currentLanguage = params.currentLanguage as string
        AppStorage.setOrCreate('currentLanguage', this.currentLanguage)
      }

      // Load localized strings after language is set
      this.loadLocalizedStrings()

      this.viewModel.init(params, hostContext)

      // Update local state if params are provided
      if (params.title) {
        this.title = params.title
      }
    } catch (e) {
      console.warn('No params or failed to read params for KnowledgeLessonPage:', e)
    }
  }


  // 加载本地化字符串
  private loadLocalizedStrings(): void {
    const isChinese = this.currentLanguage.startsWith('zh')

    if (isChinese) {
      this.testYourMasteryText = '测试你对本课程的掌握程度'
      this.testContentText = '测试内容'
      this.trueFalseQuestionsText = '• 2道判断题（每题20分）'
      this.multipleChoiceQuestionsText = '• 3道选择题（每题20分）'
      this.need100ToPassText = '• 需要100分才能通过'
      this.startTestText = '开始测试'
    } else {
      this.testYourMasteryText = 'Test your mastery of this lesson'
      this.testContentText = 'Test Content'
      this.trueFalseQuestionsText = '• 2 True/False questions (20 points each)'
      this.multipleChoiceQuestionsText = '• 3 Multiple choice questions (20 points each)'
      this.need100ToPassText = '• Need 100 points to pass'
      this.startTestText = 'Start Test'
    }
  }

  // 获取当前系统语言
  private getCurrentLanguage(): string {
    try {
      const currentLocale = i18n.System.getSystemLocale()
      // 将系统locale转换为我们的语言代码格式
      if (currentLocale.startsWith('zh')) {
        return 'zh-CN'
      } else if (currentLocale.startsWith('en')) {
        return 'en-US'
      }
      return 'zh-CN' // 默认中文
    } catch (error) {
      console.error('[KnowledgeLessonPage] Failed to get current language:', error)
      return 'zh-CN' // 默认中文
    }
  }

  // 获取系统资源字符串
  private async getStringResource(key: string): Promise<string> {
    try {
      if (this.resourceMgr) {
        // 使用资源ID获取字符串
        const resourceId = await this.resourceMgr.getStringByName(key)
        return resourceId
      }
      return key
    } catch (error) {
      console.error(`[KnowledgeLessonPage] Failed to get string resource for key: ${key}`, error)
      return key
    }
  }

  // Removed onPageShow system bar re-application to avoid flicker

  @Builder
  TitleBar() {
    Row() {
      Button() {
        Image($rawfile('ic_back.svg'))
          .width(20)
          .height(20)
          .fillColor(Color.White)
      }
      .width(48)
        .height(48)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back()
        })

      Text(this.viewModel.title || this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Button()
        .width(48)
        .height(48)
        .backgroundColor(Color.Transparent)
        .enabled(false)
    }
    .height(56)
      .padding({ left: 16, right: 16 })
  }

  @Builder
  buildBulletLine(text: string) {
    Row() {
      Text('• ')
        .fontColor('#FFFFFFB3')
      Text(text)
        .layoutWeight(1)
        .fontColor('#FFFFFF')
    }
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  buildSingleLine(text: string) {
    Text(text)
      .fontColor('#FFFFFF')
      .textAlign(TextAlign.Start)
      .width('100%')
  }

  @Builder
  buildDefaultSection(title: string, contents: string[]) {
    Column() {
      ForEach(contents, (content: string, index: number) => {
        Column() {
          this.buildSingleLine(content)
          if (index < contents.length - 1) {
            Blank().height(8)
          }
        }
      })
    }
    .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
      .width('100%')
      .align(Alignment.TopStart)
  }

  @Builder
  buildSectionCard(title: string, contents: string[], index: number) {
    Column() {
      Stack() {
        // Big faded number at bottom right
        Text(`${index + 1}`)
          .fontSize(80)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .opacity(0.25)
          .position({ x: '100%', y: '100%' })
          .translate({ x: '-100%', y: '-100%' })
          .margin({ right: 0, bottom: -10 })

        // Main content
        Column() {
          Text(title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ bottom: 32 })
            .alignSelf(ItemAlign.Start)

          Scroll() {
            this.buildDefaultSection(title, contents)
          }
          .layoutWeight(1)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .align(Alignment.TopStart)
        }
        .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Start)
          .width('100%')
          .height('100%')
          .padding({ top: 0 })
      }
    }
    .width(320)
      .height(480)
      .padding(16)
      .backgroundColor('#1A1A1A')
      .border({ width: 1, color: '#333333' })
      .borderRadius(12)
      .margin({ right: 16 })
  }

  @Builder
  buildTestCard() {
    Column() {
      Stack() {
        // Main content
        Column() {
          Row() {
            Image($rawfile('ic_records.svg')).width(20).height(20).fillColor('#FF8C00').margin({ right: 8 })

            Text(this.viewModel.testTitle)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF8C00')
              .alignSelf(ItemAlign.Center)
          }
          .margin({ bottom: 32 })

          Text(this.testYourMasteryText)
            .fontSize(16)
            .fontColor('#FF8C00')
            .margin({ bottom: 16 })

          Text(this.testContentText)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF8C00')
            .margin({ bottom: 8 })
            .alignSelf(ItemAlign.Start)

          Column() {
            Text(this.trueFalseQuestionsText).fontSize(14).fontColor(Color.Black).margin({ bottom: 4 })
            Text(this.multipleChoiceQuestionsText).fontSize(14).fontColor(Color.Black).margin({ bottom: 4 })
            Text(this.need100ToPassText).fontSize(14).fontColor(Color.Black)
          }
          .margin({ bottom: 16 })
            .alignItems(HorizontalAlign.Start)

          Blank().layoutWeight(1)

          Button() {
            Text(this.startTestText)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .width('100%')
            .height(48)
            .backgroundColor('#FF8C00')
            .borderRadius(8)
            .onClick(() => {
              // Navigate to quiz page
              console.error(`[KNOWLEDGE_LESSON] Start quiz: pageTitle=${this.viewModel.testTitle}`)
              router.push({
                url: 'pages/learn/LessonQuizPage',
                params: {
                  pageTitle: this.viewModel.testTitle,
                  lessonCompletedKey: this.viewModel.lessonCompletedKey,
                  currentLanguage: this.currentLanguage
                }
              })
            })

          Blank().height(16)
        }
        .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Start)
          .width('100%')
          .height('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
      .width(320)
      .height(480)
      .padding(16)
      .backgroundColor('#FFF8DC')
      .border({ width: 1, color: '#FF8C00' })
      .borderRadius(12)
  }

  @Builder
  ContentCard() {
    Column() {
      Text(this.content)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .lineHeight(24)
        .textAlign(TextAlign.Start)
        .width('100%')
    }
    .width('100%')
      .padding(20)
      .backgroundColor('#2A2A2A')
      .border({ width: 1, color: '#333333' })
      .borderRadius(12)
  }

  @Builder
  CustomSections() {
    if (this.customSections.length > 0) {
      Column() {
        ForEach(this.customSections, (section: string, index: number) => {
          Column() {
            Text(section)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .lineHeight(24)
              .textAlign(TextAlign.Start)
              .width('100%')
          }
          .width('100%')
            .padding(20)
            .backgroundColor('#2A2A2A')
            .border({ width: 1, color: '#333333' })
            .borderRadius(12)
            .margin({ top: index > 0 ? 20 : 0 })
        })
      }
    }
  }

  @Builder
  CompleteButton() {
    Button() {
      Text($r('app.string.learning_completed'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
    }
    .width('100%')
      .height(48)
      .backgroundColor('#FFD700')
      .borderRadius(12)
      .onClick(async () => {
        console.error(`[KNOWLEDGE_LESSON] CompleteButton: User completed learning, marking lesson as completed`)
        // 立即标记课程完成
        await this.viewModel.markLessonCompletedImmediately()
        router.back()
      })
  }

  // 检查是否使用分章节模式
  private isSectionMode(): boolean {
    return this.viewModel.getSectionTitles().length > 0
  }

  @Builder
  buildSimpleContent() {
    Scroll() {
      Column() {
        // Main content
        this.ContentCard()

        // Custom sections
        this.CustomSections()

        Blank().height(40)

        // Complete button
        this.CompleteButton()
      }
      .padding(16)
        .alignItems(HorizontalAlign.Start)
    }
    .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  buildSectionContent() {
    // PageView style with horizontal scrolling cards
    Scroll() {
      Row() {
        // Section cards
        ForEach(this.viewModel.getSectionTitles(), (title: string, index: number) => {
          this.buildSectionCard(title, this.viewModel.getSectionContent(title), index)
        })

        // Test card
        this.buildTestCard()
      }
      .alignItems(VerticalAlign.Top)
    }
    .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 16, bottom: 24 })
  }

  build() {
    Column() {
      this.TitleBar()

      // 内容区域
      Column() {
        if (this.isSectionMode()) {
          // 使用分章节模式（原LessonPage的功能）
          this.buildSectionContent()
        } else {
          // 使用简单内容模式（原KnowledgeLessonPage的功能）
          this.buildSimpleContent()
        }
      }
      .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
