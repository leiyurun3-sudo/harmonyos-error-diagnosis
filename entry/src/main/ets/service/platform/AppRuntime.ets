import {
  common,
  ConfigurationConstant
} from '@kit.AbilityKit';
import { SETTINGS_PREFERENCES_NAME } from '../../constants/StorageKeys';
import {
  DiagnosisService,
  LocalDiagnosisService
} from '../../domain/diagnosis/DiagnosisService';
import { RuleMatcher } from '../../domain/diagnosis/RuleMatcher';
import { InputValidationService } from '../../domain/validation/InputValidationService';
import {
  AccentTheme,
  ContentFontScale,
  ThemeMode,
  VisualEffectMode
} from '../../model/SettingsModels';
import { DiagnosisRuleResourceLoader } from '../../repository/static/DiagnosisRuleResourceLoader';
import { HttpStatusResourceLoader } from '../../repository/static/HttpStatusResourceLoader';
import {
  LocalStaticContentRepository,
  StaticContentRepository
} from '../../repository/static/StaticContentRepository';
import { AppRouter } from '../../router/AppRouter';
import {
  DiagnosisRouteParams,
  ReportRouteParams
} from '../../router/RouteModels';
import { LocalReportRepository } from '../../repository/report/LocalReportRepository';
import {
  ReportRepository,
  SystemTimeSource
} from '../../repository/report/ReportRepository';
import {
  LocalSettingsRepository,
  SettingsRepository
} from '../../repository/settings/SettingsRepository';
import { AppStateStore } from '../../store/AppStateStore';
import { DiagnosisSessionStore } from '../../store/DiagnosisSessionStore';
import { LazyHarmonyPreferencesStore } from '../../storage/preferences/PreferencesStore';
import {
  DatabaseManager,
  HarmonyDatabaseStoreProvider
} from '../../storage/database/DatabaseManager';
import { LazyReportDataStore } from '../../storage/database/LazyReportDataStore';
import {
  RawResourceStore,
  ResourceManagerRawFileContentSource,
  Utf8RawTextDecoder
} from '../../storage/static/RawResourceStore';
import {
  DiagnosisFlowDependencies,
  DiagnosisViewModel
} from '../../viewmodel/diagnosis/DiagnosisViewModel';
import { HomeViewModel } from '../../viewmodel/home/HomeViewModel';
import { HistoryViewModel } from '../../viewmodel/history/HistoryViewModel';
import { ReportViewModel } from '../../viewmodel/report/ReportViewModel';
import { SettingsViewModel } from '../../viewmodel/settings/SettingsViewModel';
import { ThemePlatform } from '../../theme/ThemeModels';
import { HarmonyHiLogSink } from './HarmonyHiLogSink';
import { HiLogService } from './HiLogService';
import { HarmonyThemePlatform } from './HarmonyThemePlatform';
import { SystemIdGenerator } from '../../utils/IdGenerator';
import { SystemTimeProvider } from '../../utils/TimeProvider';

/** Process-level state shared by the Navigation root and all six T11 pages. */
export const appStateStore: AppStateStore = new AppStateStore();

let settingsViewModel: SettingsViewModel | undefined;
let homeViewModel: HomeViewModel | undefined;
let reportDataStore: LazyReportDataStore | undefined;
let reportRepository: ReportRepository | undefined;
let diagnosisSessionStore: DiagnosisSessionStore | undefined;
let diagnosisStaticRepository: StaticContentRepository | undefined;
let diagnosisService: DiagnosisService | undefined;
let diagnosisLogger: HiLogService | undefined;
let diagnosisValidationService: InputValidationService | undefined;

/** Synchronously wires dependencies, then restores Preferences without blocking first render. */
export function configureAppRuntime(context: common.UIAbilityContext): Promise<boolean> {
  const initialColorMode = context.config.colorMode === undefined ?
    ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT : context.config.colorMode;
  const repository = new LocalSettingsRepository(
    new LazyHarmonyPreferencesStore(context, SETTINGS_PREFERENCES_NAME),
    new HiLogService(new HarmonyHiLogSink())
  );
  configureHomeRuntime(context);
  configureDiagnosisRuntime(context);
  return configureAppRuntimeWithAdapters(
    repository,
    new HarmonyThemePlatform(context.getApplicationContext(), initialColorMode),
    new HiLogService(new HarmonyHiLogSink())
  );
}

export function configureDiagnosisRuntime(context: common.UIAbilityContext): void {
  diagnosisLogger = new HiLogService(new HarmonyHiLogSink());
  const reader = new RawResourceStore(
    new ResourceManagerRawFileContentSource(context.resourceManager),
    new Utf8RawTextDecoder(),
    diagnosisLogger
  );
  diagnosisStaticRepository = new LocalStaticContentRepository(
    new DiagnosisRuleResourceLoader(reader, diagnosisLogger),
    new HttpStatusResourceLoader(reader, diagnosisLogger),
    reader,
    diagnosisLogger
  );
  diagnosisSessionStore = new DiagnosisSessionStore(
    new SystemIdGenerator(),
    new SystemTimeProvider()
  );
  diagnosisService = new LocalDiagnosisService(
    new RuleMatcher(),
    new SystemIdGenerator(),
    new SystemTimeProvider(),
    diagnosisLogger
  );
  diagnosisValidationService = new InputValidationService(diagnosisLogger);
}

