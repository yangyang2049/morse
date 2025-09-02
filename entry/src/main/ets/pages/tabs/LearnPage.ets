interface LessonItem {
  key: string
  title: string
  subtitle?: string
  unlocked: boolean
  unitUnlocked: boolean
  completed: boolean
}

@Component
export struct LearnPage {
  private scroller: Scroller = new Scroller()

  private introLessons(): LessonItem[] {
    return [
      { key: 'intro_0', title: '第1课：摩斯密码基础', subtitle: '点划、间隔、历史与应用', unlocked: true, unitUnlocked: true, completed: false },
      { key: 'intro_1', title: '第2课：中文摩尔斯电码', subtitle: '汉字编码、标点符号、应用场景', unlocked: true, unitUnlocked: true, completed: false },
      { key: 'intro_p1', title: '占位', unlocked: false, unitUnlocked: false, completed: false },
      { key: 'intro_p2', title: '占位', unlocked: false, unitUnlocked: false, completed: false },
      { key: 'intro_p2', title: '占位', unlocked: false, unitUnlocked: false, completed: false },

    ]
  }

  private alphabetLessons(): LessonItem[] {
    const items: LessonItem[] = []
    const subtitles: string[] = ['ABC', 'DEF', 'GHIJ', '复习：A-J', 'KLMN', 'OPQR', 'STUV', 'WXYZ', '复习：K-Z']
    for (let i = 0; i < 9; i++) {
      const isReview = i === 3 || i === 8
      items.push({
        key: `alpha_${i}`,
        title: isReview ? `第${i + 1}课：复习` : `第${i + 1}课`,
        subtitle: subtitles[i],
        unlocked: i === 0,
        unitUnlocked: true,
        completed: false
      })
    }
    return items
  }

  private numberLessons(): LessonItem[] {
    const subtitles: string[] = ['1 2 3', '4 5 6', '7 8 9 0', '复习：0-9']
    const items: LessonItem[] = []
    for (let i = 0; i < 4; i++) {
      const isReview = i === 3
      items.push({
        key: `num_${i}`,
        title: isReview ? `第${i + 1}课：复习` : `第${i + 1}课`,
        subtitle: subtitles[i],
        unlocked: i === 0,
        unitUnlocked: true,
        completed: false
      })
    }
    // Pad up to 4 (no more) for consistent alignment
    while (items.length < 5) {
      items.push({ key: `num_p${items.length}`, title: '占位', unlocked: false, unitUnlocked: false, completed: false })
    }
    return items
  }

  private punctuationLessons(): LessonItem[] {
    const subtitles: string[] = ['., ? ! : ;', '= + - _ " \' , ( ) / @', '复习']
    const items: LessonItem[] = []
    for (let i = 0; i < 3; i++) {
      items.push({
        key: `pun_${i}`,
        title: `第${i + 1}课`,
        subtitle: subtitles[i],
        unlocked: i === 0,
        unitUnlocked: true,
        completed: false
      })
    }
    // Pad up to 4 entries
    while (items.length < 5) {
      items.push({ key: `pun_p${items.length}`, title: '占位', unlocked: false, unitUnlocked: false, completed: false })
    }
    return items
  }

  private wordLessons(): LessonItem[] {
    const items: LessonItem[] = [
      { key: 'word_0', title: '第1课', subtitle: '3字母单词', unlocked: true, unitUnlocked: true, completed: false },
      { key: 'word_1', title: '第2课', subtitle: '4字母单词', unlocked: false, unitUnlocked: true, completed: false },
      { key: 'word_2', title: '第3课', subtitle: '5字母单词', unlocked: false, unitUnlocked: true, completed: false },
      { key: 'intro_p2', title: '占位', unlocked: false, unitUnlocked: false, completed: false },
      { key: 'intro_p2', title: '占位', unlocked: false, unitUnlocked: false, completed: false },

    ]
    while (items.length < 4) {
      items.push({ key: `word_p${items.length}`, title: '占位', unlocked: false, unitUnlocked: false, completed: false })
    }
    return items
  }

