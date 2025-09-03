import { MorseCode, MorseCodeData } from '../models/MorseCode'
import { router } from '@kit.ArkUI'
import { LearnViewModel } from '../viewmodel/LearnViewModel'
import { LessonData } from '../data/LessonData'
import { promptAction } from '@kit.ArkUI'
import window from '@ohos.window'

@Entry
@Component
export struct FullscreenLessonPage {
  // 课程数据
  private codes: MorseCode[] = []
  private lessonId: string = ''
  private title: string = ''
  
  // 状态管理
  @State currentIndex: number = 0
  @State userInput: string = ''
  @State showResult: boolean = false
  @State isCorrect: boolean = false
  @State showMorseCode: boolean = true
  @State completionCount: Map<number, number> = new Map()
  @State practiceCount: Map<number, number> = new Map() // 每个字母的练习次数
  private readonly REQUIRED_PRACTICE_COUNT: number = 5 // 每个字母需要练习5次
  @State hintRevealed: Map<number, boolean> = new Map()
  // 显示用的可动画进度（0~1），用于平滑填充圆环
  @State progressVisual: number = 0
  // 完成后才切换为绿色（外环与内圆）
  @State showCompletedColor: boolean = false
  // 自动校验的防抖计时器
  private autoCheckTimer: number | null = null
  // 进度补间计时器
  private progressTimer: number | null = null
  // 自定义完成对话框控制器
  private completionDialogController: CustomDialogController = new CustomDialogController({
    builder: this.CompletionDialog(),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: false
  })
  
  // ViewModel
  private learnViewModel: LearnViewModel = new LearnViewModel()

  aboutToAppear() {
    // Set status bar color
    window.getLastWindow(getContext(this)).then((windowClass) => {
      windowClass.setWindowSystemBarProperties({
        statusBarColor: '#000000',
        statusBarContentColor: '#FFFFFF'
      })
    })

    // 从路由参数获取课程数据
    const params = router.getParams() as Record<string, Object>
    this.lessonId = params['lessonId'] as string || ''
    this.title = params['title'] as string || '练习课程'
    
    // 根据lessonId设置课程数据
    this.setupLessonData()
    
    // 初始化ViewModel
    this.learnViewModel.init()
  }

  aboutToDisappear() {
    // 清理未触发的自动校验
    if (this.autoCheckTimer !== null) {
      clearTimeout(this.autoCheckTimer)
      this.autoCheckTimer = null
    }
    // 清理进度动画计时器
    if (this.progressTimer !== null) {
      clearInterval(this.progressTimer)
      this.progressTimer = null
    }
  }

  private setupLessonData() {
    // 根据lessonId设置不同的课程数据，按课程顺序显示指定内容
    if (this.lessonId.includes('alpha_')) {
      // 字母课程：根据课程编号显示特定字母组合
      const lessonIndex = parseInt(this.lessonId.split('_')[1]) || 0
      const alphabetGroups = LessonData.getAlphabetGroups()
      if (lessonIndex < alphabetGroups.length) {
        const targetLetters = alphabetGroups[lessonIndex]
        this.codes = MorseCodeData.englishAlphabet.filter(code => 
          targetLetters.includes(code.character)
        )
      } else {
        this.codes = MorseCodeData.englishAlphabet.slice(0, 3) // 默认ABC
      }
    } else if (this.lessonId.includes('num_')) {
      // 数字课程：根据课程编号显示特定数字组合
      const lessonIndex = parseInt(this.lessonId.split('_')[1]) || 0
      const numberGroups = LessonData.getNumberGroups()
      if (lessonIndex < numberGroups.length) {
        const targetNumbers = numberGroups[lessonIndex]
        this.codes = MorseCodeData.numbers.filter(code => 
          targetNumbers.includes(code.character)
        )
      } else {
        this.codes = MorseCodeData.numbers.slice(0, 3) // 默认123
      }
    } else if (this.lessonId.includes('pun_')) {
      // 标点课程：根据课程编号显示特定标点组合
      const lessonIndex = parseInt(this.lessonId.split('_')[1]) || 0
      const punctuationGroups = LessonData.getPunctuationGroups()
      if (lessonIndex < punctuationGroups.length) {
        const targetPunctuation = punctuationGroups[lessonIndex]
        this.codes = MorseCodeData.punctuation.filter(code => 
          targetPunctuation.includes(code.character)
        )
      } else {
        this.codes = MorseCodeData.punctuation.slice(0, 3) // 默认前3个
      }
    } else if (this.lessonId.includes('word_')) {
      // 单词课程：根据课程编号显示特定长度单词
      const lessonIndex = parseInt(this.lessonId.split('_')[1]) || 0
      const wordGroups = LessonData.getWordGroups()
      if (lessonIndex < wordGroups.length) {
        const targetWords = wordGroups[lessonIndex]
        // 将单词转换为MorseCode对象
        this.codes = targetWords.map(word => new MorseCode(word, '', ''))
      } else {
        this.codes = [new MorseCode('THE', '', ''), new MorseCode('AND', '', ''), new MorseCode('FOR', '', '')]
      }
    } else {
      // 默认显示前3个字母
      this.codes = MorseCodeData.englishAlphabet.slice(0, 3)
    }
  }

