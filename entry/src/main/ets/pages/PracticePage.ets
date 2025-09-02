import { PracticeViewModel } from '../viewmodel/PracticeViewModel'
import { MorseCode } from '../models/MorseCode'
import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { PracticeRecordDialog } from '../widgets/PracticeRecordDialog'

@Entry
@Component
export struct PracticePage {
  @State vm: PracticeViewModel = new PracticeViewModel()
  @State circleScale: number = 1.0 // 控制圆圈和字符的缩放动画
  @State displayCharacter: string = '' // 用于显示的字符，控制动画时序
  private dialogController: CustomDialogController = new CustomDialogController({
    builder: PracticeRecordDialog({
      vm: $vm
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: false
  })
  private difficulty: string = '简单'
  private lastCharacterChangeId: number = -1
  private animationTimer: number | null = null

  aboutToAppear(): void {
    // 从路由参数获取难度（容错处理，避免无参数时崩溃）
    try {
      const params = (router.getParams?.() as Record<string, Object>) ?? {}
      const diff = params['difficulty'] as string
      this.difficulty = diff && typeof diff === 'string' ? diff : '简单'
    } catch {
      this.difficulty = '简单'
    }
    console.error(`[PracticePage] aboutToAppear: difficulty=${this.difficulty}`)
    this.vm.init(this.difficulty)
    this.displayCharacter = this.vm.getCurrentCharacter() // 初始化显示字符
    this.lastCharacterChangeId = this.vm.getCharacterChangeId()
    this.startAnimationCheck()
  }

  aboutToDisappear(): void {
    this.vm.destroy()
    if (this.animationTimer) {
      clearInterval(this.animationTimer)
    }
  }

  // 开始检查字符变化的定时器
  private startAnimationCheck(): void {
    this.animationTimer = setInterval(() => {
      const currentChangeId = this.vm.getCharacterChangeId()
      if (currentChangeId !== this.lastCharacterChangeId) {
        this.lastCharacterChangeId = currentChangeId
        
        // 先隐藏当前字母（保持旧字符内容）
        animateTo({
          duration: 150,
          curve: Curve.EaseIn
        }, () => {
          this.circleScale = 0.0
        })
        
        // 等待隐藏动画完成后更新字符内容并显示新字母
        setTimeout(() => {
          this.displayCharacter = this.vm.getCurrentCharacter() // 更新显示字符
          
          // 再等50ms后开始显示新字母的动画
          setTimeout(() => {
            animateTo({
              duration: 300,
              curve: Curve.EaseInOut
            }, () => {
              this.circleScale = 1.0
            })
          }, 50)
        }, 150) // 等待隐藏动画完成
      }
    }, 100) // 每100ms检查一次
  }



  @Builder
  private TitleBar() {
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

      Text('练习')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Button() {
        Text('📋')
          .fontSize(18)
          .fontColor(Color.White)
      }
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.dialogController.open()
      })
    }
    .height(52)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  private ProgressCircle() {
    // 使用字符作为唯一key，确保每次字符变化时触发动画
    Stack({ alignContent: Alignment.Center }) {
      // 进度圆环：只有在用户出现错误后才显示
      if (this.vm.getHasIncorrectAttempt()) {
        // 背景圈（暗色）
        Circle({ width: 200, height: 200 })
          .fill(Color.Transparent)
          .strokeWidth(8)
          .stroke('#333333')

        // 进度弧 - 从顶部中心开始（12点方向）
        Circle({ width: 200, height: 200 })
          .fill(Color.Transparent)
          .strokeWidth(8)
          .stroke(this.vm.getProgress() >= 1.0 ? Color.Green : '#FFD700')
          .strokeDashArray([this.getRingLength(), this.getCircumference()])
          .strokeDashOffset(this.getCircumference() * 0.75) // 从顶部12点方向开始
          .strokeLineCap(LineCapStyle.Round)
          .animation({
            duration: 800, // 更长的动画时间
            curve: Curve.EaseOut // 更平滑的曲线
          })
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
    .key(`character_${this.displayCharacter}_${this.vm.getCharacterChangeId()}`) // 唯一key确保动画触发
    .scale({ x: this.circleScale, y: this.circleScale }) // 使用状态控制的缩放
  }

  private getCircumference(): number {
    // 直径200，描边半径近似 90（扣除描边宽度的一半）；对视觉误差不敏感，直接按100半径计算即可
    return 2 * Math.PI * 100
  }

  private getRingLength(): number {
    const progress = Math.max(0, Math.min(this.vm.getProgress(), 1))
    return this.getCircumference() * progress
  }

  @Builder
  private InputDisplay() {
    Stack({ alignContent: Alignment.Center }) {
      // 占位文本（始终存在但透明）
      Text('- - -')
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Transparent)
        .fontFamily('monospace')
        .letterSpacing(4)

      // 主要输入文本
      Text(
        this.vm.getShowHint() || this.vm.getShowCorrectAnswer() ?
        this.vm.getCurrentMorse().split('.').join('·') :
        this.vm.getUserInput().split('.').join('·')
      )
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontFamily('monospace')
        .letterSpacing(4)
        .fontColor(
          this.vm.getShowCorrectAnswer() ? Color.Green :
          (this.vm.getShowHint() ? Color.White :
          (this.vm.getShowResult() && this.vm.getIsCorrect() ? Color.Green :
          (this.vm.getShowResult() && !this.vm.getIsCorrect() ? Color.Red :
          (this.vm.getUserInput().length === 0 ? Color.Transparent : '#FFD700'))))
        )
    }
    .width('100%')
    .height(60)
  }

  @Builder
  private ToolButtons() {
    Row() {
      // 收藏按钮
      Button(this.vm.getIsFavorite() ? '❤' : '♡')
        .onClick(() => this.vm.toggleFavorite())
        .fontColor(this.vm.getIsFavorite() ? Color.Red : Color.White)
        .width(48).height(48)
        .backgroundColor(Color.Transparent)

      // 提示按钮（眼睛）
      Button('👁')
        .onClick(() => this.vm.flashHint())
        .fontColor(Color.White)
        .width(48).height(48)
        .backgroundColor(Color.Transparent)

      // 下一个按钮
      Button('⏭')
        .onClick(() => this.vm.passCharacter())
        .fontColor(Color.White)
        .width(48).height(48)
        .backgroundColor(Color.Transparent)
    }
    .justifyContent(FlexAlign.SpaceEvenly)
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
      .borderRadius(20)
      .border({ width: 1, color: '#333333' })
      .onClick(() => this.vm.addDot())
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
      .onClick(() => this.vm.addDash())
      .layoutWeight(1)
    }
    .padding({ left: 20, right: 20, bottom: 20 })
  }



  build() {
    Stack() {
      Column() {
        this.TitleBar()

        Blank().height(20)

        // 主要内容
        Column() {
          // 字符与进度圆圈
          this.ProgressCircle()

          Blank().height(40)

          this.InputDisplay()
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        this.ToolButtons()
        Blank().height(26)
        this.BottomKeys()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
    }
  }
}
