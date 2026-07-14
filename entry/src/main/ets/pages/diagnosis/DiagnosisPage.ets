import { uiMaterial } from '@kit.ArkUI';
import { AsyncStatePanel } from '../../components/common/AsyncStatePanel';
import { InlineErrorNotice } from '../../components/common/InlineErrorNotice';
import { NoticeSeverity } from '../../components/common/CommonComponentModels';
import { DiagnosisTextEditor } from '../../components/diagnosis/DiagnosisTextEditor';
import { SourceType } from '../../model/DiagnosisModels';
import { OperationStatus } from '../../model/ResultModels';
import { AppRouter } from '../../router/AppRouter';
import { RouteName } from '../../router/RouteNames';
import { DiagnosisRouteParams } from '../../router/RouteModels';
import { createDiagnosisViewModel } from '../../service/platform/AppRuntime';
import { AppStateStore } from '../../store/AppStateStore';
import { EffectiveTheme, getThemePalette, ThemePalette } from '../../theme/ThemeModels';
import { DiagnosisViewModel } from '../../viewmodel/diagnosis/DiagnosisViewModel';

@Component
export struct DiagnosisPage {
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
  routeParams: DiagnosisRouteParams = {
    sourceType: SourceType.TEXT,
    origin: RouteName.HOME
  };
  @State
  viewModel: DiagnosisViewModel | undefined = undefined;
  @State
  startButtonScale: number = 1;

  aboutToAppear(): void {
    if (this.viewModel === undefined) {
      this.viewModel = createDiagnosisViewModel(this.routeParams, this.router);
    }
  }

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme);
  }

  private diagnose(): void {
    this.viewModel?.diagnose();
  }

  build() {
    NavDestination() {
      if (this.viewModel === undefined) {
        AsyncStatePanel({
          status: OperationStatus.LOADING,
          message: '正在准备本地诊断…',
          showContent: false
        })
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Column({ space: 6 }) {
              Text(this.viewModel.session.sourceType === SourceType.IMAGE ?
                $r('app.string.diagnosis_image_title') : $r('app.string.diagnosis_text_title'))
                .width('100%')
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.palette().primaryText)
              Text($r('app.string.route_diagnosis_title'))
                .width('100%')
                .fontSize(14)
                .fontColor(this.palette().secondaryText)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            if (this.viewModel.session.sourceType === SourceType.IMAGE) {
              InlineErrorNotice({
                message: '当前设备 OCR 尚未接入，请先手动输入或粘贴错误文本。',
                severity: NoticeSeverity.INFO
              })
            }

            DiagnosisTextEditor({
              text: this.viewModel.rawText,
              sourceType: this.viewModel.session.sourceType,
              characterCount: this.viewModel.characterCount,
              errorMessage: this.viewModel.inputError?.message ?? '',
              readOnly: this.viewModel.diagnosisOperation.status === OperationStatus.LOADING,
              onTextChange: (value: string): void => {
                this.viewModel?.updateText(value);
              },
              onClear: (): void => {
                this.viewModel?.clearInput();
              }
            })

            if (this.viewModel.diagnosisOperation.status === OperationStatus.LOADING) {
              AsyncStatePanel({
                status: OperationStatus.LOADING,
                message: '正在加载本地规则并生成诊断报告…',
                showContent: false
              })
            } else if (this.viewModel.diagnosisOperation.status === OperationStatus.ERROR &&
              this.viewModel.inputError === undefined) {
              InlineErrorNotice({
                message: this.viewModel.diagnosisError?.message ?? '本地诊断暂时不可用，请稍后重试。',
                actionLabel: '重试诊断',
                onAction: (): void => {
                  this.diagnose();
                }
              })
            }

            Column({ space: 10 }) {
              Button($r('app.string.diagnosis_use_example'))
                .id('diagnosis_use_example')
                .width('100%')
                .constraintSize({ minHeight: 48 })
                .enabled(this.viewModel.diagnosisOperation.status !== OperationStatus.LOADING)
                .fontColor(this.palette().accent)
                .onClick((): void => {
                  this.viewModel?.useExample();
                })
              Button($r('app.string.diagnosis_start'))
                .id('diagnosis_start')
                .width('100%')
                .constraintSize({ minHeight: 52 })
                .fontWeight(FontWeight.Bold)
                .fontColor(this.palette().primaryText)
                .backgroundColor(this.palette().focusSurface)
                .backgroundBlurStyle(this.appState.effectiveTheme === EffectiveTheme.DARK ?
                  BlurStyle.Thin : BlurStyle.NONE)
                .systemMaterial(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
                  this.lightFocusMaterial : undefined)
                .border({ width: 2, color: this.palette().focusBorder })
                .borderRadius(14)
                .shadow({
                  radius: 24,
                  color: this.palette().focusGlow,
                  offsetX: 0,
                  offsetY: 6
                })
                .scale({ x: this.startButtonScale, y: this.startButtonScale })
                .animation({
                  duration: this.startButtonScale < 1 ? 100 : 180,
                  curve: this.startButtonScale < 1 ? Curve.EaseOut : Curve.Friction
                })
                .enabled(this.viewModel.diagnosisOperation.status !== OperationStatus.LOADING)
                .onTouch((event: TouchEvent): void => {
                  if (event.type === TouchType.Down) {
                    this.startButtonScale = 0.98;
                  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.startButtonScale = 1;
                  }
                })
                .onClick((): void => {
                  this.diagnose();
                })
              Button(this.routeParams.origin === RouteName.HOME ?
                $r('app.string.route_back_home') : $r('app.string.route_back_origin'))
                .width('100%')
                .constraintSize({ minHeight: 48 })
                .fontColor(this.palette().secondaryText)
                .onClick((): void => {
                  this.router.back();
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20, bottom: 32 })
          .alignItems(HorizontalAlign.Start)
        }
        .id('diagnosis_scroll')
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Auto)
        .backgroundColor(this.palette().pageBackground)
      }
    }
    .title(this.routeParams.sourceType === SourceType.IMAGE ?
      $r('app.string.diagnosis_image_title') : $r('app.string.diagnosis_text_title'))
    .backgroundColor(this.palette().navigationBackground)
  }
}
