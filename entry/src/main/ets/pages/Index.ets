import { LearnPage } from './tabs/LearnPage'
import { PracticeDifficultyPage } from './PracticeDifficultyPage'
import { TranslatePage } from './tabs/TranslatePage'
import { CodeTablePage } from './tabs/CodeTablePage'

@Entry
@Component
struct Index {
  @State index: number = 0;

  @Builder
  TabIcon(icon: Resource) {
    Image(icon)
      .width(24)
      .height(24)
      .fillColor(Color.White)
      .objectFit(ImageFit.Contain)
  }

  build() {
    Tabs({ index: this.index }) {
      // Learn
      TabContent() {
        LearnPage()
      }
      .tabBar((): void => { this.TabIcon($r('app.media.tab_learn')) })

      // Practice
      TabContent() {
        PracticeDifficultyPage()
      }
      .tabBar((): void => { this.TabIcon($r('app.media.tab_practice')) })

      // Translate
      TabContent() {
        TranslatePage()
      }
      .tabBar((): void => { this.TabIcon($r('app.media.tab_translate')) })

      // 码表 (code table)
      TabContent() {
        CodeTablePage()
      }
      .tabBar((): void => { this.TabIcon($r('app.media.tab_codetable')) })
    }
    .barMode(BarMode.Fixed)
    .barPosition(BarPosition.End)
    .barBackgroundColor(Color.Black)
    .height('100%')
    .width('100%')
    .onChange((index: number) => this.index = index)
  }
}