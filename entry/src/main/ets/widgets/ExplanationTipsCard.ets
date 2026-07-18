@Component
export struct ExplanationTipsCard {
  @Prop title: string = ''
  @Prop content: string = ''

  @Builder
  build() {
    Column() {
      // Title
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start)

      // Content with scroll
      Scroll() {
        Text(this.content)
          .fontSize(14)
          .fontColor('#1A1A1A')
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
    .backgroundColor('#FFF8DC')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }
}
