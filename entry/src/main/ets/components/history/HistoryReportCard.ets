import { AppStateStore } from '../../store/AppStateStore';
import {
  getThemePalette,
  ThemePalette
} from '../../theme/ThemeModels';
import { HomeReportItem } from '../../viewmodel/home/HomeModels';

@Component
export struct HistoryReportCard {
  @Consume('appState')
  appState: AppStateStore;
  @Prop
  item: HomeReportItem;
  @Prop
  compact: boolean = true;
  @Prop
  idPrefix: string = 'home_recent_report';
  onOpen: () => void = (): void => {};

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  build() {
    Column({ space: this.compact ? 8 : 12 }) {
      Row({ space: 8 }) {
        Text(this.item.errorType)
          .layoutWeight(1)
          .fontSize((this.compact ? 16 : 18) * this.appState.contentFontMultiplier)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().primaryText)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.item.sourceLabel)
          .fontSize(12 * this.appState.contentFontMultiplier)
          .fontColor(this.palette().accent)
      }
      .width('100%')

      Text(this.item.summary)
        .width('100%')
          .fontSize(14 * this.appState.contentFontMultiplier)
        .fontColor(this.palette().secondaryText)
        .maxLines(this.compact ? 2 : 4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row() {
        Text(this.item.savedAtText)
          .fontSize(12 * this.appState.contentFontMultiplier)
          .fontColor(this.palette().secondaryText)
        Blank()
        Text($r('app.string.home_recent_open'))
          .fontSize(13 * this.appState.contentFontMultiplier)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.palette().accent)
      }
      .width('100%')
    }
    .width('100%')
    .constraintSize({ minHeight: 88 })
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(14)
    .backgroundColor(this.palette().surfaceBackground)
    .id(`${this.idPrefix}_${this.item.reportId}`)
    .accessibilityGroup(true)
    .accessibilityText(this.item.accessibilityText)
    .accessibilityDescription($r('app.string.home_recent_open_accessibility'))
    .onClick(() => this.onOpen())
  }
}
