import { router } from '@kit.ArkUI'
// System bar colors are set globally in EntryAbility
import { FavoritesStore } from '../../store/FavoritesStore'
import { promptAction } from '@kit.ArkUI'
import { i18nService } from '../../services/I18nService'
// 使用$r()函数替代I18n
import { eventHub, Events } from '../../utils/EventHub'

interface DifficultyItem {
  key: string
  label: string
  desc: string
}

@Entry
@Component
export struct PracticeDifficultyPage {
  @State favoritesStore: FavoritesStore = FavoritesStore.getInstance()
  @State private refreshTrigger: number = 0
  // 使用 StorageLink 监听语言变化
  @StorageLink('currentLanguage') currentLanguage: string = 'zh'
  
  private difficulties: DifficultyItem[] = [
    { key: 'easy', label: i18nService.t('easy'), desc: i18nService.t('easy_desc') },
    { key: 'medium', label: i18nService.t('medium'), desc: i18nService.t('medium_desc') },
    { key: 'hard', label: i18nService.t('hard'), desc: i18nService.t('hard_desc') }
  ]

  aboutToAppear() {
    // System bar colors are set globally in EntryAbility
  }

  aboutToDisappear() {
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
        message: i18nService.t('favorites_empty'),
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
        message: i18nService.t('mistakes_empty'),
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
  private SpecialCard(title: Resource | string, desc: Resource | string, count: number, onClick: () => void) {
    // 居中文本的卡片项 - 与DifficultyCard保持一致的样式
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
  private TitleBar() {
    // 顶部标题栏
    Row() {
      Text(i18nService.t('practice'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
    }
    .height(52)
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
        })

        // 收藏和错题本卡片
        Column() {
          Blank().height(24)
          this.SpecialCard(i18nService.t('favorites'), i18nService.t('practice_favorites'), 0, () => this.openFavorites())
          Blank().height(16)
          this.SpecialCard(i18nService.t('mistakes'), i18nService.t('mistakes_desc'), 0, () => this.openMistakes())
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
