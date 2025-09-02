import { MorseCode, MorseCodeData } from '../models/MorseCode'
import { router } from '@kit.ArkUI'
import { LearnViewModel } from '../viewmodel/LearnViewModel'
import { LessonData } from '../data/LessonData'
import { promptAction } from '@kit.ArkUI'

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
  // 自动校验的防抖计时器
  private autoCheckTimer: number | null = null
  
  // ViewModel
  private learnViewModel: LearnViewModel = new LearnViewModel()

  aboutToAppear() {
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
      this.practiceCount.set(this.currentIndex, currentPracticeCount + 1)

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
    // 标记课程为已完成
    this.markLessonCompleted()
    
    // 显示完成对话框
    AlertDialog.show({
      title: '恭喜完成！',
      message: `完成了 ${this.codes.length} 个字母的练习`,
      primaryButton: {
        value: '返回',
        action: () => {
          router.back()
        }
      },
      secondaryButton: {
        value: '再次练习',
        action: () => {
          this.currentIndex = 0
          this.completionCount.clear()
          this.clearInput()
        }
      }
    })
  }

  @Builder
  private TitleBar() {
    Column() {
      // 顶部导航栏
      Row() {
        Button() {
          Text('←')
            .fontSize(24)
            .fontColor(Color.White)
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
            Text(this.showMorseCode ? '👁️' : '👁️‍🗨️')
              .fontSize(20)
              .fontColor(Color.White)
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
        .strokeDashArray([this.getProgressLength(), this.getCircumference()])
        .strokeDashOffset(this.getCircumference() / 4)
        .strokeLineCap(LineCapStyle.Round)
        .opacity(this.getProgressLength() > 0 ? 1 : 0) // 进度为0时不显示
        .animation({
          duration: 500,
          curve: Curve.EaseInOut
        })
      
      // 内部圆圈
      Circle({ width: 200, height: 200 })
        .fill(this.getProgressColor())
        .animation({
          duration: 500,
          curve: Curve.EaseInOut
        })
      
      // 字符
      Text(this.codes[this.currentIndex]?.character || '')
        .fontSize(80)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isCompleted() ? Color.White : '#1A1A1A')
    }
  }

  private getProgressColor(): ResourceColor {
    const isCompleted = this.isCompleted()
    return isCompleted ? Color.Green : '#FFD700'
  }

  private getCircumference(): number {
    // 半径固定为110（见ProgressCircle中Circle尺寸），用于计算描边长度和偏移量
    return 2 * Math.PI * 110
  }

  private isCompleted(): boolean {
    const currentPracticeCount = this.practiceCount.get(this.currentIndex) || 0
    return currentPracticeCount >= this.REQUIRED_PRACTICE_COUNT
  }

  private getProgressLength(): number {
    const currentPracticeCount = this.practiceCount.get(this.currentIndex) || 0
    const progress = Math.min(currentPracticeCount / this.REQUIRED_PRACTICE_COUNT, 1)
    return 2 * Math.PI * 110 * progress
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
  }
}
