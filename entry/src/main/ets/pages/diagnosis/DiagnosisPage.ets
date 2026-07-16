import { uiMaterial } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AsyncStatePanel } from '../../components/common/AsyncStatePanel';
import { InlineErrorNotice } from '../../components/common/InlineErrorNotice';
import { NoticeSeverity } from '../../components/common/CommonComponentModels';
import { DiagnosisTextEditor } from '../../components/diagnosis/DiagnosisTextEditor';
import { DIAGNOSIS_EXAMPLES, DiagnosisExample } from '../../constants/DiagnosisExamples';
import { SourceType } from '../../model/DiagnosisModels';
import { OperationStatus } from '../../model/ResultModels';
import { VisualEffectMode } from '../../model/SettingsModels';
import { AppRouter } from '../../router/AppRouter';
import { RouteName } from '../../router/RouteNames';
import { DiagnosisRouteParams } from '../../router/RouteModels';
import { createDiagnosisViewModel } from '../../service/platform/AppRuntime';
import { VisionAiAdapter } from '../../service/ai/VisionAiAdapter';
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
  @State
  ocrStatus: string = '选择报错截图，Core Vision Kit 会在设备端提取文字。';
  @State
  ocrBusy: boolean = false;
  @State
  sampleSaveStatus: string = '可将 4 张典型报错截图保存到模拟器相册，用于完整演示图片选择与视觉识别流程。';
  private readonly vision: VisionAiAdapter = new VisionAiAdapter();

  aboutToAppear(): void {
    if (this.viewModel === undefined) {
      this.viewModel = createDiagnosisViewModel(this.routeParams, this.router);
    }
  }

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  private diagnose(): void {
    this.viewModel?.diagnose();
  }

  private async chooseImageAndRecognize(): Promise<void> {
    if (this.ocrBusy) {
      return;
    }
    this.ocrBusy = true;
    this.ocrStatus = '正在打开系统安全图片选择器…';
    try {
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const selected = await new photoAccessHelper.PhotoViewPicker().select(options);
      if (selected.photoUris.length === 0) {
        this.ocrStatus = '没有选择图片，可继续手动输入。';
        return;
      }
      this.ocrStatus = '正在调用视觉 AI 识别截图文字…';
      const source = image.createImageSource(selected.photoUris[0]);
      const pixelMap = await source.createPixelMap();
      const text = await this.vision.recognize(pixelMap);
      pixelMap.release();
      source.release();
      this.ocrStatus = text.startsWith('视觉 AI') || text.startsWith('当前设备') || text.startsWith('图片中') ?
        text : `识别完成，共提取 ${text.length} 个字符。`;
      if (!text.startsWith('视觉 AI') && !text.startsWith('当前设备') && !text.startsWith('图片中')) {
        this.viewModel?.updateText(text);
      }
    } catch (_) {
      this.ocrStatus = '图片选择或视觉 AI 暂不可用，可继续粘贴错误文本。';
    } finally {
      this.ocrBusy = false;
    }
  }

  private async saveDiagnosisSamples(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    const helper = photoAccessHelper.getPhotoAccessHelper(context);
    const sampleNames: Array<string> = [
      '01_ArkTS_Type_Error.png',
      '02_Ohpm_Package_Not_Found.png',
      '03_Module_Json_Error.png',
      '04_Network_Timeout.png'
    ];
    this.sampleSaveStatus = '正在写入模拟器相册…';
    try {
      for (let index = 0; index < sampleNames.length; index++) {
        const name = sampleNames[index];
        const data = await context.resourceManager.getRawFileContent(`diagnosis_samples/${name}`);
        const request = photoAccessHelper.MediaAssetChangeRequest.createAssetRequest(
          context,
          photoAccessHelper.PhotoType.IMAGE,
          'png',
          { title: `HarmonyOS_Diagnosis_${index + 1}` }
        );
        request.addResource(photoAccessHelper.ResourceType.IMAGE_RESOURCE, data.buffer as ArrayBuffer);
        await helper.applyChanges(request);
      }
      this.sampleSaveStatus = '已保存 4 张诊断测试图到系统相册，现在可点击“选择截图并识别文字”。';
    } catch (_) {
      this.sampleSaveStatus = '保存测试图失败，请再次点击并允许临时相册写入授权。';
    }
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
          .fontSize(28 * this.appState.contentFontMultiplier)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.palette().primaryText)
              Text($r('app.string.route_diagnosis_title'))
                .width('100%')
          .fontSize(14 * this.appState.contentFontMultiplier)
                .fontColor(this.palette().secondaryText)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            if (this.viewModel.session.sourceType === SourceType.IMAGE) {
              InlineErrorNotice({
                message: this.ocrStatus,
                severity: NoticeSeverity.INFO
              })
              Button(this.ocrBusy ? '正在识别…' : '选择截图并识别文字')
                .width('100%')
                .constraintSize({ minHeight: 48 })
                .enabled(!this.ocrBusy)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFFFF')
                .backgroundColor('#0A59F7')
                .border({ width: 1, color: this.palette().focusBorder })
                .borderRadius(14)
                .onClick((): void => {
                  this.chooseImageAndRecognize();
                })
              SaveButton({
                icon: SaveIconStyle.LINES,
                text: SaveDescription.SAVE_TO_GALLERY,
                buttonType: ButtonType.Capsule
              })
                .width('100%')
                .height(52)
                .fontSize(16 * this.appState.contentFontMultiplier)
                .fontColor('#FFFFFFFF')
                .backgroundColor('#3558C8')
                .onClick((_event: ClickEvent, result: SaveButtonOnClickResult): void => {
                  if (result === SaveButtonOnClickResult.SUCCESS) {
                    this.saveDiagnosisSamples();
                  } else {
                    this.sampleSaveStatus = '未获得临时相册写入授权，请再次点击并确认授权。';
                  }
                })
              Text(this.sampleSaveStatus)
                .width('100%')
                .fontSize(13 * this.appState.contentFontMultiplier)
                .fontColor(this.palette().secondaryText)
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

            Column({ space: 8 }) {
              Text('内置测试用例')
                .width('100%')
                .fontSize(16 * this.appState.contentFontMultiplier)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.palette().primaryText)
              Text('选择不同错误类型，立即填入诊断输入框。')
                .width('100%')
                .fontSize(13 * this.appState.contentFontMultiplier)
                .fontColor(this.palette().secondaryText)
              Scroll() {
                Row({ space: 8 }) {
                  ForEach(DIAGNOSIS_EXAMPLES, (example: DiagnosisExample): void => {
                    Button(`${example.title} · ${example.description}`)
                      .height(44)
                      .fontColor('#FFFFFFFF')
                      .backgroundColor('#3157A4')
                      .borderRadius(12)
                      .onClick((): void => {
                        this.viewModel?.updateText(example.text);
                      })
                  }, (example: DiagnosisExample): string => example.title)
                }
              }
              .width('100%')
              .scrollable(ScrollDirection.Horizontal)
              .scrollBar(BarState.Off)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

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
                .fontColor('#FFFFFFFF')
                .backgroundColor('#087F5B')
                .onClick((): void => {
                  this.viewModel?.useExample();
                })
              Button($r('app.string.diagnosis_start'))
                .id('diagnosis_start')
                .width('100%')
                .constraintSize({ minHeight: 52 })
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFFFF')
                .backgroundColor('#172B4D')
                .backgroundBlurStyle(this.appState.visualEffectMode !== VisualEffectMode.OFF &&
                  this.appState.effectiveTheme === EffectiveTheme.DARK ?
                  BlurStyle.Thin : BlurStyle.NONE)
                .systemMaterial(this.appState.visualEffectMode !== VisualEffectMode.OFF &&
                  this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
                  this.lightFocusMaterial : undefined)
                .border({ width: 2, color: this.palette().focusBorder })
                .borderRadius(14)
                .shadow({
                  radius: this.appState.visualEffectMode === VisualEffectMode.FULL ? 24 :
                    (this.appState.visualEffectMode === VisualEffectMode.REDUCED ? 10 : 0),
                  color: this.appState.visualEffectMode === VisualEffectMode.OFF ? '#00000000' :
                    this.palette().focusGlow,
                  offsetX: 0,
                  offsetY: 6
                })
                .scale({
                  x: this.appState.visualEffectMode === VisualEffectMode.OFF ? 1 : this.startButtonScale,
                  y: this.appState.visualEffectMode === VisualEffectMode.OFF ? 1 : this.startButtonScale
                })
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
                .fontColor('#FFFFFFFF')
                .backgroundColor('#0A59F7')
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
