import router from '@ohos.router'
import preferences from '@ohos.data.preferences'
import { Context } from '@kit.AbilityKit'
import { LocalizationHelper } from '../../utils/LocalizationHelper'
import common from '@ohos.app.ability.common'
import { generateBarcode, scanCore } from '@kit.ScanKit'
import { image } from '@kit.ImageKit'

@Entry
@Component
struct PrivacyPage {
  private context = getContext(this) as common.UIAbilityContext
  @State qrCode: image.PixelMap | null = null
  @State qrCodeGenerating: boolean = false
  private privacyLink = 'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1776276266387804160'
  private touchStartX: number = 0
  private touchStartY: number = 0
  private isSwipeRight: boolean = false

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

  private handleTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.touchStartX = event.touches[0].x
      this.touchStartY = event.touches[0].y
      this.isSwipeRight = false
    } else if (event.type === TouchType.Move) {
      if (this.touchStartX > 0) {
        const deltaX = event.touches[0].x - this.touchStartX
        const deltaY = Math.abs(event.touches[0].y - this.touchStartY)
        // 检测右滑手势：水平移动距离大于垂直移动距离的2倍，且从左侧边缘开始
        if (this.touchStartX < 80 && deltaX > 20 && deltaX > deltaY * 1.5) {
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
    Column() {
      Scroll() {
        Column() {
          Text(LocalizationHelper.getString('privacy_title'))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ top: 8, bottom: 6 })
            .textAlign(TextAlign.Center)
            .width('100%')

          // QR Code Section
          Column() {
            Text(LocalizationHelper.getString('scan_to_read'))
              .fontSize(14)
              .fontColor('#FFFFFF')
              .margin({ bottom: 6 })

            if (this.qrCode) {
              Image(this.qrCode)
                .width(120)
                .height(120)
                .backgroundColor(Color.White)
                .borderRadius(12)
                .padding(12)
            } else {
              Column() {
                LoadingProgress()
                  .width(32)
                  .height(32)
                  .color('#FFD700')
                Text(this.qrCodeGenerating ? LocalizationHelper.getString('qr_code_generating') : LocalizationHelper.getString('watch_loading_failed'))
                  .fontSize(12)
                  .fontColor('#666666')
                  .margin({ top: 8 })
              }
              .width(120)
              .height(120)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({ bottom: 12 })

          Column() {
            Button(LocalizationHelper.getString('agree'))
              .width(140)
              .height(40)
              .backgroundColor('#FFD700')
              .fontColor('#000000')
              .margin({ bottom: 8 })
              .onClick(() => {
                this.agreePrivacy()
              })

            Button(LocalizationHelper.getString('exit_app'))
              .fontColor('#FFFFFF')
              .fontSize(14)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.exitApp()
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ bottom: 12 })
        }
        .width('100%')
        .padding({ top: 8, left: 16, right: 16, bottom: 16 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .focusable(true)
      .defaultFocus(true)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .onTouch((event: TouchEvent) => {
      this.handleTouch(event)
    })
  }
}
