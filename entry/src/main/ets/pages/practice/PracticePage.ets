import { router, promptAction } from '@kit.ArkUI'
import { audioService } from '../../services/AudioService'
import { MorseCode, MorseCodeData } from '../../models/MorseCode'
import { FavoritesStore } from '../../store/FavoritesStore'
import { PracticeViewModel } from '../../viewmodel/PracticeViewModel'
import { PracticeProgressStore } from '../../store/PracticeProgressStore'
import preferences from '@ohos.data.preferences'
import { vibratorService } from '../../services/VibratorService'

// 练习模式类型
type PracticeMode = 'text_to_code' | 'code_to_text' | 'sound_to_text'
// 类别类型
type Category = 'letters' | 'numbers' | 'punctuation'

@Entry
@Component
export struct PracticePage {
  @State mode: PracticeMode = 'text_to_code'
  @State category: Category = 'letters'
  @State soundEnabled: boolean = true
  @State favoritesStore: FavoritesStore = FavoritesStore.getInstance()
  @State practiceProgressStore: PracticeProgressStore = PracticeProgressStore.getInstance()

  // 通用状态（使用ViewModel）
  @State vm: PracticeViewModel = new PracticeViewModel()
  @State circleScale: number = 1.0
  @State displayCharacter: string = ''
  @State progressVisual: number = 0
  @State useSingleButton: boolean = false
  @State showButtonModeDialog: boolean = false
  @State selectedButtonMode: boolean = false
  @State showSettingsDialog: boolean = false
  @State sliderValue: number = 300
  @State settingsDialogScale: number = 0.8
  @State settingsDialogOpacity: number = 0

  // 代码转文本和声音转文本模式的候选字符
  @State candidateChars: string[] = []
  @State selectedChar: string = ''
  @State isPlayingSound: boolean = false
  @State playProgress: number = 0
  @State isMixedMode: boolean = false
  @State showHintText: boolean = false
  @State hintTextColor: string = ''
  @State hintTextOpacity: number = 0
  @State showCandidateGrid: boolean = true

  private preferencesStore: preferences.Preferences | null = null
  private progressTimer: number | null = null
  private targetProgress: number = 0
  private lastCharacterChangeId: number = -1
  private animationTimer: number | null = null
  private readonly pillRadius: number = 20
  private pressStartTime: number = 0
  private longPressThreshold: number = 300
  private longPressTimer: number | null = null
  private isCustomCharacterSet: boolean = false
  private allAvailableCodes: MorseCode[] = [] // 存储所有可用字符
  private playProgressTimer: number | null = null

  async aboutToAppear(): Promise<void> {
    // 获取路由参数
    try {
      const params: Record<string, Object> = (router.getParams?.() as Record<string, Object>) ?? {}
      this.mode = (params['mode'] as PracticeMode) || 'text_to_code'
      this.isMixedMode = (params['mixedMode'] as boolean) || false

      // 初始化练习进度store
      const context = getContext(this)
      await this.practiceProgressStore.init(context)

      // 初始化收藏和错题store
      await this.favoritesStore.init(context)

      // 初始化偏好设置
      await this.initPreferences()
      await this.loadButtonModePreference()
      await this.loadLongPressThresholdPreference()
      await this.loadVibrationPreference()

      this.vm.setAutoCheckDelay(this.useSingleButton ? 1500 : 600)

      // 如果是收藏或错题本模式，使用指定的字符列表
      const characters = (params['characters'] as string[]) || []
      if (characters && Array.isArray(characters) && characters.length > 0) {
        this.isCustomCharacterSet = true
        const allCodes = [...MorseCodeData.englishAlphabet, ...MorseCodeData.numbers, ...MorseCodeData.punctuation]
        this.allAvailableCodes = allCodes.filter(code => characters.includes(code.character))
      } else {
        this.isCustomCharacterSet = false
        this.allAvailableCodes = [
          ...MorseCodeData.englishAlphabet,
          ...MorseCodeData.numbers,
          ...MorseCodeData.punctuation
        ]
      }

      // 根据当前类别过滤字符
      this.updateCurrentCategory()

      this.displayCharacter = this.vm.getCurrentCharacter()
      this.lastCharacterChangeId = this.vm.getCharacterChangeId()

      // 为代码转文本和声音转文本模式生成候选字符
      if (this.mode === 'code_to_text' || this.mode === 'sound_to_text') {
        this.generateCandidates()
        this.showCandidateGrid = true
      }

      // 如果是声音模式，延迟播放确保字符已正确加载
      if (this.mode === 'sound_to_text') {
        setTimeout(() => {
          console.log(`[PracticePage] Initial play for character: ${this.vm.getCurrentCharacter()}, morse: ${this.vm.getCurrentMorse()}`)
          this.playMorse()
        }, 800)
      }

      this.startAnimationCheck()
    } catch (error) {
      console.error('[PracticePage] Error in aboutToAppear:', error)
    }
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
    if (this.playProgressTimer) {
      clearInterval(this.playProgressTimer)
      this.playProgressTimer = null
    }
  }

