@Component
export struct ExplanationTipsCard {
  @Prop title: string = ''
  @Prop content: string = ''
  @Prop color: string = '#FF8C00'

  @Builder
  build() {
    Column() {
      // Title
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.color)
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start)

      // Content with scroll
      Scroll() {
        Text(this.content)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .lineHeight(20)
          .textAlign(TextAlign.Start)
          .width('100%')
      }
      .width('100%')
      .height(100)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height(160)
    .padding(16)
    .backgroundColor('#2A2A2A')
    .border({ width: 1, color: this.color })
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }
}

