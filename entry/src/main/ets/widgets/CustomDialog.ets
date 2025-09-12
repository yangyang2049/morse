interface DialogListItem {
  text: string
  selected?: boolean
  onClick?: () => void
}

interface DialogOptions {
  title: string
  message?: string
  confirmText?: string
  cancelText?: string
  showCancel?: boolean
  onConfirm?: () => void
  onCancel?: () => void
  // Optional: render a list of selectable items instead of confirm/cancel
  listItems?: Array<DialogListItem>
  // Optional: show a close button in the header
  showClose?: boolean
  onClose?: () => void
}

// 全局状态管理
class DialogState {
  static showDialog: boolean = false
  static title: string = ''
  static message: string = ''
  static confirmText: string = '确认'
  static cancelText: string = '取消'
  static showCancel: boolean = true
  static onConfirm?: () => void
  static onCancel?: () => void
  static listItems?: Array<DialogListItem>
  static showClose: boolean = false
  static onClose?: () => void

  static show(options: DialogOptions) {
    DialogState.title = options.title
    DialogState.message = options.message || ''
    DialogState.confirmText = options.confirmText || '确认'
    DialogState.cancelText = options.cancelText || '取消'
    DialogState.showCancel = options.showCancel !== false
    DialogState.onConfirm = options.onConfirm
    DialogState.onCancel = options.onCancel
    DialogState.listItems = options.listItems
    DialogState.showClose = options.showClose === true
    DialogState.onClose = options.onClose
    DialogState.showDialog = true
  }

  static hide() {
    DialogState.showDialog = false
  }
}

@Component
export struct CustomDialog {
  @State private showDialog: boolean = false
  @State private title: string = ''
  @State private message: string = ''
  @State private confirmText: string = '确认'
  @State private cancelText: string = '取消'
  @State private showCancel: boolean = true
  @State private listItems: Array<DialogListItem> = []
  @State private showClose: boolean = false
  private onConfirm?: () => void
  private onCancel?: () => void
  private onClose?: () => void

  aboutToAppear() {
    // 监听全局状态变化
    setInterval(() => {
      if (DialogState.showDialog !== this.showDialog) {
        this.showDialog = DialogState.showDialog
        this.title = DialogState.title
        this.message = DialogState.message
        this.confirmText = DialogState.confirmText
        this.cancelText = DialogState.cancelText
        this.showCancel = DialogState.showCancel
        this.onConfirm = DialogState.onConfirm
        this.onCancel = DialogState.onCancel
        this.listItems = DialogState.listItems || []
        this.showClose = DialogState.showClose
        this.onClose = DialogState.onClose
      }
    }, 100)
  }

  private handleConfirm() {
    this.onConfirm?.()
    this.hide()
  }

  private handleCancel() {
    this.onCancel?.()
    this.hide()
  }

  private handleClose() {
    if (this.onClose) {
      this.onClose()
    }
    this.hide()
  }

  private hide() {
    this.showDialog = false
    DialogState.hide()
  }

  @Builder
  private DialogContent() {
    Column() {
      // 标题区：在列表/需要关闭按钮时显示左标题+右关闭；否则居中标题
      if (this.showClose || (this.listItems && this.listItems.length > 0)) {
        Row() {
          Text(this.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .alignSelf(ItemAlign.Start)
            .layoutWeight(1)

          // 关闭按钮
          Button() {
            Image($rawfile('ic_close.svg'))
              .width(20)
              .height(20)
          }
          .width(32)
          .height(32)
          .backgroundColor('rgba(128, 128, 128, 0.2)')
          .borderRadius(16)
          .onClick(() => this.handleClose())
        }
        .width('100%')
        .margin({ bottom: 20 })
      } else {
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: this.message ? 16 : 0 })
      }

      // 消息内容 - 可滚动，左对齐（仅在非列表模式显示）
      if (this.message && (!this.listItems || this.listItems.length === 0)) {
        Scroll() {
          Text(this.message)
            .fontSize(14)
            .fontColor('#CCCCCC')
            .textAlign(TextAlign.Start)
            .width('100%')
            .lineHeight(20)
        }
        .width('100%')
        .height(300)
        .scrollBar(BarState.Auto)
        .margin({ bottom: 24 })
      }

      // 内容区域：如果提供 listItems，展示列表选择；否则展示确认/取消按钮
      if (this.listItems && this.listItems.length > 0) {
        // 语言选择等列表（宽松布局 + 选中高亮圆圈 + 边框加粗）
        Column() {
          ForEach(this.listItems, (item: DialogListItem, index?: number) => {
            Row() {
              Text(item.text)
                .layoutWeight(1)
                .fontSize(16)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Medium)
                .alignSelf(ItemAlign.Start)

              if (item.selected) {
                Circle()
                  .width(16)
                  .height(16)
                  .fill(Color.Transparent)
                  .stroke('#FFD700')
                  .strokeWidth(2)
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#111111')
            .border({
              width: item.selected ? 2 : 1,
              color: item.selected ? '#FFD700' : '#333333',
              radius: 8
            })
            .borderRadius(8)
            .margin({ bottom: 16 })
            .onClick(() => {
              item.onClick && item.onClick()
              this.hide()
            })
          })

          // 可选：底部取消，若需要
          if (this.showCancel) {
            Button(this.cancelText)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .backgroundColor('#111111')
              .border({ width: 1, color: '#333333' })
              .borderRadius(8)
              .width('100%')
              .height(44)
              .onClick(() => this.handleCancel())
              .margin({ top: 4 })
          }
        }
        .width('100%')
      } else {
        // 传统确认/取消
        Column() {
          if (this.showCancel) {
            Button(this.cancelText)
              .fontSize(16)
              .fontColor('#000000')
              .backgroundColor('#333333')
              .borderRadius(8)
              .width('100%')
              .height(44)
              .onClick(() => this.handleCancel())
              .margin({ bottom: 12 })
          }

          Button(this.confirmText)
            .fontSize(16)
            .fontColor('#000000')
            .backgroundColor('#FFD700') // 黄色主题
            .borderRadius(8)
            .width('100%')
            .height(44)
            .onClick(() => this.handleConfirm())
        }
        .width('100%')
      }
    }
    .padding(24)
    .backgroundColor('#1A1A1A')
    .borderRadius(12)
    .width('85%')
    .constraintSize({ maxWidth: 480, maxHeight: '90%' })
  }

  build() {
    if (this.showDialog) {
      Stack() {
        // 背景遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.6)')
          .onClick(() => {
            this.hide()
          })

        // 对话框内容
        this.DialogContent()
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(1000)
    }
  }
}

// 全局对话框管理器
export class DialogManager {
  static show(options: DialogOptions) {
    DialogState.show(options)
  }

  static hide() {
    DialogState.hide()
  }
}
