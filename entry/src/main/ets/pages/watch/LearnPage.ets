import router from '@ohos.router'
import { common } from '@kit.AbilityKit'
import { CourseCatalogV2, CourseDefinition } from '../../data/CourseCatalogV2'
import { learningRepositoryV2, LearningSnapshot } from '../../repository/LearningRepositoryV2'
import { DistributedSyncPermissionHelper } from '../../utils/DistributedSyncPermissionHelper'
import { LocalizationHelper } from '../../utils/LocalizationHelper'

@Component
export struct LearnPage {
  @State courses: CourseDefinition[] = []
  @State completedCourseIds: string[] = []
  private snapshotListener: ((snapshot: LearningSnapshot) => void) | null = null

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext()?.getHostContext() as common.UIAbilityContext
    this.courses = CourseCatalogV2.getVisible(LocalizationHelper.getCurrentLanguage())
    if (context) {
      const syncGranted = await DistributedSyncPermissionHelper.requestOnLearnEntry(context)
      await learningRepositoryV2.init(context, syncGranted)
      this.applySnapshot(await learningRepositoryV2.getSnapshot())
      this.snapshotListener = (snapshot: LearningSnapshot) => this.applySnapshot(snapshot)
      learningRepositoryV2.subscribe(this.snapshotListener)
    }
  }

  onPageShow(): void {
    void this.refreshSnapshot()
  }

  aboutToDisappear(): void {
    if (this.snapshotListener) {
      learningRepositoryV2.unsubscribe(this.snapshotListener)
      this.snapshotListener = null
    }
  }

  private async refreshSnapshot(): Promise<void> {
    this.applySnapshot(await learningRepositoryV2.getSnapshot())
  }

  private applySnapshot(snapshot: LearningSnapshot): void {
    console.info(`[LearningSyncV2] watch snapshot applied, completed=[${snapshot.completedCourseIds.join(',')}]`)
    this.completedCourseIds = [...snapshot.completedCourseIds]
  }

  private isCompleted(courseId: string): boolean {
    return this.completedCourseIds.includes(courseId)
  }

  private async openCourse(course: CourseDefinition): Promise<void> {
    let title: string = course.id
    try {
      const context = this.getUIContext()?.getHostContext()
      if (context) {
        title = await context.resourceManager.getStringByName(course.titleKey)
      }
    } catch (_error) {
    }
    if (course.kind === 'knowledge') {
      router.pushUrl({
        url: 'pages/watch/KnowledgeLessonPage',
        params: { courseId: course.id, title: title }
      })
    } else {
      router.pushUrl({
        url: 'pages/watch/LessonDetailPage',
        params: { courseId: course.id, title: title }
      })
    }
  }

  build() {
    Column() {
      Text(LocalizationHelper.getString('watch_learn'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFD700')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8, bottom: 8 })

      Scroll() {
        Column() {
          ForEach(this.courses, (course: CourseDefinition) => {
            Row() {
              Column() {
                Text(LocalizationHelper.getString(course.titleKey))
                  .fontSize(15)
                  .fontColor('#FFFFFF')
                  .width('100%')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(LocalizationHelper.getString(course.subtitleKey))
                  .fontSize(11)
                  .fontColor('#AAAAAA')
                  .width('100%')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

              Text(this.isCompleted(course.id) ? '✓' : '›')
                .fontSize(18)
                .fontColor(this.isCompleted(course.id) ? '#4CAF50' : '#FFD700')
            }
            .width('84%')
            .height(54)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('rgba(255, 255, 255, 0.1)')
            .borderRadius(8)
            .margin({ bottom: 8 })
            .clickEffect({ level: ClickEffectLevel.LIGHT })
            .onClick(() => { void this.openCourse(course) })
          }, (course: CourseDefinition) => course.id)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 8, bottom: 40 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .focusable(true)
      .defaultFocus(true)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#000000')
  }
}
