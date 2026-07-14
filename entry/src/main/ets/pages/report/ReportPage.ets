import { uiMaterial } from '@kit.ArkUI';
import { AsyncStatePanel } from '../../components/common/AsyncStatePanel';
import { ReportSectionCard } from '../../components/report/ReportSectionCard';
import { DiagnosisReport } from '../../model/DiagnosisModels';
import { OperationStatus } from '../../model/ResultModels';
import { AppRouter } from '../../router/AppRouter';
import { RouteName } from '../../router/RouteNames';
import { ReportRouteParams } from '../../router/RouteModels';
import { createReportViewModel } from '../../service/platform/AppRuntime';
import { AppStateStore } from '../../store/AppStateStore';
import { EffectiveTheme, getThemePalette, ThemePalette } from '../../theme/ThemeModels';
import { ReportSectionKind } from '../../viewmodel/report/ReportModels';
import { ReportViewModel } from '../../viewmodel/report/ReportViewModel';

@Component
export struct ReportPage {
  private readonly lightFocusMaterial: uiMaterial.ImmersiveMaterial = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.THIN,
    materialColor: '#33FFFFFF',
    colorInvert: false,
    applyShadow: true,
    interactive: true,
    lightEffect: { color: Color.White }
  });
  @Consume('appRouter')
  router: AppRouter;
  @Consume('appState')
  appState: AppStateStore;
  @Prop
  routeParams: ReportRouteParams = {
    reportId: 'unavailable',
    origin: RouteName.HOME
  };
  @State
  viewModel: ReportViewModel | undefined = undefined;
  @State
  reportSnapshot: DiagnosisReport | undefined = undefined;
  @State
  rawTextExpanded: boolean = false;

  aboutToAppear(): void {
    if (this.viewModel === undefined) {
      this.viewModel = createReportViewModel(this.routeParams, this.router);
      this.reportSnapshot = this.viewModel.report;
    }
  }

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme);
  }

  private editInput(): void {
    this.viewModel?.editInput();
  }

  @Builder
  private reportContent(report: DiagnosisReport) {
    Column({ space: 16 }) {
      Column({ space: 8 }) {
        Row({ space: 10 }) {
          Text('✓')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().accent)
            .accessibilityText('诊断已完成')
          Text(report.errorType)
            .layoutWeight(1)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().primaryText)
          Text($r('app.string.report_unsaved'))
            .fontSize(14)
            .fontColor(this.palette().accent)
        }
        .width('100%')
        Text(report.summary)
          .width('100%')
          .fontSize(17)
          .fontColor(this.palette().secondaryText)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(16)
      .borderRadius(14)
      .backgroundColor(this.palette().focusSurface)
      .backgroundBlurStyle(this.appState.effectiveTheme === EffectiveTheme.DARK ?
        BlurStyle.Thin : BlurStyle.NONE)
      .systemMaterial(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
        this.lightFocusMaterial : undefined)
      .border({ width: 2, color: this.palette().focusBorder })
      .shadow({
        radius: 24,
        color: this.palette().focusGlow,
        offsetX: 0,
        offsetY: 6
      })

      ReportSectionCard({ title: '匹配证据', items: report.evidence })
      ReportSectionCard({ title: '可能原因', items: report.possibleCauses })
      ReportSectionCard({
        title: '排查步骤',
        items: report.steps,
        kind: ReportSectionKind.STEPS
      })
      if (report.suggestions !== undefined && report.suggestions.length > 0) {
        ReportSectionCard({ title: '建议', items: report.suggestions })
      }
      if (report.riskNotice !== undefined && report.riskNotice.length > 0) {
        ReportSectionCard({
          title: '风险提示',
          items: [report.riskNotice],
          kind: ReportSectionKind.RISK
        })
      }

      Column({ space: 10 }) {
        Text($r('app.string.report_original_text'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().primaryText)
        Text(report.rawText)
          .id('report_raw_text')
          .width('100%')
          .fontSize(15)
          .fontColor(this.palette().secondaryText)
          .maxLines(this.rawTextExpanded ? 20 : 4)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Button(this.rawTextExpanded ? $r('app.string.report_collapse') : $r('app.string.report_expand'))
          .constraintSize({ minHeight: 44 })
          .fontColor(this.palette().accent)
          .onClick((): void => {
            this.rawTextExpanded = !this.rawTextExpanded;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(16)
      .borderRadius(14)
      .backgroundColor(this.palette().surfaceBackground)

      Column({ space: 10 }) {
        Button($r('app.string.report_edit_text'))
          .id('report_edit_text')
          .width('100%')
          .constraintSize({ minHeight: 48 })
          .onClick((): void => {
            this.editInput();
          })
        Button($r('app.string.report_rediagnose'))
          .id('report_rediagnose')
          .width('100%')
          .constraintSize({ minHeight: 48 })
          .fontColor(this.palette().accent)
          .onClick((): void => {
            this.viewModel?.rediagnose();
          })
        Button($r('app.string.route_back_origin'))
          .width('100%')
          .constraintSize({ minHeight: 48 })
          .fontColor(this.palette().secondaryText)
          .onClick((): void => {
            this.viewModel?.backToOrigin();
          })
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          Text($r('app.string.route_report_title'))
            .width('100%')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().primaryText)

          if (this.reportSnapshot !== undefined) {
            this.reportContent(this.reportSnapshot)
          } else if (this.viewModel === undefined) {
            AsyncStatePanel({
              status: OperationStatus.LOADING,
              message: '正在准备诊断报告…',
              showContent: false
            })
          } else {
            AsyncStatePanel({
              status: this.viewModel.reportOperation.status,
              error: this.viewModel.reportError,
              message: this.viewModel.reportError?.message ?? '当前报告不可用。',
              showContent: false
            })
            Button(this.routeParams.origin === RouteName.HISTORY_SETTINGS ?
              $r('app.string.route_back_history_settings') : $r('app.string.route_back_origin'))
              .width('100%')
              .constraintSize({ minHeight: 48 })
              .onClick((): void => {
                this.viewModel?.backToOrigin();
              })
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 20, bottom: 32 })
        .alignItems(HorizontalAlign.Start)
      }
      .id('report_scroll')
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
      .backgroundColor(this.palette().pageBackground)
    }
    .title($r('app.string.route_report_title'))
    .backgroundColor(this.palette().navigationBackground)
  }
}