  @Builder
  private LessonCard(item: LessonItem) {
    Row() {
      Column() {
        Text(item.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.unlocked ? Color.White : '#FFFFFF99')
          .margin({ bottom: item.subtitle ? 8 : 0 })

        if (item.subtitle) {
          Text(item.subtitle)
            .fontSize(14)
            .fontColor(item.unlocked ? '#B0B0B0' : '#FFFFFF80')
        }
      }
      .layoutWeight(1)

      if (item.completed) {
        Text('✓').fontSize(20).fontColor(Color.Green)
      } else if (item.unlocked) {
        Text('›').fontSize(16).fontColor(Color.White)
      } else if (item.unitUnlocked) {
        Text('🔒').fontSize(16).fontColor('#FFFFFF80')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1A1A1A')
    .border({ width: 1, color: '#333333' })
    .borderRadius(12)
  }

  @Builder
  private UnitCard(title: string, unitNumber: number, lessons: LessonItem[], isUnlocked: boolean) {
    RelativeContainer() {
      // Reference anchor filling the card (use empty Column due to Blank restriction)
      Column() {}
        .id('card')
        .width('100%')
        .height('100%')

      // Big faded number anchored to bottom-right of the card
      Text(`${unitNumber}`)
        .fontSize(80)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .opacity(0.25)  // 25% opacity
        .alignRules({
          bottom: { anchor: 'card', align: VerticalAlign.Bottom },
          right:  { anchor: 'card', align: HorizontalAlign.End }
        })
        .margin({ right: 0, bottom: -10 })  // Negative bottom margin to move it closer
        .zIndex(0)

      Column()
        .alignRules({
          top:  { anchor: 'card', align: VerticalAlign.Top },
          left: { anchor: 'card', align: HorizontalAlign.Start }
        })
        .zIndex(1)
      {
        Row() {
          Text(title)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          if (!isUnlocked) {
            Text('🔒').fontSize(24).fontColor('#FFFFFF99')
          }
        }
        .margin({ top: 24, bottom: 32 })

        // Lessons list (scroll within card); render placeholders with opacity 0 to keep vertical alignment
        Scroll() {
          Column() {
            ForEach(lessons, (l: LessonItem, idx: number) => {
              Column() {
                this.LessonCard(l)
                if (idx < lessons.length - 1) { Blank().height(12) }
              }
              .opacity(l.title === '占位' ? 0.0 : 1.0)
            }, (l: LessonItem) => l.key)
          }
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)  // 移除滚动条
        .edgeEffect(EdgeEffect.Spring)  // 添加弹性效果
        .opacity(isUnlocked ? 1.0 : 0.45)
      }
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .backgroundColor('#1A1A1A')
    .border({ width: 1, color: '#333333' })
    .borderRadius(12)
  }

  build() {
    Column() {
      // Title bar
      Row() {
        Text('学习')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.Black)

      // Horizontal scroll of unit cards
      Scroll(this.scroller) {
        Row() {
          // Intro unit (2 lessons + padding)
          Column() { this.UnitCard('摩斯密码基础', 1, this.introLessons(), true) }
            .width(320).height(500).margin({ right: 16 })

          // Alphabet unit (9)
          Column() { this.UnitCard('字母', 2, this.alphabetLessons(), true) }
            .width(320).height(500).margin({ right: 16 })

          // Numbers unit (4)
          Column() { this.UnitCard('数字', 3, this.numberLessons(), true) }
            .width(320).height(500).margin({ right: 16 })

          // Punctuation unit (3 + pad)
          Column() { this.UnitCard('符号', 4, this.punctuationLessons(), true) }
            .width(320).height(500).margin({ right: 16 })

          // Words unit (3 + pad)
          Column() { this.UnitCard('单词', 5, this.wordLessons(), true) }
            .width(320).height(500)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Auto)
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 16, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
