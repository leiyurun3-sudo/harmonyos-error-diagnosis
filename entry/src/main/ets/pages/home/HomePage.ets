import { uiMaterial } from '@kit.ArkUI';
import { AsyncStatePanel } from '../../components/common/AsyncStatePanel';
import { EmptyStateView } from '../../components/common/EmptyStateView';
import { InlineErrorNotice } from '../../components/common/InlineErrorNotice';
import { HistoryReportCard } from '../../components/history/HistoryReportCard';
import { OperationStatus } from '../../model/ResultModels';
import { ThemeMode } from '../../model/SettingsModels';
import { AppRouter, ArkNavigationStack } from '../../router/AppRouter';
import { RouteName } from '../../router/RouteNames';
import {
  DiagnosisRouteParams,
  ReportRouteParams
} from '../../router/RouteModels';
import {
  appStateStore as globalAppStateStore,
  getHomeViewModel,
  switchApplicationTheme
} from '../../service/platform/AppRuntime';
import { AppStateStore } from '../../store/AppStateStore';
import {
  EffectiveTheme,
  getThemePalette,
  ThemePalette,
  themeStatusText
} from '../../theme/ThemeModels';
import { HomeReportItem } from '../../viewmodel/home/HomeModels';
import { HomeNavigation } from '../../viewmodel/home/HomeNavigation';
import { HomeViewModel } from '../../viewmodel/home/HomeViewModel';
import { DiagnosisPage } from '../diagnosis/DiagnosisPage';
import { HistorySettingsPage } from '../history/HistorySettingsPage';
import { ReportPage } from '../report/ReportPage';
import { PrivacyPage } from '../settings/PrivacyPage';
import { ToolsPage } from '../tools/ToolsPage';

