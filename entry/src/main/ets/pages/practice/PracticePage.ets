import { PracticeViewModel } from '../../viewmodel/PracticeViewModel'
import { router, promptAction } from '@kit.ArkUI'
import { PracticeRecordDialog } from '../../widgets/PracticeRecordDialog'
import { FavoritesStore } from '../../store/FavoritesStore'
import { audioService } from '../../services/AudioService'
import { i18nService } from '../../services/I18nService'

// 本地化字符串接口
interface LocalizedStrings {
  easy: string
  medium: string
  hard: string
  favorites: string
  mistakes: string
  favorite_removed: string
  favorite_added: string
}

@Entry
@Component
export struct PracticePage {
  @State vm: PracticeViewModel = new PracticeViewModel()
  @State circleScale: number = 1.0 // 控制圆圈和字符的缩放动画
  @State displayCharacter: string = '' // 用于显示的字符，控制动画时序
  // 可视化进度（0~1），用于平滑填充进度弧
  @State progressVisual: number = 0
  @State favoritesStore: FavoritesStore = FavoritesStore.getInstance()
  @State soundEnabled: boolean = true // 声音开关状态
  // 使用 StorageLink 监听语言变化
  @StorageLink('currentLanguage') currentLanguage: string = 'zh-CN'
  // 语言变化计数器，用于强制UI刷新
  @State langTick: number = 0
  // 缓存本地化字符串
  @State strings: LocalizedStrings = {
    easy: '',
    medium: '',
    hard: '',
    favorites: '',
    mistakes: '',
    favorite_removed: '',
    favorite_added: ''
  }
  private languageChangeListener: ((lang: string) => void) | null = null
  private progressTimer: number | null = null
  private targetProgress: number = 0
  private dialogController: CustomDialogController = new CustomDialogController({
    builder: PracticeRecordDialog({
      vm: $vm
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: false
  })
  private difficulty: Resource | string = '简单'
  private lastCharacterChangeId: number = -1
  private animationTimer: number | null = null
  private readonly pillRadius: number = 20

  aboutToAppear(): void {
    // 添加语言变化监听器
    this.languageChangeListener = (lang: string) => {
      console.log(`[PracticePage] Language changed to: ${lang}`)
      // 更新缓存的本地化字符串
      this.strings = this.computeStrings()
      // 触发UI强制刷新
      this.langTick++
    }
    
    // 启动语言变化监听
    this.startLanguageWatcher()
    
    // 初始化本地化字符串
    this.strings = this.computeStrings()
    
    // 从路由参数获取难度和字符列表（容错处理，避免无参数时崩溃）
    try {
      const params: Record<string, Object> = (router.getParams?.() as Record<string, Object>) ?? {}
      const diff = (params['difficulty'] as string) || ''
      const characters = (params['characters'] as string[]) || []
      this.difficulty = diff && typeof diff === 'string' ? diff : this.strings.easy || i18nService.t('easy')
      
      // 如果是收藏或错题本模式，使用指定的字符列表
      if ((this.difficulty === 'favorites' || this.difficulty === 'mistakes') && characters && Array.isArray(characters)) {
        this.vm.initWithCharacters(this.difficulty, characters)
      } else {
        this.vm.init(this.difficulty as string)
      }
    } catch {
      this.difficulty = this.strings.easy || i18nService.t('easy')
      this.vm.init(this.difficulty as string)
    }
    console.error(`[PracticePage] aboutToAppear: difficulty=${this.difficulty}`)
    this.displayCharacter = this.vm.getCurrentCharacter() // 初始化显示字符
    this.lastCharacterChangeId = this.vm.getCharacterChangeId()
    this.startAnimationCheck()
  }

  // 获取格式化的标题显示
  private getFormattedTitle(): string {
    // 引用langTick确保标题会更新
    if (typeof this.difficulty === 'string') {
      // 处理特殊模式
      if (this.difficulty === 'favorites') {
        return this.strings.favorites || i18nService.t('favorites')
      }
      if (this.difficulty === 'mistakes') {
        return this.strings.mistakes || i18nService.t('mistakes')
      }
      
      // 处理难度级别 - 使用缓存的字符串
      if (this.difficulty === 'easy' || this.difficulty === '简单') {
        return this.strings.easy || i18nService.t('easy')
      }
      if (this.difficulty === 'medium' || this.difficulty === '中等') {
        return this.strings.medium || i18nService.t('medium')
      }
      if (this.difficulty === 'hard' || this.difficulty === '困难') {
        return this.strings.hard || i18nService.t('hard')
      }
      
      // 如果是已经本地化的字符串，直接返回
      return this.difficulty
    }
    return String(this.difficulty)
  }

  aboutToDisappear(): void {
    this.vm.destroy()
    if (this.animationTimer) {
      clearInterval(this.animationTimer)
    }
    if (this.progressTimer) {
      clearInterval(this.progressTimer)
      this.progressTimer = null
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
        console.log(`[PracticePage] Language changed from ${lastLanguage} to ${this.currentLanguage}`)
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
      easy: i18nService.t('easy'),
      medium: i18nService.t('medium'),
      hard: i18nService.t('hard'),
      favorites: i18nService.t('favorites'),
      mistakes: i18nService.t('mistakes'),
      favorite_removed: i18nService.t('favorite_removed'),
      favorite_added: i18nService.t('favorite_added')
    }
  }

  // Removed onPageShow system bar re-application to avoid flicker

  // 开始检查字符变化的定时器
  private startAnimationCheck(): void {
    this.animationTimer = setInterval(() => {
      const currentChangeId = this.vm.getCharacterChangeId()
      if (currentChangeId !== this.lastCharacterChangeId) {
        this.lastCharacterChangeId = currentChangeId
        
        // 先隐藏当前字母（保持旧字符内容）
        animateTo({
          duration: 100,
          curve: Curve.EaseIn
        }, () => {
          this.circleScale = 0.0
        })
        
        // 等待隐藏动画完成后更新字符内容并显示新字母
        setTimeout(() => {
          this.displayCharacter = this.vm.getCurrentCharacter() // 更新显示字符
          // 重置可视化进度
          this.setProgressInstant(0)
          
          // 再等50ms后开始显示新字母的动画
          setTimeout(() => {
            animateTo({
              duration: 200,
              curve: Curve.EaseInOut
            }, () => {
              this.circleScale = 1.0
            })
          }, 50)
        }, 150) // 等待隐藏动画完成
      }
      // 检查进度变化，平滑推进可视化进度
      const p = Math.max(0, Math.min(this.vm.getProgress(), 1))
      if (Math.abs(p - this.targetProgress) > 1e-6) {
        this.targetProgress = p
        this.animateProgressTo(this.targetProgress, 320)
      }
    }, 100) // 每100ms检查一次
  }



  @Builder
  private TitleBar() {
    Row() {
      Button() {
        Image($rawfile('ic_back.svg')).width(24).height(24).fillColor(Color.White)
      }
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        router.back()
      })

      Text(this.getFormattedTitle())
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Button() {
        Image($rawfile('ic_records.svg')).width(22).height(22).fillColor(Color.White)
      }
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.dialogController.open()
      })
    }
    .height(56)
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.Black)
  }

  @Builder
  private ProgressCircle() {
    // 使用字符作为唯一key，确保每次字符变化时触发动画
    Stack({ alignContent: Alignment.Center }) {
      // 进度圆环：只有在用户出现错误后才显示
      if (this.vm.getHasIncorrectAttempt()) {
        // 背景圈（暗色）- 错误后立即显示
        Circle({ width: 200, height: 200 })
          .fill(Color.Transparent)
          .strokeWidth(8)
          .stroke('#333333')

        // 进度弧 - 从顶部中心开始（12点方向）
        Circle({ width: 200, height: 200 })
          .fill(Color.Transparent)
          .strokeWidth(8)
          .stroke(this.vm.getProgress() >= 1.0 ? Color.Green : '#FFD700')
          // 采用 [填充长度, 剩余长度]，绑定可视化进度，避免偏移截断
          .strokeDashArray([this.getProgressVisualLength(), this.getCircumference() - this.getProgressVisualLength()])
          // 起点设为周长的1/4，确保从12点方向开始
          .strokeDashOffset(this.getCircumference() / 4)
          .strokeLineCap(LineCapStyle.Round)
          .opacity(this.progressVisual > 0 ? 1 : 0) // 进度为0时完全透明
      }

      // 内层圆圈（始终显示）- 添加颜色过渡动画
      Column()
        .width(180)
        .height(180)
        .backgroundColor(
          this.vm.getShowResult() && !this.vm.getIsCorrect() ? Color.Red : 
          (this.vm.getIsCorrect() ? Color.Green : '#FFD700')
        )
        .borderRadius(90)
        .animation({ duration: 300, curve: Curve.EaseInOut })

      // 主字符 - 使用displayCharacter控制显示时序
      Text(this.displayCharacter)
        .fontSize(72)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
    }
    .width(200)
    .height(200)
    .scale({ x: this.circleScale, y: this.circleScale }) // 使用状态控制的缩放
  }

  @Builder
  private MorseDisplay() {
    Column() {
      if (this.vm.getShowHint() || this.vm.getShowCorrectAnswer()) {
        Text(this.vm.getCurrentMorse().split('.').join('·'))
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .fontFamily('monospace')
          .letterSpacing(2)
          .textAlign(TextAlign.Center)
          .width('100%')
      } else {
        Image($rawfile('ic_eye.svg'))
          .width(28)
          .height(28)
          .fillColor('#FFFFFF')
      }
    }
    .height(60)
    .width(150)
    .backgroundColor('#1A1A1A')
    .borderRadius(this.pillRadius)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.vm.flashHint()
    })
  }

  private getCircumference(): number {
    // 直径200，描边半径近似 90（扣除描边宽度的一半）；对视觉误差不敏感，直接按100半径计算即可
    return 2 * Math.PI * 100
  }

  // 使用可视化进度计算当前弧长
  private getProgressVisualLength(): number {
    return this.getCircumference() * Math.max(0, Math.min(this.progressVisual, 1))
  }

  // 立即设置可视化进度（不动画）
  private setProgressInstant(value: number) {
    if (this.progressTimer) {
      clearInterval(this.progressTimer)
      this.progressTimer = null
    }
    this.progressVisual = Math.max(0, Math.min(value, 1))
    this.targetProgress = this.progressVisual
  }

  // 自定义补间动画至目标进度
  private animateProgressTo(target: number, duration: number = 500) {
    if (this.progressTimer) {
      clearInterval(this.progressTimer)
      this.progressTimer = null
    }
    const start = this.progressVisual
    const end = Math.max(0, Math.min(target, 1))
    const delta = end - start
    if (Math.abs(delta) < 1e-4 || duration <= 0) {
      this.setProgressInstant(end)
      return
    }
    const startTs = Date.now()
    const easeInOutCubic = (t: number) => t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2
    this.progressTimer = setInterval(() => {
      const t = Math.min(1, (Date.now() - startTs) / duration)
      this.progressVisual = start + delta * easeInOutCubic(t)
      if (t >= 1) {
        if (this.progressTimer) {
          clearInterval(this.progressTimer)
          this.progressTimer = null
        }
        this.progressVisual = end
      }
    }, 16)
  }

  @Builder
  private InputDisplay() {
    Column() {
      Text(this.vm.getUserInput().split('.').join('·'))
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontFamily('monospace')
        .letterSpacing(4)
        .fontColor(
          this.vm.getShowResult() && this.vm.getIsCorrect() ? Color.Green :
          (this.vm.getShowResult() && !this.vm.getIsCorrect() ? Color.Red :
          (this.vm.getUserInput().length === 0 ? Color.Transparent : '#FFD700'))
        )
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    // Fixed size to reserve space even when empty
    .width(400)
    .height(60)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private ToolButtons() {
    Row() {
      // 收藏按钮
      Button() {
        Image($rawfile('ic_star.svg')).width(24).height(24)
          .fillColor(this.vm.getIsFavorite() ? '#FFD700' : Color.White)
      }
        .onClick(() => {
          const currentChar = this.vm.getCurrentCharacter()
          const wasFavorite = this.favoritesStore.isFavorite(currentChar)
          this.favoritesStore.toggleFavorite(currentChar)
          // 同步VM中的收藏状态以驱动UI更新
          this.vm.toggleFavorite()
          
          // 显示toast提示
          promptAction.showToast({
            message: wasFavorite ? (this.strings.favorite_removed || i18nService.t('favorite_removed')) : (this.strings.favorite_added || i18nService.t('favorite_added')),
            duration: 1500,
            bottom: '80%'
          })
        })
        .width(48).height(48)
        .backgroundColor(Color.Transparent)

      Blank().width(40)

      // 声音开关按钮
      Button() {
        Image($rawfile(this.soundEnabled ? 'ic_sound_on.svg' : 'ic_sound_off.svg'))
          .width(24).height(24).fillColor(Color.White)
      }
        .onClick(() => {
          this.soundEnabled = !this.soundEnabled
        })
        .width(48).height(48)
        .backgroundColor(Color.Transparent)

      Blank().width(40)

      // 下一个按钮
      Button() {
        Image($rawfile('ic_skip.svg')).width(24).height(24).fillColor(Color.White)
      }
        .onClick(() => this.vm.passCharacter())
        .width(48).height(48)
        .backgroundColor(Color.Transparent)
    }
    .justifyContent(FlexAlign.Center)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  private BottomKeys() {
    Row() {
      // 点 (短音)
      Button() {
        Circle({ width: 20, height: 20 })
          .fill('#FFD700')
      }
      .height(80)
      .backgroundColor('#1A1A1A')
      .borderRadius(this.pillRadius)
      .border({ width: 1, color: '#333333' })
      .onClick(async () => {
        this.vm.addDot()
        if (this.soundEnabled) {
          await audioService.playDit()
        }
      })
      .layoutWeight(1)

      Blank().width(20)

      // 划 (长音)
      Button() {
        Rect({ width: 40, height: 12 })
          .fill('#FFD700')
      }
      .height(80)
      .backgroundColor('#1A1A1A')
      .borderRadius(this.pillRadius)
      .border({ width: 1, color: '#333333' })
      .onClick(async () => {
        this.vm.addDash()
        if (this.soundEnabled) {
          await audioService.playDah()
        }
      })
      .layoutWeight(1)
    }
    .padding({ left: 20, right: 20, bottom: 12 })
  }



  build() {
    Stack() {
      Column() {
        this.TitleBar()

        // 内容区域 - 响应式宽度，最大480vp
        Column() {
          Blank().height(12)

          // 主要内容（对齐 LetterLessonPage 布局）
          Column() {
            // 字符与进度圆圈
            this.ProgressCircle()

            Blank().height(40)

            // 目标电码/提示显示
            this.MorseDisplay()

            Blank().height(12)

            // 用户输入显示
            this.InputDisplay()
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Blank().height(12)
          this.ToolButtons()
          Blank().height(16)
          this.BottomKeys()
        }
        .width('100%')
        .constraintSize({ maxWidth: 480 })
        .padding({ left: 20, right: 20 })
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
}
