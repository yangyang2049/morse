import { ArcSwiper, ArcSwiperAttribute, ArcSwiperController, ArcDotIndicator } from '@kit.ArkUI'
import { LearnPage } from './LearnPage'
import { PracticePage } from './PracticePage'
import { CodeTablePage } from './CodeTablePage'
import { SettingsPage } from './SettingsPage'
import common from '@ohos.app.ability.common'

@Entry
@Component
struct Index {
  @State currentTab: number = 0 // 0: 学习, 1: 练习, 2: 码表, 3: 设置
  
  private arcSwiperController: ArcSwiperController = new ArcSwiperController()
  private context = getContext(this) as common.UIAbilityContext
  private touchStartX: number = 0
  private touchStartY: number = 0
  private isSwipeRight: boolean = false

  exitApp() {
    this.context.terminateSelf()
  }

  private handleTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.touchStartX = event.touches[0].x
      this.touchStartY = event.touches[0].y
      this.isSwipeRight = false
    } else if (event.type === TouchType.Move) {
      if (this.touchStartX > 0) {
        const deltaX = event.touches[0].x - this.touchStartX
        const deltaY = Math.abs(event.touches[0].y - this.touchStartY)
        // 检测右滑手势：水平移动距离大于垂直移动距离的1.5倍，且从左侧边缘开始
        // 只检测从最左侧边缘（前30像素）开始的右滑，避免与 ArcSwiper 冲突
        if (this.touchStartX < 30 && deltaX > 20 && deltaX > deltaY * 1.5) {
          this.isSwipeRight = true
        } else if (deltaY > deltaX) {
          // 如果垂直移动更多，取消右滑检测
          this.isSwipeRight = false
        }
      }
    } else if (event.type === TouchType.Up) {
      if (this.isSwipeRight && this.touchStartX > 0) {
        const deltaX = event.touches[0].x - this.touchStartX
        // 如果右滑距离超过50像素，触发退出
        if (deltaX > 50) {
          this.exitApp()
        }
      }
      this.touchStartX = 0
      this.touchStartY = 0
      this.isSwipeRight = false
    }
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
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .onTouch((event: TouchEvent) => {
      this.handleTouch(event)
    })
  }
}
