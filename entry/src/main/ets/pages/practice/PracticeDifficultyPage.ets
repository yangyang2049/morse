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

// 本地化字符串接口
interface LocalizedStrings {
  practice: string
  easy: string
  easy_desc: string
  medium: string
  medium_desc: string
  hard: string
  hard_desc: string
  favorites: string
  practice_favorites: string
  mistakes: string
  mistakes_desc: string
  favorites_empty: string
  mistakes_empty: string
}

@Entry
@Component
export struct PracticeDifficultyPage {
  @State favoritesStore: FavoritesStore = FavoritesStore.getInstance()
  @State private refreshTrigger: number = 0
  // 使用 StorageLink 监听语言变化
  @StorageLink('currentLanguage') currentLanguage: string = 'zh'
  // 语言变化计数器，用于强制UI刷新
  @State langTick: number = 0
  // 缓存本地化字符串
  @State strings: LocalizedStrings = {
    practice: '',
    easy: '',
    easy_desc: '',
    medium: '',
    medium_desc: '',
    hard: '',
    hard_desc: '',
    favorites: '',
    practice_favorites: '',
    mistakes: '',
    mistakes_desc: '',
    favorites_empty: '',
    mistakes_empty: ''
  }
  private languageChangeListener: ((lang: string) => void) | null = null
  
  private difficulties: DifficultyItem[] = []

  aboutToAppear() {
    // System bar colors are set globally in EntryAbility
    // 添加语言变化监听器
    this.languageChangeListener = (lang: string) => {
      console.log(`[PracticeDifficultyPage] Language changed to: ${lang}`)
      // 更新缓存的本地化字符串
      this.strings = this.computeStrings()
      // 重建难度列表
      this.buildDifficulties()
      // 触发UI强制刷新
      this.langTick++
    }
    
    // 启动语言变化监听
    this.startLanguageWatcher()
    
    // 初始化本地化字符串和难度列表
    this.strings = this.computeStrings()
    this.buildDifficulties()
  }

  aboutToDisappear() {
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
        console.log(`[PracticeDifficultyPage] Language changed from ${lastLanguage} to ${this.currentLanguage}`)
        lastLanguage = this.currentLanguage
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
  private computeStrings(): LocalizedStrings {
    return {
      practice: i18nService.t('practice'),
      easy: i18nService.t('easy'),
      easy_desc: i18nService.t('easy_desc'),
      medium: i18nService.t('medium'),
      medium_desc: i18nService.t('medium_desc'),
      hard: i18nService.t('hard'),
      hard_desc: i18nService.t('hard_desc'),
      favorites: i18nService.t('favorites'),
      practice_favorites: i18nService.t('practice_favorites'),
      mistakes: i18nService.t('mistakes'),
      mistakes_desc: i18nService.t('mistakes_desc'),
      favorites_empty: i18nService.t('favorites_empty'),
      mistakes_empty: i18nService.t('mistakes_empty')
    }
  }

  // 构建难度列表
  private buildDifficulties(): void {
    this.difficulties = [
      { key: 'easy', label: this.strings.easy, desc: this.strings.easy_desc },
      { key: 'medium', label: this.strings.medium, desc: this.strings.medium_desc },
      { key: 'hard', label: this.strings.hard, desc: this.strings.hard_desc }
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
      // 引用langTick确保toast消息也会更新
      const _ = this.langTick
      promptAction.showToast({
        message: this.strings.favorites_empty || i18nService.t('favorites_empty'),
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
      // 引用langTick确保toast消息也会更新
      const _ = this.langTick
      promptAction.showToast({
        message: this.strings.mistakes_empty || i18nService.t('mistakes_empty'),
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
      // 隐藏的langTick触发器
      Text(this.langTick.toString())
        .opacity(0)
        .width(0)
        .height(0)
      
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
      // 隐藏的langTick触发器
      Text(this.langTick.toString())
        .opacity(0)
        .width(0)
        .height(0)
      
      // 内容垂直居中对齐
      Column() {
        Text(this.strings.favorites || i18nService.t('favorites'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)

        Text(this.strings.practice_favorites || i18nService.t('practice_favorites'))
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
      // 隐藏的langTick触发器
      Text(this.langTick.toString())
        .opacity(0)
        .width(0)
        .height(0)
      
      // 内容垂直居中对齐
      Column() {
        Text(this.strings.mistakes || i18nService.t('mistakes'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)

        Text(this.strings.mistakes_desc || i18nService.t('mistakes_desc'))
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
      // 隐藏的langTick触发器
      Text(this.langTick.toString())
        .opacity(0)
        .width(0)
        .height(0)
      
      Text(this.strings.practice || i18nService.t('practice'))
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
        }, (item: DifficultyItem) => `${item.key}-${this.langTick}`)

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