/** Replaceable composition seam used by device tests; every dependency implements a production interface. */
export function configureDiagnosisRuntimeWithDependencies(
  sessionStore: DiagnosisSessionStore,
  staticRepository: StaticContentRepository,
  service: DiagnosisService,
  logger: HiLogService,
  validationService?: InputValidationService
): void {
  diagnosisSessionStore = sessionStore;
  diagnosisStaticRepository = staticRepository;
  diagnosisService = service;
  diagnosisLogger = logger;
  diagnosisValidationService = validationService ?? new InputValidationService(logger);
}

export function createDiagnosisViewModel(
  routeParams: DiagnosisRouteParams,
  router: AppRouter
): DiagnosisViewModel {
  if (diagnosisSessionStore === undefined || diagnosisStaticRepository === undefined ||
    diagnosisService === undefined || diagnosisLogger === undefined || diagnosisValidationService === undefined) {
    throw new Error('DIAGNOSIS_RUNTIME_NOT_CONFIGURED');
  }
  const dependencies: DiagnosisFlowDependencies = {
    staticContentRepository: diagnosisStaticRepository,
    diagnosisService: diagnosisService,
    router: router,
    logger: diagnosisLogger
  };
  return new DiagnosisViewModel(
    diagnosisSessionStore,
    diagnosisValidationService,
    routeParams,
    dependencies
  );
}

export function createReportViewModel(
  routeParams: ReportRouteParams,
  router: AppRouter
): ReportViewModel {
  if (diagnosisSessionStore === undefined || reportRepository === undefined) {
    throw new Error('DIAGNOSIS_RUNTIME_NOT_CONFIGURED');
  }
  return new ReportViewModel(
    diagnosisSessionStore,
    reportRepository,
    router,
    routeParams,
    async (): Promise<boolean> => {
      if (homeViewModel === undefined) {
        return false;
      }
      return homeViewModel.loadRecent();
    }
  );
}

export function createHistoryViewModel(router: AppRouter): HistoryViewModel {
  if (reportRepository === undefined) {
    throw new Error('HOME_RUNTIME_NOT_CONFIGURED');
  }
  return new HistoryViewModel(reportRepository, router);
}

function configureHomeRuntime(context: common.UIAbilityContext): void {
  const logger = new HiLogService(new HarmonyHiLogSink());
  const manager = new DatabaseManager(new HarmonyDatabaseStoreProvider(context), logger);
  reportDataStore = new LazyReportDataStore(manager, logger);
  configureHomeRuntimeWithRepository(new LocalReportRepository(
    reportDataStore,
    new SystemTimeSource(),
    logger
  ));
}

/** Testable composition seam; production passes the real LocalReportRepository above. */
export function configureHomeRuntimeWithRepository(repository: ReportRepository): void {
  homeViewModel?.dispose();
  reportRepository = repository;
  homeViewModel = new HomeViewModel(repository);
}

export function getHomeViewModel(): HomeViewModel {
  if (homeViewModel === undefined) {
    throw new Error('HOME_RUNTIME_NOT_CONFIGURED');
  }
  return homeViewModel;
}

/** Replaceable composition boundary used by device tests and future platform variants. */
export function configureAppRuntimeWithAdapters(
  repository: SettingsRepository,
  themePlatform: ThemePlatform,
  logger: HiLogService
): Promise<boolean> {
  settingsViewModel?.dispose();
  settingsViewModel = new SettingsViewModel(repository, appStateStore, themePlatform, logger);
  return settingsViewModel.initialize();
}

export function switchApplicationTheme(themeMode: ThemeMode): Promise<boolean> {
  if (settingsViewModel === undefined) {
    return Promise.resolve(false);
  }
  return settingsViewModel.switchTheme(themeMode);
}

export function updateApplicationVisualPreferences(
  accentTheme: AccentTheme,
  contentFontScale: ContentFontScale,
  visualEffectMode: VisualEffectMode
): Promise<boolean> {
  if (settingsViewModel === undefined) {
    return Promise.resolve(false);
  }
  return settingsViewModel.updateVisualPreferences(accentTheme, contentFontScale, visualEffectMode);
}

export function resetApplicationSettings(): Promise<boolean> {
  if (settingsViewModel === undefined) {
    return Promise.resolve(false);
  }
  return settingsViewModel.resetSettings();
}

export function clearApplicationSettingsError(): void {
  settingsViewModel?.clearError();
}

export function disposeAppRuntime(): void {
  settingsViewModel?.dispose();
  settingsViewModel = undefined;
  homeViewModel?.dispose();
  homeViewModel = undefined;
  reportDataStore?.close();
  reportDataStore = undefined;
  reportRepository = undefined;
  diagnosisSessionStore = undefined;
  diagnosisStaticRepository = undefined;
  diagnosisService = undefined;
  diagnosisLogger = undefined;
  diagnosisValidationService = undefined;
}
