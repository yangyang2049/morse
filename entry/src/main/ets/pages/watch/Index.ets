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
    .gesture(
      PanGesture({ direction: PanDirection.Right })
        .onActionEnd(() => {
          if (this.currentTab === 0) {
            this.context.terminateSelf()
          }
        })
    )
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