  private addDot(): void {
    this.userInput += '.'
    this.showResult = false
    this.startAutoCheck()
  }

  private addDash(): void {
    this.userInput += '-'
    this.showResult = false
    this.startAutoCheck()
  }

  private clearInput(): void {
    this.userInput = ''
    this.showResult = false
    this.isCorrect = false
    // 取消未触发的自动校验，避免清空后立即校验
    if (this.autoCheckTimer !== null) {
      clearTimeout(this.autoCheckTimer)
      this.autoCheckTimer = null
    }
  }

  private startAutoCheck(): void {
    // 防抖：在用户输入停止600ms后自动校验
    if (this.autoCheckTimer !== null) {
      clearTimeout(this.autoCheckTimer)
      this.autoCheckTimer = null
    }
    this.autoCheckTimer = setTimeout(() => {
      this.autoCheckTimer = null
      this.checkAnswer()
    }, 600)
  }

  private shouldShowHint(index: number): boolean {
    const isReviewLesson = this.codes.length > 10
    if (isReviewLesson) {
      return this.hintRevealed.get(index) || false
    } else {
      return this.showMorseCode
    }
  }

  private checkAnswer(): void {
    const currentCode = this.codes[this.currentIndex]
    const isCorrect = this.userInput === currentCode.morse

    this.isCorrect = isCorrect
    this.showResult = true

    if (isCorrect) {
      // 增加练习次数
      const currentPracticeCount = this.practiceCount.get(this.currentIndex) || 0
      const newCount = currentPracticeCount + 1
      this.practiceCount.set(this.currentIndex, newCount)
      // 动画过渡到新的进度（每次 +1/5）
      const targetProgress = Math.min(newCount / this.REQUIRED_PRACTICE_COUNT, 1)
      // 未完成前，保持黄色；完成后在动画结束时切换为绿色
      if (newCount >= this.REQUIRED_PRACTICE_COUNT) {
        this.animateProgressTo(targetProgress, 320, () => {
          this.showCompletedColor = true
        })
      } else {
        this.showCompletedColor = false
        this.animateProgressTo(targetProgress, 320)
      }

      // 检查是否完成5次练习
      if (this.practiceCount.get(this.currentIndex)! >= this.REQUIRED_PRACTICE_COUNT) {
        // 标记为完成
        this.completionCount.set(this.currentIndex, 1)
        setTimeout(() => {
          this.moveToNext()
        }, 1000)
      } else {
        // 继续当前字母，清空输入
        setTimeout(() => {
          this.clearInput()
        }, 1000)
      }
    } else {
      // 错误时显示系统toast
      promptAction.showToast({
        message: '再试一次',
        duration: 1500
      })
      setTimeout(() => {
        this.clearInput()
      }, 1500)
    }
  }

  private moveToNext(): void {
    if (this.currentIndex < this.codes.length - 1) {
      this.currentIndex++
      // 切换到下一个字母时，重置可视进度到该字母的当前累计进度（通常为0）
      const nextCount = this.practiceCount.get(this.currentIndex) || 0
      this.progressVisual = Math.min(nextCount / this.REQUIRED_PRACTICE_COUNT, 1)
      this.showCompletedColor = false
      this.clearInput()
    } else {
      // 所有字母都完成了
      this.showCompletionDialog()
    }
  }

  private async markLessonCompleted(): Promise<void> {
    if (this.lessonId) {
      await this.learnViewModel.markLessonCompleted(this.lessonId)
    }
  }

  private showCompletionDialog(): void {
    // 持久化完成状态并打开自定义对话框
    this.markLessonCompleted()
    this.completionDialogController.open()
  }

