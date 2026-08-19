/**
 * 加群找同好 - 手表端
 * 极简展示群二维码，供用户直接扫码加入群聊。
 * 无返回按钮与标题栏：返回由系统返回手势 / 侧键处理。
 */
const GROUP_QR_RAWFILE_NAME: string = 'ic_group_qrcode.jpg'

@Entry
@Component
struct JoinGroupPage {
  aboutToAppear(): void {
    console.info('[JoinGroupPage] aboutToAppear called')
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 10 }) {
          Text('摩斯电码交流群')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFD700')

          Stack({ alignContent: Alignment.Center }) {
            Column()
              .width('88%')
              .height('88%')
              .backgroundColor(Color.White)
              .borderRadius(10)
            Image($rawfile(GROUP_QR_RAWFILE_NAME))
              .width('82%')
              .height('82%')
              .objectFit(ImageFit.Contain)
              .borderRadius(8)
          }
          .width('100%')
            .aspectRatio(1)
            .padding(8)

          Text('使用微信扫一扫加入')
            .fontSize(11)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
          .padding({ top: 8, bottom: 12 })
          .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor('#000000')
    }
    .width('100%')
      .height('100%')
      .backgroundColor('#000000')
  }
}
