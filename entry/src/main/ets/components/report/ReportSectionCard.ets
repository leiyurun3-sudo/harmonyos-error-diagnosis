import { AppStateStore } from '../../store/AppStateStore';
import { getThemePalette, ThemePalette } from '../../theme/ThemeModels';
import { ReportSectionKind } from '../../viewmodel/report/ReportModels';

/** Pure report section renderer. It does not know about sessions, repositories or saving. */
@Component
export struct ReportSectionCard {
  @Consume('appState')
  appState: AppStateStore;
  @Prop
  title: string = '';
  @Prop
  items: Array<string> = [];
  @Prop
  kind: ReportSectionKind = ReportSectionKind.STANDARD;

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  build() {
    if (this.items.length > 0) {
      Column({ space: 12 }) {
        Row({ space: 8 }) {
          if (this.kind === ReportSectionKind.RISK) {
            Text('⚠')
          .fontSize(20 * this.appState.contentFontMultiplier)
              .fontColor(this.palette().error)
              .accessibilityText($r('app.string.report_risk_icon_accessibility'))
          }
          Text(this.title)
            .fontSize(20 * this.appState.contentFontMultiplier)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.kind === ReportSectionKind.RISK ? this.palette().error : this.palette().primaryText)
        }
        .width('100%')

        ForEach(this.items, (item: string, index: number) => {
          Row({ space: 10 }) {
            Text(this.kind === ReportSectionKind.STEPS ? `${index + 1}.` : '•')
              .fontWeight(FontWeight.Bold)
              .fontColor(this.kind === ReportSectionKind.RISK ? this.palette().error : this.palette().accent)
            Text(item)
              .layoutWeight(1)
          .fontSize(16 * this.appState.contentFontMultiplier)
              .fontColor(this.palette().primaryText)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        }, (_item: string, index: number): string => `${index}`)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(16)
      .borderRadius(14)
      .border({
        width: this.kind === ReportSectionKind.RISK ? 1 : 0,
        color: this.kind === ReportSectionKind.RISK ? this.palette().error : this.palette().surfaceBackground
      })
      .backgroundColor(this.palette().surfaceBackground)
    }
  }
}