@Entry
@Component
struct HomePage {
  private readonly pathStack: NavPathStack = new NavPathStack();
  private readonly lightFocusMaterial: uiMaterial.ImmersiveMaterial = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.THIN,
    materialColor: '#33FFFFFF',
    colorInvert: false,
    applyShadow: true,
    interactive: true,
    lightEffect: { color: Color.White }
  });
  private readonly lightSecondaryMaterial: uiMaterial.ImmersiveMaterial = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.THIN,
    materialColor: '#33D7ECFF',
    colorInvert: false,
    applyShadow: true,
    interactive: true,
    lightEffect: { color: '#C8F1FF' }
  });
  @Provide('appRouter')
  private appRouter: AppRouter = new AppRouter(new ArkNavigationStack(this.pathStack));
  @Provide('appState')
  private appState: AppStateStore = globalAppStateStore;
  @State
  private homeViewModel: HomeViewModel = getHomeViewModel();
  private homeNavigation: HomeNavigation = new HomeNavigation(this.appRouter);

  aboutToAppear(): void {
    this.homeViewModel.loadRecent();
  }

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme);
  }

  @Builder
  private primaryEntry(
    entryId: string,
    title: Resource,
    description: Resource,
    isFocus: boolean,
    action: () => void
  ) {
    Button() {
      Column({ space: 8 }) {
        Text(title)
          .width('100%')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().primaryText)
          .textAlign(TextAlign.Start)
        Text(description)
          .width('100%')
          .fontSize(14)
          .fontColor(this.palette().secondaryText)
          .textAlign(TextAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .id(entryId)
    .width('100%')
    .constraintSize({ minHeight: 96 })
    .padding(18)
    .borderRadius(16)
    .backgroundColor(isFocus ? this.palette().focusSurface : this.palette().surfaceBackground)
    .backgroundBlurStyle(isFocus && this.appState.effectiveTheme === EffectiveTheme.DARK ?
      BlurStyle.Thin : BlurStyle.NONE)
    .systemMaterial(isFocus && this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
      this.lightFocusMaterial : undefined)
    .border({
      width: isFocus ? 2 : 0,
      color: isFocus ? this.palette().focusBorder : this.palette().surfaceBackground
    })
    .shadow({
      radius: isFocus ? 24 : 0,
      color: isFocus ? this.palette().focusGlow : '#00000000',
      offsetX: 0,
      offsetY: isFocus ? 6 : 0
    })
    .onClick(action)
  }

  @Builder
  private recentReportList() {
    Column({ space: 12 }) {
      ForEach(this.homeViewModel.recentReports, (item: HomeReportItem) => {
        HistoryReportCard({
          item: item,
          compact: true,
          onOpen: (): void => {
            this.homeNavigation.openReport(item.reportId);
          }
        })
      }, (item: HomeReportItem): string => item.reportId)
    }
    .width('100%')
  }

  @Builder
  routeDestination(routeName: string, routeParams: object) {
    if (routeName === RouteName.DIAGNOSIS) {
      DiagnosisPage({ routeParams: routeParams as DiagnosisRouteParams });
    } else if (routeName === RouteName.REPORT) {
      ReportPage({ routeParams: routeParams as ReportRouteParams });
    } else if (routeName === RouteName.TOOLS) {
      ToolsPage();
    } else if (routeName === RouteName.HISTORY_SETTINGS) {
      HistorySettingsPage();
    } else if (routeName === RouteName.PRIVACY) {
      PrivacyPage();
    } else {
      NavDestination() {
        Column({ space: 12 }) {
          Text($r('app.string.route_unknown_title'))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().primaryText)
          Text($r('app.string.route_unknown_message'))
            .fontColor(this.palette().secondaryText)
          Button($r('app.string.route_back_home'))
            .onClick(() => this.appRouter.openHome())
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .padding(24)
        .backgroundColor(this.palette().pageBackground)
      }
      .title($r('app.string.route_unknown_title'))
    }
  }

  build() {
    Navigation(this.pathStack) {
      Scroll() {
        Column({ space: 18 }) {
          Column({ space: 8 }) {
            Text($r('app.string.app_name'))
              .width('100%')
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.palette().primaryText)
            Text($r('app.string.home_product_description'))
              .width('100%')
              .fontSize(16)
              .fontColor(this.palette().secondaryText)
            Text($r('app.string.home_local_badge'))
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.palette().accent)
              .accessibilityText($r('app.string.home_local_badge_accessibility'))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          this.primaryEntry(
            'home_image_diagnosis',
            $r('app.string.home_image_diagnosis'),
            $r('app.string.home_image_diagnosis_description'),
            true,
            (): void => { this.homeNavigation.openImageDiagnosis(); }
          )
          this.primaryEntry(
            'home_text_diagnosis',
            $r('app.string.home_text_diagnosis'),
            $r('app.string.home_text_diagnosis_description'),
            true,
            (): void => { this.homeNavigation.openTextDiagnosis(); }
          )

          Button($r('app.string.home_tools'))
            .width('100%')
            .constraintSize({ minHeight: 52 })
            .fontColor(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
              this.palette().secondaryActionText : this.palette().accent)
            .backgroundColor(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
              this.palette().secondaryActionSurface : undefined)
            .systemMaterial(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
              this.lightSecondaryMaterial : undefined)
            .border({
              width: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 1 : 0,
              color: this.palette().secondaryActionBorder
            })
            .borderRadius(this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 14 : undefined)
            .shadow({
              radius: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 16 : 0,
              color: this.palette().secondaryActionGlow,
              offsetX: 0,
              offsetY: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 4 : 0
            })
            .onClick(() => this.homeNavigation.openTools())

          Column({ space: 12 }) {
            Row() {
              Text($r('app.string.home_recent_title'))
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.palette().primaryText)
              Blank()
              Button($r('app.string.home_view_all'))
                .constraintSize({ minHeight: 44 })
                .fontColor(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
                  this.palette().secondaryActionText : this.palette().accent)
                .backgroundColor(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
                  this.palette().secondaryActionSurface : undefined)
                .systemMaterial(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
                  this.lightSecondaryMaterial : undefined)
                .border({
                  width: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 1 : 0,
                  color: this.palette().secondaryActionBorder
                })
                .borderRadius(this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 14 : undefined)
                .shadow({
                  radius: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 12 : 0,
                  color: this.palette().secondaryActionGlow,
                  offsetX: 0,
                  offsetY: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 3 : 0
                })
                .onClick(() => this.homeNavigation.openHistory())
            }
            .width('100%')

            if (this.homeViewModel.recentReports.length > 0) {
              this.recentReportList()
            }
            if (this.homeViewModel.recentStatus === OperationStatus.LOADING) {
              AsyncStatePanel({
                status: OperationStatus.LOADING,
                message: '正在加载最近记录',
                showContent: false
              })
            } else if (this.homeViewModel.recentStatus === OperationStatus.ERROR) {
              InlineErrorNotice({
                message: this.homeViewModel.recentError?.message ??
                  '暂时无法读取最近记录，请稍后重试。',
                actionLabel: '重新加载',
                onAction: (): void => { this.homeViewModel.retryRecent(); }
              })
            } else if (this.homeViewModel.isRecentEmpty) {
              EmptyStateView({
                title: '还没有诊断记录',
                description: '完成诊断并主动保存后，最近记录会显示在这里。',
                actionLabel: '开始第一次诊断',
                onAction: (): void => { this.homeNavigation.openTextDiagnosis(); }
              })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Column({ space: 10 }) {
            Text($r('app.string.home_privacy_note'))
              .width('100%')
              .fontSize(13)
              .fontColor(this.palette().secondaryText)
            Text(themeStatusText(this.appState.selectedThemeMode, this.appState.effectiveTheme))
              .fontSize(13)
              .fontColor(this.palette().accent)
            Row({ space: 8 }) {
              Button($r('app.string.theme_verify_light'))
                .constraintSize({ minHeight: 44 })
                .fontColor(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
                  this.palette().secondaryActionText : this.palette().accent)
                .backgroundColor(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
                  this.palette().secondaryActionSurface : undefined)
                .systemMaterial(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
                  this.lightSecondaryMaterial : undefined)
                .border({
                  width: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 1 : 0,
                  color: this.palette().secondaryActionBorder
                })
                .borderRadius(this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 14 : undefined)
                .shadow({
                  radius: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 10 : 0,
                  color: this.palette().secondaryActionGlow,
                  offsetX: 0,
                  offsetY: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 2 : 0
                })
                .onClick(() => switchApplicationTheme(ThemeMode.LIGHT))
              Button($r('app.string.theme_verify_dark'))
                .constraintSize({ minHeight: 44 })
                .fontColor(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
                  this.palette().secondaryActionText : this.palette().accent)
                .backgroundColor(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
                  this.palette().secondaryActionSurface : undefined)
                .systemMaterial(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
                  this.lightSecondaryMaterial : undefined)
                .border({
                  width: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 1 : 0,
                  color: this.palette().secondaryActionBorder
                })
                .borderRadius(this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 14 : undefined)
                .shadow({
                  radius: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 10 : 0,
                  color: this.palette().secondaryActionGlow,
                  offsetX: 0,
                  offsetY: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 2 : 0
                })
                .onClick(() => switchApplicationTheme(ThemeMode.DARK))
              Button($r('app.string.theme_verify_system'))
                .constraintSize({ minHeight: 44 })
                .fontColor(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
                  this.palette().secondaryActionText : this.palette().accent)
                .backgroundColor(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
                  this.palette().secondaryActionSurface : undefined)
                .systemMaterial(this.appState.effectiveTheme === EffectiveTheme.LIGHT ?
                  this.lightSecondaryMaterial : undefined)
                .border({
                  width: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 1 : 0,
                  color: this.palette().secondaryActionBorder
                })
                .borderRadius(this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 14 : undefined)
                .shadow({
                  radius: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 10 : 0,
                  color: this.palette().secondaryActionGlow,
                  offsetX: 0,
                  offsetY: this.appState.effectiveTheme === EffectiveTheme.LIGHT ? 2 : 0
                })
                .onClick(() => switchApplicationTheme(ThemeMode.SYSTEM))
            }
            if (this.appState.isThemeSessionOnly) {
              Text($r('app.string.theme_session_only'))
                .fontSize(14)
                .fontColor(this.palette().error)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 24, bottom: 32 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .id('home_scroll')
      .scrollBar(BarState.Auto)
      .backgroundColor(this.palette().pageBackground)
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.routeDestination)
    .backgroundColor(this.palette().navigationBackground)
  }
}
