/**
 * 加群找同好 - 手表端
 * 极简展示群二维码，供用户直接扫码加入群聊
 */
import { router } from '@kit.ArkUI';
import { SystemBarHelper } from '../../utils/SystemBarHelper';

const GROUP_QR_RAWFILE_NAME: string = 'ic_group_qrcode.jpg';

@Entry
@Component
export struct JoinGroupPage {
  aboutToAppear(): void {
    SystemBarHelper.applyDarkFromUIContext(this.getUIContext());
  }

  build() {
    Column() {
      Row() {
        Button() {
          Image($rawfile('ic_back.svg'))
            .width(16)
            .height(16)
            .fillColor(Color.White)
        }
        .width(36)
          .height(36)
          .backgroundColor(Color.Transparent)
          .borderRadius(18)
          .onClick(() => {
            router.back();
          })

        Text('加群找同好')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 36 })
      }
      .width('100%')
        .height(40)
        .padding({ left: 4, right: 8 })
        .backgroundColor('#000000')

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
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}