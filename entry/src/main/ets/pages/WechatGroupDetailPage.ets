import router from '@ohos.router'
import { LocalizationHelper } from '../utils/LocalizationHelper'

/**
 * 手机端加群找同好二维码页。
 * 布局：顶部返回+标题栏 + Scroll（二维码 35%、文案 90%）。
 * 入口：我 tab「加群找同好」。手表端见 pages/watch/WechatGroupDetailPage。
 */
@Entry
@Component
struct WechatGroupDetailPage {
  build() {
    Column() {
      Row() {
        Image($rawfile('ic_back.svg'))
          .width(24)
          .height(24)
          .fillColor('#FFFFFF')
          .onClick(() => router.back())

        Text(LocalizationHelper.getString('join_group_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 24 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#000000')

      Scroll() {
        Column() {
          Column() {
            Image($rawfile('wechat_account.JPG'))
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain)
          }
          .width('35%')
          .aspectRatio(1)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .padding(8)
          .margin({ top: 24, bottom: 20 })

          Text(LocalizationHelper.getString('join_group_detail'))
            .fontSize(15)
            .fontColor('rgba(255, 255, 255, 0.9)')
            .textAlign(TextAlign.Center)
            .width('90%')
            .lineHeight(24)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 8, bottom: 24 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
