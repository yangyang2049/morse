import { router } from '@kit.ArkUI'
// System bar colors are set globally in EntryAbility
import { KnowledgeLessonViewModel } from '../../viewmodel/KnowledgeLessonViewModel'
import { LessonNavParams } from '../../types/LessonTypes'
import { i18nService } from '../../services/I18nService'

@Entry
@Component
struct KnowledgeLessonPage {
  @State viewModel: KnowledgeLessonViewModel = new KnowledgeLessonViewModel()
  @State title: string = i18nService.t('morse_code_basics')
  @State content: string = i18nService.t('morse_code_intro')
  @State customSections: string[] = []
  
  // 监听语言变化
  @StorageLink('currentLanguage') @Watch('onLanguageChange') currentLanguage: string = 'zh-CN'
  @StorageLink('languageRefreshTrigger') @Watch('onLanguageRefreshTrigger') languageRefreshTrigger: number = 0

  aboutToAppear() {
    const uiContext = this.getUIContext()
    const hostContext = uiContext.getHostContext()
    
    // Read navigation params and initialize ViewModel
    try {
      const params: LessonNavParams = (router.getParams() as Record<string, Object>) as LessonNavParams ?? {} as LessonNavParams
      console.error(`[KNOWLEDGE_LESSON] aboutToAppear: Raw params=`, JSON.stringify(params))
      this.viewModel.init(params, hostContext)
      
      // Update local state if params are provided
      if (params.title) {
        this.title = params.title
      }
    } catch (e) {
      console.warn('No params or failed to read params for KnowledgeLessonPage:', e)
    }
  }

  // 语言变化时的处理方法
  onLanguageChange(): void {
    // 同步到 i18nService 的当前语言
    i18nService.setLanguage(this.currentLanguage)
      .then(() => {
        this.refreshContent()
      })
      .catch(() => {
        // 即便失败也尝试更新，以防止 UI 不刷新
        this.refreshContent()
      })
  }

  // 当全局语言刷新触发器变化时，强制刷新内容
  onLanguageRefreshTrigger(): void {
    this.refreshContent()
  }

  // 刷新页面内容
  private refreshContent(): void {
    // 重新获取标题和内容
    this.title = i18nService.t('morse_code_basics')
    this.content = i18nService.t('morse_code_intro')
    
    // 刷新ViewModel的内容
    this.viewModel.refreshContent()
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
    .height(52)
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

          Text(i18nService.t('test_your_mastery'))
            .fontSize(16)
            .fontColor('#FF8C00')
            .margin({ bottom: 16 })

          Text(i18nService.t('test_content'))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF8C00')
            .margin({ bottom: 8 })
            .alignSelf(ItemAlign.Start)

          Column() {
            Text(i18nService.t('test_format_1')).fontSize(14).fontColor(Color.Black).margin({ bottom: 4 })
            Text(i18nService.t('test_format_2')).fontSize(14).fontColor(Color.Black).margin({ bottom: 4 })
            Text(i18nService.t('need_100_to_pass')).fontSize(14).fontColor(Color.Black)
          }
          .margin({ bottom: 16 })
          .alignItems(HorizontalAlign.Start)

          Blank().layoutWeight(1)

          Button() {
            Text(i18nService.t('start_test'))
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
                lessonCompletedKey: this.viewModel.lessonCompletedKey
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
      Text(i18nService.t('learning_completed'))
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
