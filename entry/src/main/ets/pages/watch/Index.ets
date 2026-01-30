import { ArcSwiper, ArcSwiperController, ArcDotIndicator } from '@kit.ArkUI'
import { LearnPage } from './LearnPage'
import { PracticePage } from './PracticePage'
import { CodeTablePage } from './CodeTablePage'
import { SettingsPage } from './SettingsPage'

@Entry
@Component
struct Index {
  @State currentTab: number = 0 // 0: 学习, 1: 练习, 2: 码表, 3: 设置

  private arcSwiperController: ArcSwiperController = new ArcSwiperController()

  /**
   * 是否应允许退出：仅在首页（学习 tab）且右滑时返回 true，
   * 供 onGestureRecognizerJudgeBegin 返回 REJECT 让系统处理退出手势（参考 zhaocha 项目）。
   */
  private shouldAllowExit(event: BaseGestureEvent, current: GestureRecognizer): boolean {
    if (!current || !current.isBuiltIn()) {
      return false
    }
    if (current.getType() !== GestureControl.GestureType.PAN_GESTURE) {
      return false
    }
    const target = current.getEventTargetInfo()
    if (!(target instanceof ScrollableTargetInfo)) {
      return false
    }
    const swiperTarget = target as ScrollableTargetInfo
    const isAtBeginning = swiperTarget.isBegin() || this.currentTab === 0
    const panEvent = event as PanGestureEvent
    const isSwipingRight = panEvent?.offsetX > 0
    return isAtBeginning && isSwipingRight
  }

  build() {
    // 使用 ArcSwiper 进行标签页切换
    ArcSwiper(this.arcSwiperController) {
      // 学习
      LearnPage()

      // 练习
      PracticePage()

      // 码表
      CodeTablePage()

      // 设置
      SettingsPage()
    }
    .index(this.currentTab)
    .indicator(new ArcDotIndicator()
      .itemColor('rgba(255, 255, 255, 0.3)')
      .selectedItemColor('#FFD700'))
    .onChange((index: number) => {
      this.currentTab = index
    })
    .onGestureRecognizerJudgeBegin((event: BaseGestureEvent, current: GestureRecognizer,
      _others: Array<GestureRecognizer>): GestureJudgeResult => {
      if (this.shouldAllowExit(event, current)) {
        return GestureJudgeResult.REJECT
      }
      return GestureJudgeResult.CONTINUE
    })
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
