import { SourceType } from '../../model/DiagnosisModels';
import { AppResult } from '../../model/ResultModels';
import { AppRouter } from '../../router/AppRouter';
import { RouteName } from '../../router/RouteNames';
import { ResolvedRoute } from '../../router/RouteModels';

/** Converts home actions into the existing lightweight AppRouter contracts. */
export class HomeNavigation {
  private router: AppRouter;

  constructor(router: AppRouter) {
    this.router = router;
  }

  openImageDiagnosis(): AppResult<ResolvedRoute> {
    return this.router.openDiagnosis({ sourceType: SourceType.IMAGE, origin: RouteName.HOME });
  }

  openTextDiagnosis(): AppResult<ResolvedRoute> {
    return this.router.openDiagnosis({ sourceType: SourceType.TEXT, origin: RouteName.HOME });
  }

  openTools(): AppResult<ResolvedRoute> {
    return this.router.openTools({ origin: RouteName.HOME });
  }

  openHistory(): AppResult<ResolvedRoute> {
    return this.router.openHistorySettings({ origin: RouteName.HOME });
  }

  openReport(reportId: string): AppResult<ResolvedRoute> {
    return this.router.openReport({ reportId: reportId, origin: RouteName.HOME });
  }
}