  // 初始化偏好设置
  private async initPreferences(): Promise<void> {
    try {
      const context = getContext(this)
      this.preferencesStore = await preferences.getPreferences(context, 'practice_preferences')
    } catch (error) {
      console.error('[PracticePage] Failed to initialize preferences:', error)
    }
  }

  // 加载按钮模式偏好
  private async loadButtonModePreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        const hasSetPreference = await this.preferencesStore.get('has_set_button_mode', false) as boolean
        if (hasSetPreference) {
          this.useSingleButton = await this.preferencesStore.get('use_single_button', false) as boolean
        } else {
          this.selectedButtonMode = false
          this.showButtonModeDialog = this.mode === 'text_to_code' // 只在文本→代码模式显示
        }
      }
    } catch (error) {
      console.error('[PracticePage] Failed to load button mode preference:', error)
    }
  }

  // 保存按钮模式偏好
  private async saveButtonModePreference(useSingle: boolean): Promise<void> {
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.put('use_single_button', useSingle)
        await this.preferencesStore.put('has_set_button_mode', true)
        await this.preferencesStore.flush()
        this.useSingleButton = useSingle
        this.vm.setAutoCheckDelay(this.useSingleButton ? 1500 : 600)

        if (this.animationTimer) {
          clearInterval(this.animationTimer)
        }
        this.startAnimationCheck()
      }
    } catch (error) {
      console.error('[PracticePage] Failed to save button mode preference:', error)
    }
  }

  // 加载长按时间偏好
  private async loadLongPressThresholdPreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        this.longPressThreshold = await this.preferencesStore.get('long_press_threshold', 300) as number
      }
    } catch (error) {
      console.error('[PracticePage] Failed to load long press threshold:', error)
    }
  }

  // 保存长按时间偏好
  private async saveLongPressThresholdPreference(threshold: number): Promise<void> {
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.put('long_press_threshold', threshold)
        await this.preferencesStore.flush()
        this.longPressThreshold = threshold
      }
    } catch (error) {
      console.error('[PracticePage] Failed to save long press threshold:', error)
    }
  }

  // 加载振动偏好设置
  private async loadVibrationPreference(): Promise<void> {
    try {
      if (this.preferencesStore) {
        const vibrationEnabled = await this.preferencesStore.get('vibration_enabled', true) as boolean
        vibratorService.setEnabled(vibrationEnabled)
        console.log(`[PracticePage] ===== Loaded vibration preference: ${vibrationEnabled} =====`)
        console.log(`[PracticePage] ===== Vibrator service enabled: ${vibratorService.isVibrationEnabled()} =====`)
      } else {
        console.warn('[PracticePage] Preferences store not initialized, using default vibration: true')
        vibratorService.setEnabled(true)
      }
    } catch (error) {
      console.error('[PracticePage] Failed to load vibration preference:', error)
      // 如果加载失败，确保振动默认开启
      vibratorService.setEnabled(true)
    }
  }

  // 更新当前类别
  private updateCurrentCategory(): void {
    let filtered: MorseCode[] = []

    if (this.category === 'letters') {
      filtered = this.allAvailableCodes.filter(code =>
        MorseCodeData.englishAlphabet.some(c => c.character === code.character))
    } else if (this.category === 'numbers') {
      filtered = this.allAvailableCodes.filter(code =>
        MorseCodeData.numbers.some(c => c.character === code.character))
    } else if (this.category === 'punctuation') {
      filtered = this.allAvailableCodes.filter(code =>
        MorseCodeData.punctuation.some(c => c.character === code.character))
    }

    // 如果当前类别没有字符
    if (filtered.length === 0) {
      console.log(`[PracticePage] No characters in category ${this.category}`)
      // 尝试切换到有字符的类别
      if (this.category !== 'letters') {
        const letters = this.allAvailableCodes.filter(code =>
          MorseCodeData.englishAlphabet.some(c => c.character === code.character))
        if (letters.length > 0) {
          this.category = 'letters'
          filtered = letters
        }
      }
    }

    // 更新ViewModel的当前代码列表
    if (filtered.length > 0) {
      this.vm.setCurrentCodes(filtered)
      console.log(`[PracticePage] Updated to category ${this.category} with ${filtered.length} characters`)
    }
  }

  // 切换类别
  private switchCategory(category: Category): void {
    console.log(`[PracticePage] Switching from ${this.category} to ${category}`)
    if (this.category === category) return

    this.category = category
    this.updateCurrentCategory()

    // 更新显示字符
    this.displayCharacter = this.vm.getCurrentCharacter()

    if (this.mode === 'code_to_text' || this.mode === 'sound_to_text') {
      // code_to_text 使用更快的过渡
      const transitionDelay = this.mode === 'code_to_text' ? 200 : 400
      const playDelay = this.mode === 'sound_to_text' ? 400 : 0

      // 隐藏网格，然后显示新内容
      this.showCandidateGrid = false
      setTimeout(() => {
        this.generateCandidates()
        this.showCandidateGrid = true

        if (this.mode === 'sound_to_text') {
          setTimeout(() => {
            console.log(`[PracticePage] Playing morse after category switch for: ${this.vm.getCurrentCharacter()}`)
            this.playMorse()
          }, playDelay)
        }
      }, transitionDelay)
    }
  }

  // 生成候选字符
  private generateCandidates(): void {
    const currentChar = this.vm.getCurrentCharacter()
    const allCodes = this.vm.getCurrentCodes()
    const candidates: string[] = [currentChar]
    const availableChars = allCodes.filter(code => code.character !== currentChar)

    const count = Math.min(5, availableChars.length)
    for (let i = 0; i < count; i++) {
      const randomIndex = Math.floor(Math.random() * availableChars.length)
      candidates.push(availableChars[randomIndex].character)
      availableChars.splice(randomIndex, 1)
    }

    this.candidateChars = candidates.sort(() => Math.random() - 0.5)
  }

  // 播放摩斯码
  private async playMorse(): Promise<void> {
    if (!this.soundEnabled) return

    // 先清除之前可能存在的定时器
    if (this.playProgressTimer) {
      clearInterval(this.playProgressTimer)
      this.playProgressTimer = null
    }

    this.isPlayingSound = true
    this.playProgress = 0

    const morse = this.vm.getCurrentMorse().trim() // 去除空格
    console.log(`[PracticePage] Playing morse: "${morse}" for character: ${this.vm.getCurrentCharacter()}`)

    if (!morse || morse.length === 0) {
      console.error('[PracticePage] Empty morse code, skipping playback')
      this.isPlayingSound = false
      return
    }

    const codes = morse.split('')

    // 计算实际总时长：
    // dit: playDit内部100ms + 外部delay 100ms = 200ms
    // dah: playDah内部300ms + 外部delay 100ms = 400ms
    // 符号间隔: 200ms
    let totalDuration = 0
    for (let i = 0; i < codes.length; i++) {
      if (codes[i] === '.') {
        totalDuration += 200 // dit 总时长
      } else if (codes[i] === '-') {
        totalDuration += 400 // dah 总时长
      }
      // 符号间隔（最后一个符号后不需要间隔）
      if (i < codes.length - 1) {
        totalDuration += 200
      }
    }

    console.log(`[PracticePage] Total duration calculated: ${totalDuration}ms`)
    const startTime = Date.now()

    // 启动平滑进度更新定时器
    this.playProgressTimer = setInterval(() => {
      const elapsed = Date.now() - startTime
      this.playProgress = Math.min(elapsed / totalDuration, 1)
    }, 16) // 60fps更新

    for (let i = 0; i < codes.length; i++) {
      const code = codes[i]
      if (code === '.') {
        // 声音播放时同步振动：点短振
        void vibratorService.vibrateDit()
        await audioService.playDit()
        await this.delay(100)
      } else if (code === '-') {
        // 声音播放时同步振动：划长振
        void vibratorService.vibrateDah()
        await audioService.playDah()
        await this.delay(100)
      } else {
        // 跳过非摩斯码字符
        console.warn(`[PracticePage] Skipping invalid character in morse: "${code}"`)
        continue
      }

      // 符号间隔
      if (i < codes.length - 1) {
        await this.delay(200)
      }
    }

    // 清除定时器
    if (this.playProgressTimer) {
      clearInterval(this.playProgressTimer)
      this.playProgressTimer = null
    }

    this.isPlayingSound = false
    this.playProgress = 0
    console.log(`[PracticePage] Playback finished, actual duration: ${Date.now() - startTime}ms`)
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  // 选择字符（代码/声音→文本模式）
  private selectChar(char: string): void {
    this.selectedChar = char
    const isCorrect = char === this.vm.getCurrentCharacter()

    // 振动反馈
    if (isCorrect) {
      void vibratorService.vibrateSuccess()
    } else {
      void vibratorService.vibrateError()
    }

    // 记录到练习进度
    if (isCorrect) {
      this.practiceProgressStore.recordCorrect(this.vm.getCurrentCharacter())
    } else {
      this.practiceProgressStore.recordIncorrect(this.vm.getCurrentCharacter())
      void this.favoritesStore.addToMistakes(this.vm.getCurrentCharacter()).catch((error: Error) => {
        console.error('[PracticePage] Failed to add to mistakes:', error)
      })
    }

    // 如果答错，显示提示但不自动进入下一题
    if (!isCorrect) {
      // 显示"再试一次"提示
      try {
        promptAction.showToast({
          message: $r('app.string.try_again'),
          duration: 2000,
          bottom: '45%'
        })
      } catch (error) {
        console.error('[PracticePage] Failed to show toast:', error)
      }

      // 在声音转文本模式显示提示文字1500ms
      if (this.mode === 'sound_to_text') {
        this.hintTextColor = '#FF0000'
        this.showHintText = true

        // 淡入动画
        animateTo({
          duration: 200,
          curve: Curve.EaseOut
        }, () => {
          this.hintTextOpacity = 1
        })

        // 1500ms后淡出隐藏
        setTimeout(() => {
          animateTo({
            duration: 200,
            curve: Curve.EaseIn
          }, () => {
            this.hintTextOpacity = 0
          })
          // 动画结束后隐藏元素
          setTimeout(() => {
            this.showHintText = false
          }, 200)
        }, 1500)
      }

      // 清除选中状态，让用户可以继续选择（code_to_text 更快）
      const clearDelay = this.mode === 'code_to_text' ? 500 : 500
      setTimeout(() => {
        this.selectedChar = ''
      }, clearDelay)

      return // 答错不进入下一题
    }

    // 答对了，执行自动进入下一题的逻辑
    // code_to_text 模式使用更快的过渡
    const hideDelay = this.mode === 'code_to_text' ? 500 : 500
    const showDelay = this.mode === 'code_to_text' ? 1000 : 1800

    // 逻辑1: 在声音转文本模式显示提示文字1500ms（同时开始）
    if (this.mode === 'sound_to_text') {
      this.hintTextColor = '#00FF00'
      this.showHintText = true

      // 淡入动画
      animateTo({
        duration: 200,
        curve: Curve.EaseOut
      }, () => {
        this.hintTextOpacity = 1
      })

      // 1500ms后淡出隐藏
      setTimeout(() => {
        animateTo({
          duration: 200,
          curve: Curve.EaseIn
        }, () => {
          this.hintTextOpacity = 0
        })
        // 动画结束后隐藏元素
        setTimeout(() => {
          this.showHintText = false
        }, 200)
      }, 1500)
    }

    // 逻辑2: 隐藏选择网格（code_to_text=300ms, sound_to_text=500ms）
    setTimeout(() => {
      this.showCandidateGrid = false
      this.selectedChar = ''

      // 如果是混合模式，随机切换模式
      if (this.isMixedMode) {
        this.switchToRandomMode()
      }
    }, hideDelay)

    // 逻辑3: 更新数据并显示新题目（code_to_text=600ms, sound_to_text=1800ms）
    setTimeout(() => {
      this.vm.generateNewCharacter()

      if (this.mode === 'code_to_text' || this.mode === 'sound_to_text') {
        this.generateCandidates()
      }

      this.showCandidateGrid = true
    }, showDelay)
  }

  // 切换到随机模式（混合模式使用）
  private switchToRandomMode(): void {
    const modes: PracticeMode[] = ['text_to_code', 'code_to_text', 'sound_to_text']
    const currentIndex = modes.indexOf(this.mode)
    const availableModes = modes.filter((_, index) => index !== currentIndex)
    const randomIndex = Math.floor(Math.random() * availableModes.length)
    this.mode = availableModes[randomIndex]
  }

  // 单按钮模式处理
  private handleSingleButtonPress(): void {
    this.pressStartTime = Date.now()
    this.longPressTimer = setTimeout(() => {
      this.handleLongPress()
    }, this.longPressThreshold)
  }

  private async handleSingleButtonRelease(): Promise<void> {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer)
      this.longPressTimer = null
    }
    const pressDuration = Date.now() - this.pressStartTime
    if (pressDuration < this.longPressThreshold) {
      this.vm.addDot()
      if (this.soundEnabled) {
        await audioService.playDit()
      }
    }
  }

  private async handleLongPress(): Promise<void> {
    this.vm.addDash()
    if (this.soundEnabled) {
      await audioService.playDah()
    }
  }

  // 动画检查
  private startAnimationCheck(): void {
    const checkInterval = this.useSingleButton ? 200 : 100
    this.animationTimer = setInterval(() => {
      const currentChangeId = this.vm.getCharacterChangeId()
      if (currentChangeId !== this.lastCharacterChangeId) {
        this.lastCharacterChangeId = currentChangeId

        // 如果是混合模式且答对了题，切换模式
        if (this.isMixedMode && this.mode === 'text_to_code' && this.vm.getIsCorrect()) {
          this.switchToRandomMode()
        }

        // 重置提示文字状态
        this.showHintText = false
        this.hintTextOpacity = 0

        animateTo({
          duration: 50,
          curve: Curve.EaseIn
        }, () => {
          this.circleScale = 0.0
        })

        setTimeout(() => {
          this.displayCharacter = this.vm.getCurrentCharacter()
          this.setProgressInstant(0)

          // 更新候选字符
          if (this.mode === 'code_to_text' || this.mode === 'sound_to_text') {
            this.generateCandidates()
          }

          // 如果切换到声音模式，延迟播放确保状态稳定
          if (this.mode === 'sound_to_text') {
            setTimeout(() => {
              console.log(`[PracticePage] Playing morse after mode switch to sound_to_text for: ${this.vm.getCurrentCharacter()}`)
              this.playMorse()
            }, 500)
          }

          animateTo({
            duration: 100,
            curve: Curve.EaseInOut
          }, () => {
            this.circleScale = 1.0
          })
        }, 60)
      }

      const p = Math.max(0, Math.min(this.vm.getProgress(), 1))
      if (Math.abs(p - this.targetProgress) > 1e-6) {
        this.targetProgress = p
        this.animateProgressTo(this.targetProgress, 150)
      }
    }, checkInterval)
  }

  private getCircumference(): number {
    return 2 * Math.PI * 100
  }

  private getProgressVisualLength(): number {
    return this.getCircumference() * Math.max(0, Math.min(this.progressVisual, 1))
  }

  private setProgressInstant(value: number) {
    if (this.progressTimer) {
      clearInterval(this.progressTimer)
      this.progressTimer = null
    }
    this.progressVisual = Math.max(0, Math.min(value, 1))
    this.targetProgress = this.progressVisual
  }

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
        .borderRadius(24)
        .onClick(() => {
          router.back()
        })

      // 类别tabs放在中间
      Row() {
        Text($r('app.string.category_letters'))
          .fontSize(14)
          .fontColor(this.category === 'letters' ? '#FFD700' : '#999999')
          .fontWeight(this.category === 'letters' ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .onClick(() => this.switchCategory('letters'))

        Text('|')
          .fontSize(14)
          .fontColor('#333333')
          .margin({ left: 2, right: 2 })

        Text($r('app.string.category_numbers'))
          .fontSize(14)
          .fontColor(this.category === 'numbers' ? '#FFD700' : '#999999')
          .fontWeight(this.category === 'numbers' ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .onClick(() => this.switchCategory('numbers'))

        Text('|')
          .fontSize(14)
          .fontColor('#333333')
          .margin({ left: 2, right: 2 })

        Text($r('app.string.category_punctuation'))
          .fontSize(14)
          .fontColor(this.category === 'punctuation' ? '#FFD700' : '#999999')
          .fontWeight(this.category === 'punctuation' ? FontWeight.Bold : FontWeight.Normal)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .onClick(() => this.switchCategory('punctuation'))
      }
      .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

      // 右侧占位空间
      Column().width(48).height(48)
    }
    .height(56)
      .width('100%')
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.Black)
  }

  @Builder
  private ProgressCircle() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.vm.getHasIncorrectAttempt()) {
        Circle({ width: 200, height: 200 })
          .fill(Color.Transparent)
          .strokeWidth(8)
          .stroke('#333333')

        Circle({ width: 200, height: 200 })
          .fill(Color.Transparent)
          .strokeWidth(8)
          .stroke(this.vm.getProgress() >= 1.0 ? Color.Green : '#FFD700')
          .strokeDashArray([this.getProgressVisualLength(), this.getCircumference() - this.getProgressVisualLength()])
          .strokeDashOffset(this.getCircumference() / 4)
          .strokeLineCap(LineCapStyle.Round)
          .opacity(this.progressVisual > 0 ? 1 : 0)
      }

      Column()
        .width(180)
        .height(180)
        .backgroundColor(
          this.vm.getShowResult() && !this.vm.getIsCorrect() ? Color.Red :
            (this.vm.getIsCorrect() ? Color.Green : '#FFD700')
        )
        .borderRadius(90)
        .animation({ duration: 300, curve: Curve.EaseInOut })

      Text(this.displayCharacter)
        .fontSize(72)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
    }
    .width(200)
      .height(200)
      .scale({ x: this.circleScale, y: this.circleScale })
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
      .width(250)
      .backgroundColor('#1A1A1A')
      .borderRadius(this.pillRadius)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.vm.flashHint()
      })
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
    .width(400)
      .height(60)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private ToolButtons() {
    Row() {
      Button() {
        Image($rawfile('ic_star.svg')).width(24).height(24)
          .fillColor(this.vm.getIsFavorite() ? '#FFD700' : Color.White)
      }
      .onClick(() => {
        const currentChar = this.vm.getCurrentCharacter()
        void this.favoritesStore.toggleFavorite(currentChar).then(() => {
          this.vm.toggleFavorite()
        }).catch((error: Error) => {
          console.error('[PracticePage] Failed to toggle favorite:', error)
        })
      })
        .width(48).height(48)
        .backgroundColor(Color.Transparent)
        .borderRadius(24)

      Blank().width(40)

      Button() {
        Image($rawfile(this.soundEnabled ? 'ic_sound_on.svg' : 'ic_sound_off.svg'))
          .width(24)
          .height(24)
      }
      .width(48)
        .height(48)
        .backgroundColor(Color.Transparent)
        .borderRadius(24)
        .onClick(() => {
          this.soundEnabled = !this.soundEnabled
        })

      Blank().width(40)

      Button() {
        Image($rawfile('ic_skip.svg')).width(24).height(24).fillColor(Color.White)
      }
      .onClick(() => this.vm.passCharacter())
        .width(48).height(48)
        .backgroundColor(Color.Transparent)
        .borderRadius(24)
    }
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private BottomKeys() {
    if (this.useSingleButton) {
      Row() {
        Column().width(48).height(48)

        Button() {
          Text('·')
            .fontSize(24)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold)
        }
        .height(120)
          .width(120)
          .backgroundColor('#FFD700')
          .borderRadius(60)
          .onTouch((event) => {
            if (event.type === TouchType.Down) {
              this.handleSingleButtonPress()
            } else if (event.type === TouchType.Up) {
              this.handleSingleButtonRelease()
            }
          })

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
            this.settingsDialogScale = 0.8
            this.settingsDialogOpacity = 0
            this.showSettingsDialog = true
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
      Row() {
        Button() {
          Circle({ width: 20, height: 20 })
            .fill('#FFD700')
        }
        .height(80)
          .backgroundColor('#1A1A1A')
          .borderRadius(this.pillRadius)
          .border({ width: 1, color: '#333333' })
          .onClick(async () => {
            this.vm.addDot() // addDot 内部已包含振动反馈
            if (this.soundEnabled) {
              await audioService.playDit()
            }
          })
          .layoutWeight(1)

        Blank().width(20)

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
  private TextToCodeMode() {
    Column() {
      Blank().height(12)

      Column() {
        this.ProgressCircle()
        Blank().height(40)
        this.MorseDisplay()
        Blank().height(12)
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
  }

  @Builder
  private CodeToTextMode() {
    Column() {
      Blank().height(40)

      // 显示摩斯码在圆角矩形框中
      Column() {
        if (this.showCandidateGrid) {
          Text(this.vm.getCurrentMorse().split('.').join(' · ').split('-').join(' - '))
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Black)
            .fontFamily('monospace')
            .textAlign(TextAlign.Center)
            .padding({ left: 30, right: 30, top: 20, bottom: 20 })
        } else {
          Text('')
            .fontSize(28)
            .padding({ left: 30, right: 30, top: 20, bottom: 20 })
        }
      }
      .width('100%')
        .constraintSize({ minHeight: 100 })
        .backgroundColor('#FFD700')
        .borderRadius(16)
        .justifyContent(FlexAlign.Center)

      Blank().layoutWeight(1)

      // 候选字符网格
      if (this.showCandidateGrid) {
        Grid() {
          ForEach(this.candidateChars, (char: string) => {
            GridItem() {
              Column() {
                Text(char)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(
                    this.selectedChar === char && char === this.vm.getCurrentCharacter() ? Color.White :
                      (this.selectedChar === char ? Color.White :
                        (this.selectedChar && char === this.vm.getCurrentCharacter() ? Color.White : Color.White))
                  )
                  .textAlign(TextAlign.Center)
              }
            .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
                .backgroundColor(
                  this.selectedChar === char && char === this.vm.getCurrentCharacter() ? Color.Green :
                    (this.selectedChar === char ? Color.Red :
                      (this.selectedChar && char === this.vm.getCurrentCharacter() ? Color.Green : '#1A1A1A'))
                )
                .borderRadius(12)
                .border({ width: 1, color: '#333333' })
                .onClick(() => {
                  if (!this.selectedChar) {
                    this.selectChar(char)
                  }
                })
            }
          })
        }
      .columnsTemplate('1fr 1fr 1fr')
          .rowsTemplate('1fr 1fr')
          .columnsGap(12)
          .rowsGap(12)
          .width('100%')
          .height(280)
          .margin({ bottom: 20 })
      }
    }
    .width('100%')
      .constraintSize({ maxWidth: 480 })
      .padding({ left: 20, right: 20 })
      .layoutWeight(1)
  }

  @Builder
  private SoundToTextMode() {
    Column() {
      Blank().height(40)

      // 播放按钮在圆圈中，带播放进度环
      Column() {
        Stack({ alignContent: Alignment.Center }) {
          if (this.isPlayingSound) {
            Circle({ width: 200, height: 200 })
              .fill(Color.Transparent)
              .strokeWidth(8)
              .stroke('#333333')

            Circle({ width: 200, height: 200 })
              .fill(Color.Transparent)
              .strokeWidth(8)
              .stroke('#FFD700')
              .strokeDashArray([2 * Math.PI * 100 * this.playProgress, 2 * Math.PI * 100 * (1 - this.playProgress)])
              .strokeDashOffset(2 * Math.PI * 100 / 4)
              .strokeLineCap(LineCapStyle.Round)
          }

          Column()
            .width(180)
            .height(180)
            .backgroundColor('#FFD700')
            .borderRadius(90)

          Button() {
            Image($rawfile('ic_play.svg'))
              .width(72)
              .height(72)
              .fillColor(Color.Black)
          }
          .width(140)
            .height(140)
            .backgroundColor(Color.Transparent)
            .borderRadius(70)
            .onClick(() => this.playMorse())
        }
        .width(200)
          .height(200)

        // 提示文字
        if (this.showHintText) {
          Text(this.vm.getCurrentMorse().split('.').join(' · ').split('-').join(' - '))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.hintTextColor)
            .fontFamily('monospace')
            .textAlign(TextAlign.Center)
            .margin({ top: 12 })
            .opacity(this.hintTextOpacity)
        } else {
          Text(' ')
            .fontSize(20)
            .margin({ top: 12 })
        }
      }
      .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

      Blank().layoutWeight(1)

      // 候选字符网格
      if (this.showCandidateGrid) {
        Grid() {
          ForEach(this.candidateChars, (char: string) => {
            GridItem() {
              Column() {
                Text(char)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(
                    this.selectedChar === char && char === this.vm.getCurrentCharacter() ? Color.White :
                      (this.selectedChar === char ? Color.White :
                        (this.selectedChar && char === this.vm.getCurrentCharacter() ? Color.White : Color.White))
                  )
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
                .backgroundColor(
                  this.selectedChar === char && char === this.vm.getCurrentCharacter() ? Color.Green :
                    (this.selectedChar === char ? Color.Red :
                      (this.selectedChar && char === this.vm.getCurrentCharacter() ? Color.Green : '#1A1A1A'))
                )
                .borderRadius(12)
                .border({ width: 1, color: '#333333' })
                .onClick(() => {
                  if (!this.selectedChar) {
                    this.selectChar(char)
                  }
                })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr')
          .rowsTemplate('1fr 1fr')
          .columnsGap(12)
          .rowsGap(12)
          .width('100%')
          .height(280)
          .margin({ bottom: 20 })
      }
    }
    .width('100%')
      .constraintSize({ maxWidth: 480 })
      .padding({ left: 20, right: 20 })
      .layoutWeight(1)
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

        Text('可在设置中更改此选项')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 20 })

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
            animateTo({
              duration: 150,
              curve: Curve.EaseIn
            }, () => {
              this.settingsDialogScale = 0.8
              this.settingsDialogOpacity = 0
            })
            setTimeout(() => {
              this.showSettingsDialog = false
            }, 150)
          })
      }
      .width('100%')
        .margin({ bottom: 20 })

      Row() {
        Column() {
          Text('长按时间')
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
          this.longPressThreshold = value
        })
        .margin({ bottom: 20 })

      Button($r('app.string.confirm'))
        .width('100%')
        .height(48)
        .backgroundColor('#FFD700')
        .borderRadius(8)
        .fontColor(Color.Black)
        .fontWeight(FontWeight.Bold)
        .onClick(async () => {
          await this.saveLongPressThresholdPreference(this.sliderValue)
          animateTo({
            duration: 150,
            curve: Curve.EaseIn
          }, () => {
            this.settingsDialogScale = 0.8
            this.settingsDialogOpacity = 0
          })
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

        if (this.mode === 'text_to_code') {
          this.TextToCodeMode()
        } else if (this.mode === 'code_to_text') {
          this.CodeToTextMode()
        } else {
          this.SoundToTextMode()
        }
      }
      .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      if (this.showButtonModeDialog) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.5)')

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

      if (this.showSettingsDialog) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.5)')

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
