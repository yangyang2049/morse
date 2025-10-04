import { PracticeViewModel } from '../../viewmodel/PracticeViewModel'
import { router, promptAction } from '@kit.ArkUI'
import { PracticeRecordDialog } from '../../widgets/PracticeRecordDialog'
import { FavoritesStore } from '../../store/FavoritesStore'
import { audioService } from '../../services/AudioService'
import { resourceManager, i18n } from '@kit.LocalizationKit'
import preferences from '@ohos.data.preferences'

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
  @State currentLanguage: string = 'zh-CN'
  @State useSingleButton: boolean = false // 是否使用单按钮模式
  @State showButtonModeDialog: boolean = false // 是否显示按钮模式选择对话框
  @State selectedButtonMode: boolean = false // 用户在对话框中选择的模式（不自动高亮）
  @State showSettingsDialog: boolean = false // 是否显示设置对话框
  @State sliderValue: number = 300 // 滑块值状态
  @State settingsDialogScale: number = 0.8 // 设置对话框缩放动画
  @State settingsDialogOpacity: number = 0 // 设置对话框透明度动画
  // 资源管理器
  private resourceMgr: resourceManager.ResourceManager | null = null
  private preferencesStore: preferences.Preferences | null = null
  private progressTimer: number | null = null
  private targetProgress: number = 0
  private dialogController: CustomDialogController = new CustomDialogController({
    builder: PracticeRecordDialog({
      vm: this.vm
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: false
  })
  private difficulty: Resource | string = '简单'
  private lastCharacterChangeId: number = -1
  private animationTimer: number | null = null
  private readonly pillRadius: number = 20
  // 单按钮模式相关
  private pressStartTime: number = 0
  private longPressThreshold: number = 300 // 长按阈值：300ms
  private longPressTimer: number | null = null

  async aboutToAppear(): Promise<void> {
    // 初始化资源管理器
    try {
      this.resourceMgr = getContext(this).resourceManager
    } catch (error) {
      console.error('[PracticePage] Failed to get resource manager:', error)
    }

    // 初始化偏好设置存储
    await this.initPreferences()

    // 获取当前语言 - 优先从AppStorage获取，否则从系统获取
    const storedLanguage = AppStorage.get<string>('currentLanguage')
    if (storedLanguage) {
      this.currentLanguage = storedLanguage
      console.log(`[PracticePage] Using stored language: ${this.currentLanguage}`)
    } else {
      this.currentLanguage = this.getCurrentLanguage()
      console.log(`[PracticePage] Using system language: ${this.currentLanguage}`)
      AppStorage.setOrCreate('currentLanguage', this.currentLanguage)
    }

    // 加载按钮模式偏好设置
    await this.loadButtonModePreference()

    // 加载长按时间偏好设置
    await this.loadLongPressThresholdPreference()

    // 根据按钮模式设置自动检查延迟
    this.vm.setAutoCheckDelay(this.useSingleButton ? 1500 : 600) // 单按钮模式1.5秒，双按钮模式600ms

    // 从路由参数获取难度和字符列表（容错处理，避免无参数时崩溃）
    try {
      const params: Record<string, Object> = (router.getParams?.() as Record<string, Object>) ?? {}
      const diff = (params['difficulty'] as string) || ''
      const characters = (params['characters'] as string[]) || []
      this.difficulty = diff && typeof diff === 'string' ? diff : 'easy'

      // 如果是收藏或错题本模式，使用指定的字符列表
      if ((this.difficulty === 'favorites' || this.difficulty === 'mistakes') && characters && Array.isArray(characters)) {
        this.vm.initWithCharacters(this.difficulty, characters)
      } else {
        this.vm.init(this.difficulty as string)
      }
    } catch {
      this.difficulty = 'easy'
      this.vm.init(this.difficulty as string)
    }
    console.error(`[PracticePage] aboutToAppear: difficulty=${this.difficulty}`)
    this.displayCharacter = this.vm.getCurrentCharacter() // 初始化显示字符
    this.lastCharacterChangeId = this.vm.getCharacterChangeId()
    this.startAnimationCheck()
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
      console.error('[PracticePage] Failed to get current language:', error)
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
      console.error(`[PracticePage] Failed to get string resource for key: ${key}`, error)
      return key
    }
  }

  // 初始化偏好设置存储
  private async initPreferences(): Promise<void> {
    try {
      const context = getContext(this)
      this.preferencesStore = await preferences.getPreferences(context, 'practice_preferences')
      console.log('[PracticePage] Preferences store initialized')
    } catch (error) {
      console.error('[PracticePage] Failed to initialize preferences:', error)
    }
  }

  // 加载按钮模式偏好设置
  private async loadButtonModePreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        const hasSetPreference = await this.preferencesStore.get('has_set_button_mode', false) as boolean
        if (hasSetPreference) {
          this.useSingleButton = await this.preferencesStore.get('use_single_button', false) as boolean
          console.log(`[PracticePage] Loaded button mode preference: ${this.useSingleButton}`)
        } else {
          // 首次使用，显示选择对话框，不预选任何选项
          this.selectedButtonMode = false
          this.showButtonModeDialog = true
          console.log('[PracticePage] First time user, showing button mode dialog')
        }
      }
    } catch (error) {
      console.error('[PracticePage] Failed to load button mode preference:', error)
      this.selectedButtonMode = false
      this.showButtonModeDialog = true
    }
  }

  // 保存按钮模式偏好设置
  private async saveButtonModePreference(useSingle: boolean): Promise<void> {
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.put('use_single_button', useSingle)
        await this.preferencesStore.put('has_set_button_mode', true)
        await this.preferencesStore.flush()
        this.useSingleButton = useSingle
        console.log(`[PracticePage] Saved button mode preference: ${useSingle}`)

        // 更新自动检查延迟
        this.vm.setAutoCheckDelay(this.useSingleButton ? 1500 : 600)

        // 重新启动动画检查定时器以使用新的间隔
        if (this.animationTimer) {
          clearInterval(this.animationTimer)
        }
        this.startAnimationCheck()
      }
    } catch (error) {
      console.error('[PracticePage] Failed to save button mode preference:', error)
    }
  }

  // 加载长按时间偏好设置
  private async loadLongPressThresholdPreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        this.longPressThreshold = await this.preferencesStore.get('long_press_threshold', 300) as number
        console.log(`[PracticePage] Loaded long press threshold: ${this.longPressThreshold}`)
      }
    } catch (error) {
      console.error('[PracticePage] Failed to load long press threshold preference:', error)
    }
  }

  // 保存长按时间偏好设置
  private async saveLongPressThresholdPreference(threshold: number): Promise<void> {
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.put('long_press_threshold', threshold)
        await this.preferencesStore.flush()
        this.longPressThreshold = threshold
        console.log(`[PracticePage] Saved long press threshold: ${threshold}`)
      }
    } catch (error) {
      console.error('[PracticePage] Failed to save long press threshold preference:', error)
    }
  }

  // 单按钮模式：处理按下
  private handleSingleButtonPress(): void {
    this.pressStartTime = Date.now()

    // 设置长按定时器
    this.longPressTimer = setTimeout(() => {
      this.handleLongPress()
    }, this.longPressThreshold)
  }

  // 单按钮模式：处理释放
  private async handleSingleButtonRelease(): Promise<void> {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer)
      this.longPressTimer = null
    }

    const pressDuration = Date.now() - this.pressStartTime
    if (pressDuration < this.longPressThreshold) {
      // 短按：添加点
      this.vm.addDot()
      if (this.soundEnabled) {
        await audioService.playDit()
      }
    }
  }

  // 单按钮模式：处理长按
  private async handleLongPress(): Promise<void> {
    // 长按：添加划
    this.vm.addDash()
    if (this.soundEnabled) {
      await audioService.playDah()
    }
  }

  // 获取格式化的标题显示
  private getFormattedTitle(): Resource | string {
    if (typeof this.difficulty === 'string') {
      // 处理特殊模式
      if (this.difficulty === 'favorites') {
        return $r('app.string.favorites')
      }
      if (this.difficulty === 'mistakes') {
        return $r('app.string.mistakes')
      }

      // 处理难度级别
      if (this.difficulty === 'easy' || this.difficulty === '简单') {
        return $r('app.string.easy')
      }
      if (this.difficulty === 'medium' || this.difficulty === '中等') {
        return $r('app.string.medium')
      }
      if (this.difficulty === 'hard' || this.difficulty === '困难') {
        return $r('app.string.hard')
      }

      // 如果是已经本地化的字符串，直接返回
      return this.difficulty
    }
    return this.difficulty
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
  }


  // Removed onPageShow system bar re-application to avoid flicker

  // 开始检查字符变化的定时器
  private startAnimationCheck(): void {
    // 根据按钮模式设置不同的检查间隔
    const checkInterval = this.useSingleButton ? 200 : 100 // 单按钮模式200ms，双按钮模式100ms
    console.log(`[PracticePage] Animation check interval set to: ${checkInterval}ms (single button: ${this.useSingleButton})`)

    this.animationTimer = setInterval(() => {
      const currentChangeId = this.vm.getCharacterChangeId()
      if (currentChangeId !== this.lastCharacterChangeId) {
        this.lastCharacterChangeId = currentChangeId

        // 先隐藏当前字母（保持旧字符内容）
        animateTo({
          duration: 50,
          curve: Curve.EaseIn
        }, () => {
          this.circleScale = 0.0
        })

        // 等待隐藏动画完成后更新字符内容并显示新字母
        setTimeout(() => {
          this.displayCharacter = this.vm.getCurrentCharacter() // 更新显示字符
          // 重置可视化进度
          this.setProgressInstant(0)

          // 立即开始显示新字母的动画
          animateTo({
            duration: 100,
            curve: Curve.EaseInOut
          }, () => {
            this.circleScale = 1.0
          })
        }, 60) // 等待隐藏动画完成
      }
      // 检查进度变化，平滑推进可视化进度
      const p = Math.max(0, Math.min(this.vm.getProgress(), 1))
      if (Math.abs(p - this.targetProgress) > 1e-6) {
        this.targetProgress = p
        this.animateProgressTo(this.targetProgress, 150)
      }
    }, checkInterval)
  }



  @Builder
  private TitleBar() {
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

      Text(this.getFormattedTitle())
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Button() {
        Image($rawfile('ic_records.svg')).width(22).height(22).fillColor(Color.White)
      }
      .width(48)
        .height(48)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          // 每次打开前重新创建对话框控制器，确保语言状态是最新的
          this.dialogController = new CustomDialogController({
            builder: PracticeRecordDialog({
              vm: this.vm
            }),
            autoCancel: true,
            alignment: DialogAlignment.Center,
            customStyle: false
          })
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
  private animateProgressTo(target: number, duration: number = 200) {
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
        .onClick(async () => {
        const currentChar = this.vm.getCurrentCharacter()
        const wasFavorite = this.favoritesStore.isFavorite(currentChar)
        this.favoritesStore.toggleFavorite(currentChar)
        // 同步VM中的收藏状态以驱动UI更新
        this.vm.toggleFavorite()

        // 显示toast提示
        const message = wasFavorite ? await this.getStringResource('favorite_removed') : await this.getStringResource('favorite_added')
        promptAction.showToast({
          message: message,
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
          .width(24).height(24)
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
    if (this.useSingleButton) {
      // 单按钮模式
      Row() {
        // 左侧占位框
        Column()
          .width(48)
          .height(48)

        // 主按钮
        Button() {
          Text('·')
            .fontSize(24)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold)
        }
        .height(120)
          .width(120)
          .backgroundColor('#FFD700')
          .borderRadius(0)
          .onTouch((event) => {
            if (event.type === TouchType.Down) {
              this.handleSingleButtonPress()
            } else if (event.type === TouchType.Up) {
              this.handleSingleButtonRelease()
            }
          })

        // 右侧设置按钮
        Button() {
          Image($rawfile('ic_settings.svg'))
            .width(24)
            .height(24)
        }
        .width(48)
          .height(48)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.sliderValue = this.longPressThreshold
            // 重置动画状态
            this.settingsDialogScale = 0.8
            this.settingsDialogOpacity = 0
            this.showSettingsDialog = true
            // 开始出现动画
            setTimeout(() => {
              animateTo({
                duration: 200,
                curve: Curve.EaseOut
              }, () => {
                this.settingsDialogScale = 1.0
                this.settingsDialogOpacity = 1.0
              })
            }, 10)
          })
      }
      .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .padding({ left: 20, right: 20, bottom: 12 })
    } else {
      // 双按钮模式
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
  }

  @Builder
  private ButtonModeDialog() {
    Column() {
      Column() {
        Text($r('app.string.select_practice_input_mode'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ bottom: 4 })

        Text(this.currentLanguage.startsWith('zh') ? '可在设置中更改此选项' : 'You can change this in settings')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 20 })

      // 双按钮模式选项
      Row() {
        Column() {
          Text($r('app.string.dual_button_mode'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .margin({ bottom: 8 })
          Text($r('app.string.dual_button_mode_desc'))
            .fontSize(12)
            .fontColor('#999999')
        }
        .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

        if (!this.selectedButtonMode) {
          Circle()
            .width(16)
            .height(16)
            .fill(Color.Transparent)
            .stroke('#FFD700')
            .strokeWidth(2)
        }
      }
      .width('100%')
        .padding(16)
        .backgroundColor('#111111')
        .borderRadius(8)
        .margin({ bottom: 8 })
        .border({
          width: !this.selectedButtonMode ? 1 : 0.5,
          color: !this.selectedButtonMode ? '#FFD700' : '#222222',
          radius: 8
        })
        .onClick(() => {
          this.selectedButtonMode = false
        })

      // 单按钮模式选项
      Row() {
        Column() {
          Text($r('app.string.single_button_mode'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .margin({ bottom: 8 })
          Text($r('app.string.single_button_mode_desc'))
            .fontSize(12)
            .fontColor('#999999')
        }
        .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

        if (this.selectedButtonMode) {
          Circle()
            .width(16)
            .height(16)
            .fill(Color.Transparent)
            .stroke('#FFD700')
            .strokeWidth(2)
        }
      }
      .width('100%')
        .padding(16)
        .backgroundColor('#111111')
        .borderRadius(8)
        .border({
          width: this.selectedButtonMode ? 1 : 0.5,
          color: this.selectedButtonMode ? '#FFD700' : '#222222',
          radius: 8
        })
        .onClick(() => {
          this.selectedButtonMode = true
        })

      // 确认按钮
      Button($r('app.string.confirm'))
        .width('100%')
        .height(48)
        .backgroundColor('#FFD700')
        .borderRadius(8)
        .fontColor(Color.Black)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })
        .onClick(() => {
          this.saveButtonModePreference(this.selectedButtonMode)
          this.showButtonModeDialog = false
        })
    }
    .padding(20)
      .backgroundColor('#2A2A2A')
      .borderRadius(12)
      .width('90%')
      .constraintSize({ maxWidth: 400 })
  }

  @Builder
  private SettingsDialog() {
    Column() {
      Row() {
        Text($r('app.string.settings'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Blank()
        Button() {
          Image($rawfile('ic_close.svg'))
            .width(20)
            .height(20)
            .fillColor(Color.White)
        }
        .width(32)
          .height(32)
          .backgroundColor('rgba(128, 128, 128, 0.2)')
          .borderRadius(16)
          .onClick(() => {
            // 开始退出动画
            animateTo({
              duration: 150,
              curve: Curve.EaseIn
            }, () => {
              this.settingsDialogScale = 0.8
              this.settingsDialogOpacity = 0
            })
            // 动画完成后关闭对话框
            setTimeout(() => {
              this.showSettingsDialog = false
            }, 150)
          })
      }
      .width('100%')
        .margin({ bottom: 20 })

      // 长按时间设置
      Row() {
        Column() {
          Text(this.currentLanguage.startsWith('zh') ? '长按时间' : 'Long Press Duration')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .margin({ bottom: 8 })
          Text(`${this.sliderValue}ms`)
            .fontSize(14)
            .fontColor('#FFD700')
        }
        .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
        .padding(16)
        .backgroundColor('#111111')
        .borderRadius(8)
        .margin({ bottom: 8 })

      // 滑块控制
      Slider({
        value: this.sliderValue,
        min: 100,
        max: 600,
        step: 25,
        style: SliderStyle.OutSet
      })
        .blockColor('#FFD700')
        .trackColor('#333333')
        .selectedColor('#FFD700')
        .trackThickness(6)
        .blockSize({ width: 20, height: 20 })
        .onChange((value: number) => {
          this.sliderValue = value
          // 实时更新阈值，但不立即保存
          this.longPressThreshold = value
        })
        .margin({ bottom: 20 })

      // 确定按钮
      Button($r('app.string.confirm'))
        .width('100%')
        .height(48)
        .backgroundColor('#FFD700')
        .borderRadius(8)
        .fontColor(Color.Black)
        .fontWeight(FontWeight.Bold)
        .onClick(async () => {
          // 保存长按时间设置
          await this.saveLongPressThresholdPreference(this.sliderValue)
          // 开始退出动画
          animateTo({
            duration: 150,
            curve: Curve.EaseIn
          }, () => {
            this.settingsDialogScale = 0.8
            this.settingsDialogOpacity = 0
          })
          // 动画完成后关闭对话框
          setTimeout(() => {
            this.showSettingsDialog = false
          }, 150)
        })
    }
    .padding(20)
      .backgroundColor('#2A2A2A')
      .borderRadius(12)
      .width('90%')
      .constraintSize({ maxWidth: 400 })
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

      // 按钮模式选择对话框
      if (this.showButtonModeDialog) {
        Stack() {
          // 半透明背景
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.5)')
            .onClick(() => {
              // 不允许点击背景关闭，用户必须选择
            })

          // 对话框内容 - 使用Column居中
          Column() {
            this.ButtonModeDialog()
          }
          .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
          .height('100%')
      }

      // 设置对话框
      if (this.showSettingsDialog) {
        Stack() {
          // 半透明背景
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.5)')

          // 对话框内容 - 使用Column居中
          Column() {
            this.SettingsDialog()
          }
          .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .scale({ x: this.settingsDialogScale, y: this.settingsDialogScale })
            .opacity(this.settingsDialogOpacity)
        }
        .width('100%')
          .height('100%')
      }
    }
  }
}
