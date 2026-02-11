import router from '@ohos.router'
import preferences from '@ohos.data.preferences'
import { LocalizationHelper } from '../../utils/LocalizationHelper'
import common from '@ohos.app.ability.common'
import { generateBarcode, scanCore } from '@kit.ScanKit'
import { image } from '@kit.ImageKit'
import { ArcButton, ArcButtonOptions, ArcButtonPosition, ArcButtonStyleMode, ColorMetrics } from '@kit.ArkUI'

@Entry
@Component
struct PrivacyPage {
  private context = getContext(this) as common.UIAbilityContext
  @State qrCode: image.PixelMap | null = null
  @State qrCodeGenerating: boolean = false
  private privacyLink = 'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1776276266387804160'

  aboutToAppear(): void {
    void this.generateQRCode()
  }

  private async generateQRCode(): Promise<void> {
    this.qrCodeGenerating = true
    try {
      const pixelMap: image.PixelMap = await generateBarcode.createBarcode(this.privacyLink, {
        scanType: scanCore.ScanType.QR_CODE,
        width: 300,
        height: 300
      })
      this.qrCode = pixelMap
    } catch (err) {
      console.error('[PrivacyPage] Failed to generate QR code:', err)
      this.qrCode = null
    } finally {
      this.qrCodeGenerating = false
    }
  }

  async agreePrivacy() {
    try {
      const preferencesStore = await preferences.getPreferences(this.context, 'app_settings')
      await preferencesStore.put('privacy_agreed', true)
      await preferencesStore.flush()

      router.replaceUrl({
        url: 'pages/watch/Index'
      })
    } catch (error) {
      console.error('[PrivacyPage] Failed to save privacy agreement:', error)
    }
  }

  exitApp() {
    this.context.terminateSelf()
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Text(LocalizationHelper.getString('privacy_title'))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .margin({ top: 16, bottom: 8 })

          Column() {
            if (this.qrCode) {
              Image(this.qrCode)
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Contain)
            } else {
              Column() {
                LoadingProgress()
                  .width(32)
                  .height(32)
                  .color('#FFD700')
                Text(this.qrCodeGenerating ? LocalizationHelper.getString('qr_code_generating') : LocalizationHelper.getString('watch_loading_failed'))
                  .fontSize(10)
                  .fontColor('#666666')
                  .margin({ top: 4 })
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            }
          }
          .width('35%')
          .aspectRatio(1)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .padding(8)
          .margin({ bottom: 4 })

          Text(LocalizationHelper.getString('scan_to_read'))
            .fontSize(10)
            .fontColor('rgba(255, 255, 255, 0.7)')
            .margin({ bottom: 8 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .focusable(true)
      .defaultFocus(true)

      Column() {
        Text(LocalizationHelper.getString('exit_app'))
          .fontSize(12)
          .fontColor('rgba(255, 255, 255, 0.7)')
          .padding({ top: 0, bottom: 12 })
          .onClick(() => {
            this.exitApp()
          })

        ArcButton({
          options: new ArcButtonOptions({
            label: LocalizationHelper.getString('agree'),
            position: ArcButtonPosition.BOTTOM_EDGE,
            styleMode: ArcButtonStyleMode.CUSTOM,
            backgroundColor: ColorMetrics.resourceColor('#FFD700'),
            fontColor: ColorMetrics.resourceColor('#000000'),
            onClick: () => {
              this.agreePrivacy()
            }
          })
        })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#000000')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .gesture(
      PanGesture({ direction: PanDirection.Right })
        .onActionEnd(() => {
          this.exitApp()
        })
    )
  }
}
