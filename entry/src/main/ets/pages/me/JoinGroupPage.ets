/**
 * 加群找同好 - 摩斯电码交流群
 * 二维码来自群聊，7 天有效，长按或微信扫一扫识别加入
 */
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { common, Want } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { SystemBarHelper } from '../../utils/SystemBarHelper';

const GROUP_QR_RAWFILE_NAME: string = 'ic_group_qrcode.jpg';
const GROUP_QR_SYSTEM_VIEW_URI: string = 'resource://rawfile/' + GROUP_QR_RAWFILE_NAME;

@Entry
@Component
export struct JoinGroupPage {
  @State private saving: boolean = false;

  aboutToAppear(): void {
    SystemBarHelper.applyDarkFromUIContext(this.getUIContext());
  }

  // 调起系统图库全屏查看（系统图库会全屏展示图片，用户可长按保存）
  private openInSystemGallery(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: GROUP_QR_SYSTEM_VIEW_URI
      };
      context.startAbility(want).catch((err: Error) => {
        console.warn('[JoinGroupPage] open system gallery failed:', err.message);
        this.getUIContext().getPromptAction().showToast({ message: '无法打开图片查看器' });
      });
    } catch (e) {
      console.error('[JoinGroupPage] openInSystemGallery failed:', e);
      this.getUIContext().getPromptAction().showToast({ message: '无法打开图片查看器' });
    }
  }

  // SaveButton 安全控件回调：系统临时授权后，应用在回调中保存到相册
  private async handleSaveToGallery(event: ClickEvent, result: number): Promise<void> {
    if (result !== 0) {
      // 0 = SUCCESS，其他为用户拒绝或错误
      console.warn('[JoinGroupPage] SaveButton not authorized, result:', result);
      this.getUIContext().getPromptAction().showToast({ message: '未获得保存授权' });
      return;
    }
    if (this.saving) {
      return;
    }
    this.saving = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
      const uri: string = await phAccessHelper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');

      // 读取 rawfile 中的二维码图片
      const buffer = context.resourceManager.getRawFileContentSync(GROUP_QR_RAWFILE_NAME);
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      try {
        await fileIo.write(file.fd, buffer.buffer);
      } finally {
        fileIo.closeSync(file.fd);
      }
      this.getUIContext().getPromptAction().showToast({ message: '已保存到相册' });
    } catch (e) {
      const err = e as BusinessError;
      console.error('[JoinGroupPage] save failed:', err.code, err.message);
      this.getUIContext().getPromptAction().showToast({ message: '保存失败' });
    } finally {
      this.saving = false;
    }
  }

  @Builder
  HeaderBuilder() {
    Row() {
      Button() {
        Image($rawfile('ic_back.svg'))
          .width(20)
          .height(20)
          .fillColor(Color.White)
      }
      .width(48)
        .height(48)
        .backgroundColor(Color.Transparent)
        .borderRadius(24)
        .onClick(() => {
          router.back();
        })

      Text('加群找同好')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .margin({ right: 48 })
    }
    .width('100%')
      .height(56)
      .backgroundColor('#000000')
      .padding({ left: 4, right: 16 })
  }

  build() {
    Column() {
      this.HeaderBuilder()

      Scroll() {
        Column({ space: 24 }) {
          Column({ space: 6 }) {
            Text('群聊')
              .fontSize(13)
              .fontColor('#999999')
            Text('摩斯电码交流群')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFD700')
          }
          .width('100%')
            .padding({ top: 24 })
            .alignItems(HorizontalAlign.Center)

          // 二维码白底卡片：点击调起系统图库全屏查看
          Stack({ alignContent: Alignment.Center }) {
            Column()
              .width(280)
              .height(280)
              .backgroundColor(Color.White)
              .borderRadius(16)
            Image($rawfile(GROUP_QR_RAWFILE_NAME))
              .width(256)
              .height(256)
              .objectFit(ImageFit.Contain)
              .borderRadius(12)
          }
          .width(280)
            .height(280)
            .onClick(() => {
              this.openInSystemGallery();
            })

          Text('使用微信扫一扫 / 长按识别二维码加入')
            .fontSize(13)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)

          // SaveButton 安全控件：用户点击即获系统临时授权，应用回调里保存到相册
          SaveButton({
            icon: SaveIconStyle.FULL_FILLED,
            text: SaveDescription.SAVE_IMAGE,
            buttonType: ButtonType.Capsule
          })
            .width('70%')
              .height(48)
              .backgroundColor('#FFD700')
              .fontColor(Color.Black)
              .onClick((event: ClickEvent, result: number) => {
                void this.handleSaveToGallery(event, result);
              })
        }
        .width('100%')
          .padding({ left: 24, right: 24, top: 12, bottom: 32 })
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