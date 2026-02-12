import { LocalizationHelper } from '../../utils/LocalizationHelper'

/**
 * 手表端加群找同好二维码页。
 * 布局：无标题栏，标题在内容内；Scroll 包 Column（标题 + 二维码 40% + 文案 55%），焦点在 Scroll。
 * 入口：手表设置 tab「加群找同好」。手机端见 pages/WechatGroupDetailPage。
 */
@Entry
@Component
struct WechatGroupDetailPage {
  build() {
      Scroll() {
        Column() {
          Text(LocalizationHelper.getString('join_group_title'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFD700')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 12 })

          Column() {
            Image($rawfile('wechat_account.JPG'))
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain)
          }
          .width('40%')
          .aspectRatio(1)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .padding(8)
          .margin({ top: 4, bottom: 12 })

          Text(LocalizationHelper.getString('join_group_detail'))
            .fontSize(15)
            .fontColor('rgba(255, 255, 255, 0.9)')
            .textAlign(TextAlign.Center)
            .width('55%')
            .lineHeight(24)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 16, bottom: 80 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .focusable(true)
      .defaultFocus(true)
      .focusOnTouch(true)


  }
}
