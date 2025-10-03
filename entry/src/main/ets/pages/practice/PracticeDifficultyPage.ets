import { router } from '@kit.ArkUI'
// System bar colors are set globally in EntryAbility
import { FavoritesStore } from '../../store/FavoritesStore'
import { promptAction } from '@kit.ArkUI'
import { resourceManager, i18n } from '@kit.LocalizationKit'

interface DifficultyItem {
  key: string
  label: Resource
  desc: Resource
}


@Entry
@Component
export struct PracticeDifficultyPage {
  @State favoritesStore: FavoritesStore = FavoritesStore.getInstance()
  @State currentLanguage: string = 'zh-CN'
  // 资源管理器
  private resourceMgr: resourceManager.ResourceManager | null = null

  private difficulties: DifficultyItem[] = []

  async aboutToAppear(): Promise<void> {
    // 初始化资源管理器
    try {
      this.resourceMgr = getContext(this).resourceManager
    } catch (error) {
      console.error('[PracticeDifficultyPage] Failed to get resource manager:', error)
    }

    // 获取当前系统语言
    this.currentLanguage = this.getCurrentLanguage()

    // 初始化难度列表
    this.buildDifficulties()
  }

  aboutToDisappear() {
    // 清理资源
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
      console.error('[PracticeDifficultyPage] Failed to get current language:', error)
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
      console.error(`[PracticeDifficultyPage] Failed to get string resource for key: ${key}`, error)
      return key
    }
  }

  // 构建难度列表
  private buildDifficulties(): void {
    this.difficulties = [
      { key: 'easy', label: $r('app.string.easy'), desc: $r('app.string.easy_desc') },
      { key: 'medium', label: $r('app.string.medium'), desc: $r('app.string.medium_desc') },
      { key: 'hard', label: $r('app.string.hard'), desc: $r('app.string.hard_desc') }
    ]
  }

  private openPractice(difficulty: string): void {
    console.error(`[PracticeDifficulty] opening practice page with difficulty=${difficulty}`)
    router.push({
      url: 'pages/practice/PracticePage',
      params: {
        difficulty: difficulty
      }
    })
  }

  private openFavorites(): void {
    const favorites = this.favoritesStore.getFavoriteCharacters()
    if (favorites.length === 0) {
      promptAction.showToast({
        message: $r('app.string.favorites_empty'),
        duration: 2000,
        bottom: '80%'
      })
      return
    }

    router.push({
      url: 'pages/practice/PracticePage',
      params: {
        difficulty: 'favorites',
        characters: favorites
      }
    })
  }

  private openMistakes(): void {
    const mistakes = this.favoritesStore.getMistakeCharacters()
    if (mistakes.length === 0) {
      promptAction.showToast({
        message: $r('app.string.mistakes_empty'),
        duration: 2000,
        bottom: '80%'
      })
      return
    }

    router.push({
      url: 'pages/practice/PracticePage',
      params: {
        difficulty: 'mistakes',
        characters: mistakes
      }
    })
  }

  @Builder
  private DifficultyCard(item: DifficultyItem) {
    // 居中文本的卡片项
    Column() {
      // 内容垂直居中对齐
      Column() {
        Text(item.label)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)

        Text(item.desc)
          .fontSize(12)
          .fontColor('#CCCCCC')
          .textAlign(TextAlign.Center)
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .padding({ left: 16, right: 16, top: 18, bottom: 18 })
    }
    .width('100%')
      .backgroundColor('#1A1A1A')
      .borderRadius(14)
      .border({ width: 1, color: '#333333' })
      .onClick(() => {
        this.openPractice(item.key)
      })
  }

  @Builder
  private FavoritesCard() {
    // 收藏卡片
    Column() {
      // 内容垂直居中对齐
      Column() {
        Text($r('app.string.favorites'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)

        Text($r('app.string.practice_favorites'))
          .fontSize(12)
          .fontColor('#CCCCCC')
          .textAlign(TextAlign.Center)
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .padding({ left: 16, right: 16, top: 18, bottom: 18 })
    }
    .width('100%')
      .backgroundColor('#1A1A1A')
      .borderRadius(14)
      .border({ width: 1, color: '#333333' })
      .onClick(() => this.openFavorites())
  }

  @Builder
  private MistakesCard() {
    // 错题本卡片
    Column() {
      // 内容垂直居中对齐
      Column() {
        Text($r('app.string.mistakes'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)

        Text($r('app.string.mistakes_desc'))
          .fontSize(12)
          .fontColor('#CCCCCC')
          .textAlign(TextAlign.Center)
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .padding({ left: 16, right: 16, top: 18, bottom: 18 })
    }
    .width('100%')
      .backgroundColor('#1A1A1A')
      .borderRadius(14)
      .border({ width: 1, color: '#333333' })
      .onClick(() => this.openMistakes())
  }

  @Builder
  private TitleBar() {
    // 顶部标题栏
    Row() {
      Text($r('app.string.practice'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
    }
    .height(56)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#000000')
  }

  build() {
    Column() {
      this.TitleBar()

      // 内容区域 - 响应式宽度，最大480vp
      Column() {
        // 难度选择卡片
        ForEach(this.difficulties, (item: DifficultyItem, index: number) => {
          Column() {
            this.DifficultyCard(item)
            if (index < this.difficulties.length - 1) {
              Blank().height(16)
            }
          }
          .width('100%')
        }, (item: DifficultyItem) => item.key)

        // 收藏和错题本卡片
        Column() {
          Blank().height(24)
          this.FavoritesCard()
          Blank().height(16)
          this.MistakesCard()
        }
        .width('100%')
      }
      .width('100%')
        .constraintSize({ maxWidth: 480 })
        .padding({ left: 20, right: 20, top: 20 })
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