  @Builder
  private CompletionDialog() {
    Column() {
      // 顶部成功图标
      Column()
        .width(80)
        .height(80)
        .backgroundColor(Color.Green)
        .borderRadius(40)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .shadow({ radius: 20, color: 'rgba(0, 255, 0, 0.3)', offsetX: 0, offsetY: 8 })
      {
        Text('✓')
          .fontSize(40)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }

      Blank().height(16)

      Text('恭喜完成！')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)

      Blank().height(20)

      // 统计信息
      Row() {
        Column() {
          Text(`${this.codes.length}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text('字母')
            .fontSize(10)
            .fontColor('#B0B0B0')
        }
        .alignItems(HorizontalAlign.Center)

        Blank().width(1).height(40).backgroundColor('#333333')

        Column() {
          Text(`${this.codes.length * this.REQUIRED_PRACTICE_COUNT}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text('练习次数')
            .fontSize(10)
            .fontColor('#B0B0B0')
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#1A1A1A')
      .border({ width: 1, color: '#333333' })
      .borderRadius(12)

      Blank().height(20)

      // 操作按钮
      Row() {
        Button() {
          Text('返回')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .layoutWeight(1)
        .height(44)
        .backgroundColor(Color.Transparent)
        .border({ width: 2, color: Color.White })
        .borderRadius(8)
        .onClick(() => {
          this.completionDialogController.close()
          router.back()
        })

        Blank().width(12)

        Button() {
          Text('再次练习')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .layoutWeight(1)
        .height(44)
        .backgroundColor(Color.Green)
        .borderRadius(8)
        .onClick(() => {
          this.completionDialogController.close()
          this.currentIndex = 0
          this.completionCount.clear()
          this.practiceCount.clear()
          this.progressVisual = 0
          this.showCompletedColor = false
          this.clearInput()
        })
      }
      .width('100%')
    }
    .width('82%')
    .padding(20)
    .backgroundColor('#000000')
    .border({ width: 2, color: Color.Green })
    .borderRadius(16)
    .shadow({ radius: 24, color: 'rgba(0,0,0,0.4)', offsetX: 0, offsetY: 12 })
  }

  @Builder
  private TitleBar() {
    Column() {
      // 顶部导航栏
      Row() {
        Button() {
          Image($rawfile('ic_back.svg')).width(24).height(24).fillColor(Color.White)
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back()
        })

        Row() {
          ForEach(this.codes, (code: MorseCode, index: number) => {
            Text(code.character)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getLetterStatusColor(index))
              .margin({ right: 8 })
          })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        // 提示按钮（仅在非复习课时显示）
        if (this.codes.length <= 10) {
          Button() {
            Image(this.showMorseCode ? $rawfile('ic_eye.svg') : $rawfile('ic_eye_closed.svg'))
              .width(22).height(22).fillColor(Color.White)
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showMorseCode = !this.showMorseCode
          })
        } else {
          // 复习课时显示占位
          Blank().width(48)
        }
      }
      .height(52)
      .padding({ left: 16, right: 16 })


    }
    .width('100%')
    .backgroundColor(Color.Black)
  }

  @Builder
  private ProgressCircle() {
    Stack({ alignContent: Alignment.Center }) {
      // 背景圆圈
      Circle({ width: 220, height: 220 })
        .fill(Color.Transparent)
        .strokeWidth(8)
        .stroke('#333333')
      
      // 进度圆圈（起点调整到顶部中心：偏移四分之一周长）
      Circle({ width: 220, height: 220 })
        .fill(Color.Transparent)
        .strokeWidth(8)
        .stroke(this.getProgressColor())
        // 使用 [已填充, 剩余] 的 dash pattern，绑定到可动画进度progressVisual
        .strokeDashArray([this.getProgressVisualLength(), this.getCircumference() - this.getProgressVisualLength()])
        .strokeDashOffset(this.getCircumference() / 4)
        .strokeLineCap(LineCapStyle.Round)
        .opacity(this.progressVisual > 0 ? 1 : 0) // 进度为0时不显示
      
      // 内部圆圈
      Circle({ width: 200, height: 200 })
        .fill(this.getProgressColor())
        .animation({
          // 与外层进度条一致的较短动画
          duration: 300,
          curve: Curve.EaseInOut
        })
      
      // 字符
      Text(this.codes[this.currentIndex]?.character || '')
        .fontSize(80)
        .fontWeight(FontWeight.Bold)
        // 始终使用深色字符，不随背景变为白色
        .fontColor('#1A1A1A')
    }
  }

  private getProgressColor(): ResourceColor {
    // 只有在最后一步填充动画完成后，才切换为绿色
    return this.showCompletedColor ? Color.Green : '#FFD700'
  }

  private getCircumference(): number {
    // 半径固定为110（见ProgressCircle中Circle尺寸），用于计算描边长度和偏移量
    return 2 * Math.PI * 110
  }

  private isCompleted(): boolean {
    const currentPracticeCount = this.practiceCount.get(this.currentIndex) || 0
    return currentPracticeCount >= this.REQUIRED_PRACTICE_COUNT
  }

  // 基于可动画的progressVisual计算当前圆环长度
  private getProgressVisualLength(): number {
    return this.getCircumference() * Math.max(0, Math.min(this.progressVisual, 1))
  }

  // 使用自定义补间（可替换为 keyframeAnimateTo）将 progressVisual 平滑推进到目标值
  private animateProgressTo(target: number, duration: number = 320, onComplete?: () => void) {
    // 终止已有动画
    if (this.progressTimer !== null) {
      clearInterval(this.progressTimer)
      this.progressTimer = null
    }

    const start = this.progressVisual
    const delta = target - start
    if (Math.abs(delta) < 1e-4 || duration <= 0) {
      this.progressVisual = target
      return
    }

    const startTs = Date.now()
    const easeInOutCubic = (t: number) => t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2

    this.progressTimer = setInterval(() => {
      const t = Math.min(1, (Date.now() - startTs) / duration)
      this.progressVisual = start + delta * easeInOutCubic(t)
      if (t >= 1) {
        if (this.progressTimer !== null) {
          clearInterval(this.progressTimer)
          this.progressTimer = null
        }
        this.progressVisual = target
        if (onComplete) {
          onComplete()
        }
      }
    }, 16)
  }

  @Builder
  private MorseDisplay() {
    Column() {
      Text(this.shouldShowHint(this.currentIndex) ? 
        (this.codes[this.currentIndex]?.morse || '').replace(/\./g, '·') : '?')
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.shouldShowHint(this.currentIndex) ? Color.White : '#FFFFFF80')
        .fontFamily('monospace')
        .letterSpacing(2)
    }
    .height(80)
    .width(150)
    .backgroundColor('#1A1A1A')
    .borderRadius(20)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private InputDisplay() {
    Stack({ alignContent: Alignment.Center }) {
      // 主要输入文本
      Text(this.userInput.replace(/\./g, '·'))
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor(
          this.showResult && this.isCorrect ? Color.Green :
          this.userInput.length === 0 ? Color.Transparent : '#FFD700'
        )
        .fontFamily('monospace')
        .letterSpacing(4)
      
      // 错误时的红色文本
      if (this.showResult && !this.isCorrect) {
        Text(this.userInput.replace(/\./g, '·'))
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Red)
          .fontFamily('monospace')
          .letterSpacing(4)
      }
    }
    .height(60)
    .width('100%')
  }





  private getLessonLetters(): string {
    // 获取当前课程的所有字母，用空格分隔
    return this.codes.map(code => code.character).join(' ')
  }

  private getLetterStatusColor(index: number): ResourceColor {
    const currentPracticeCount = this.practiceCount.get(index) || 0
    const isCompleted = currentPracticeCount >= this.REQUIRED_PRACTICE_COUNT
    const isActive = index === this.currentIndex
    
    if (isCompleted) {
      return Color.Green  // 已完成：绿色
    } else if (isActive) {
      return '#FFD700'    // 当前字母：黄色
    } else {
      return Color.White  // 其他字母：白色
    }
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
      .borderRadius(20)
      .border({ width: 1, color: '#333333' })
      .onClick(() => this.addDot())
      .layoutWeight(1)

      Blank().width(20)

      // 划 (长音)
      Button() {
        Rect({ width: 40, height: 12 })
          .fill('#FFD700')
      }
      .height(80)
      .backgroundColor('#1A1A1A')
      .borderRadius(20)
      .border({ width: 1, color: '#333333' })
      .onClick(() => this.addDash())
      .layoutWeight(1)
    }
    .padding({ left: 20, right: 20, bottom: 20 })
  }

  build() {
    Column() {
      this.TitleBar()

      Blank().height(20)

      // 主要内容区域
      Column() {
        this.ProgressCircle()
        Blank().height(60)
        this.MorseDisplay()
        Blank().height(20)
        this.InputDisplay()
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)



      this.BottomKeys()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
