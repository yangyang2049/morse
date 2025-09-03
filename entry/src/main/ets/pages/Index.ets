import { LearnPage } from './tabs/LearnPage'
import { PracticeDifficultyPage } from './PracticeDifficultyPage'
import { TranslatePage } from './tabs/TranslatePage'
import { CodeTablePage } from './tabs/CodeTablePage'

@Entry
@Component
struct Index {
  @State index: number = 0;

  @Builder
  TabIcon(icon: Resource, active: boolean = false) {
    // Try different approaches for SVG rendering
    Image(icon)
      .width(24)
      .height(24)
      .renderMode(ImageRenderMode.Template) // Template mode for SVG tinting
      .fillColor(active ? Color.White : '#CCCCCC') // Ensure visibility
      .objectFit(ImageFit.Contain) // Ensure proper scaling
      .onError(() => {
        // Fallback to text icons if SVG fails
        console.error('Failed to load SVG icon:', icon)
      })
  }

  @Builder
  TextTabIcon(text: string, active: boolean = false) {
    // Fallback text icons
    Text(text)
      .fontSize(20)
      .fontColor(active ? Color.White : '#CCCCCC')
      .fontWeight(FontWeight.Bold)
  }

  build() {
    Tabs({ index: this.index }) {
      // Learn
      TabContent() {
        LearnPage()
      }
      .tabBar((): void => { this.TextTabIcon('📚', this.index === 0) })

      // Practice
      TabContent() {
        PracticeDifficultyPage()
      }
      .tabBar((): void => { this.TextTabIcon('🎯', this.index === 1) })

      // Translate
      TabContent() {
        TranslatePage()
      }
      .tabBar((): void => { this.TextTabIcon('🔄', this.index === 2) })

      // 码表 (code table)
      TabContent() {
        CodeTablePage()
      }
      .tabBar((): void => { this.TextTabIcon('📋', this.index === 3) })
    }
    .barMode(BarMode.Fixed)
    .barPosition(BarPosition.End)
    .barBackgroundColor(Color.Black)
    .height('100%')
    .width('100%')
    .onChange((index: number) => this.index = index)
  }
}
