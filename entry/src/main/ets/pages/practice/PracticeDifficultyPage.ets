import { router } from '@kit.ArkUI'
// System bar colors are set globally in EntryAbility
import { FavoritesStore } from '../../store/FavoritesStore'
import { promptAction } from '@kit.ArkUI'
import { resourceManager, i18n } from '@kit.LocalizationKit'

interface ModeItem {
  key: string
  titleRes: Resource
  descRes: Resource
}


@Entry
@Component
export struct PracticeDifficultyPage {
  @State favoritesStore: FavoritesStore = FavoritesStore.getInstance()
  @State currentLanguage: string = 'zh-CN'
  // 资源管理器
  private resourceMgr: resourceManager.ResourceManager | null = null

  private modes: ModeItem[] = [
    {
      key: 'text_to_code',
      titleRes: $r('app.string.text_to_code_title'),
      descRes: $r('app.string.text_to_code_desc')
    },
    {
      key: 'code_to_text',
      titleRes: $r('app.string.code_to_text_title'),
      descRes: $r('app.string.code_to_text_desc')
    },
    {
      key: 'sound_to_text',
      titleRes: $r('app.string.sound_to_text_title'),
      descRes: $r('app.string.sound_to_text_desc')
    }
  ]

  async aboutToAppear(): Promise<void> {
    // 初始化资源管理器
    try {
      this.resourceMgr = getContext(this).resourceManager
    } catch (error) {
      console.error('[PracticeDifficultyPage] Failed to get resource manager:', error)
    }

    // 获取当前系统语言
    this.currentLanguage = this.getCurrentLanguage()
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

  private openPractice(mode: string): void {
    // 直接导航到练习页面
    router.push({
      url: 'pages/practice/PracticePage',
      params: {
        mode: mode
      }
    })
  }

  private openFavorites(): void {
    const favorites = this.favoritesStore.getFavoriteCharacters()
    if (favorites.length === 0) {
      try {
        promptAction.showToast({
          message: $r('app.string.favorites_empty'),
          duration: 2000,
          bottom: '80%'
        })
      } catch (error) {
        console.error('[PracticeDifficulty] Failed to show toast:', error)
      }
      return
    }

    // 导航到混合模式练习页面
    router.push({
      url: 'pages/practice/PracticePage',
      params: {
        mode: 'text_to_code', // 起始模式
        characters: favorites,
        mixedMode: true // 标记为混合模式
      }
    })
  }

  private openMistakes(): void {
    const mistakes = this.favoritesStore.getMistakeCharacters()
    if (mistakes.length === 0) {
      try {
        promptAction.showToast({
          message: $r('app.string.mistakes_empty'),
          duration: 2000,
          bottom: '80%'
        })
      } catch (error) {
        console.error('[PracticeDifficulty] Failed to show toast:', error)
      }
      return
    }

    // 导航到混合模式练习页面
    router.push({
      url: 'pages/practice/PracticePage',
      params: {
        mode: 'text_to_code', // 起始模式
        characters: mistakes,
        mixedMode: true // 标记为混合模式
      }
    })
  }

  @Builder
  private ModeCard(item: ModeItem) {
    // 居中文本的卡片项
    Column() {
      // 内容垂直居中对齐
      Column() {
        Text(item.titleRes)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
      }
      .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .padding({ left: 16, right: 16, top: 28, bottom: 28 })
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
  private SpecialModeCard(title: Resource, desc: Resource, mode: string, onClick: () => void) {
    // 特殊模式卡片（收藏和错题本）
    Column() {
      // 内容垂直居中对齐
      Column() {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)

        Text(desc)
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
      .onClick(onClick)
  }

  @Builder
  private SingleModeCard(title: Resource, desc: Resource, onClick: () => void) {
    Column() {
      Column() {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)

        Text(desc)
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
      .onClick(onClick)
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
      Scroll() {
        Column() {
          Blank().height(20)

          // 练习模式卡片
          ForEach(this.modes, (item: ModeItem, index: number) => {
            Column() {
              this.ModeCard(item)
              if (index < this.modes.length - 1) {
                Blank().height(16)
              }
            }
            .width('100%')
          }, (item: ModeItem) => item.key)

          // 分隔线
          Column() {
            Blank().height(20)
            Divider()
              .color('#333333')
              .strokeWidth(1)
              .width('50%')
            Blank().height(20)
          }
          .width('100%')
            .alignItems(HorizontalAlign.Center)

          // 收藏练习 - 混合模式
          this.SingleModeCard(
            $r('app.string.favorites'),
            $r('app.string.favorites_mixed_mode_desc'),
            () => this.openFavorites()
          )

          Blank().height(16)

          // 错题本练习 - 混合模式
          this.SingleModeCard(
            $r('app.string.mistakes'),
            $r('app.string.mistakes_mixed_mode_desc'),
            () => this.openMistakes()
          )

          Blank().height(20)
        }
        .width('100%')
      }
      .width('100%')
        .constraintSize({ maxWidth: 480 })
        .padding({ left: 20, right: 20 })
        .layoutWeight(1)
        .align(Alignment.Center)
    }
    .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
