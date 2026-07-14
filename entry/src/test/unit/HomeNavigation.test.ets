import { describe, expect, it } from '@ohos/hypium';
import { SourceType } from '../../main/ets/model/DiagnosisModels';
import { AppRouter, RoutePathInfo } from '../../main/ets/router/AppRouter';
import { RouteName } from '../../main/ets/router/RouteNames';
import {
  DiagnosisRouteParams,
  HistorySettingsRouteParams,
  ReportRouteParams,
  ToolsRouteParams
} from '../../main/ets/router/RouteModels';
import { HomeNavigation } from '../../main/ets/viewmodel/home/HomeNavigation';
import { FakeNavigationStack } from '../fakes/FakeNavigationStack';

interface HomeNavigationFixture {
  navigation: HomeNavigation;
  stack: FakeNavigationStack;
}

function setup(): HomeNavigationFixture {
  const stack = new FakeNavigationStack();
  return { navigation: new HomeNavigation(new AppRouter(stack)), stack: stack };
}

export default function homeNavigationTest() {
  describe('HomeNavigation', () => {
    it('opens image diagnosis with IMAGE and home origin', 0, () => {
      const fixture = setup();
      fixture.navigation.openImageDiagnosis();
      const params = fixture.stack.paths[0].param as DiagnosisRouteParams;

      expect(fixture.stack.paths[0].name).assertEqual(RouteName.DIAGNOSIS);
      expect(params.sourceType).assertEqual(SourceType.IMAGE);
      expect(params.origin).assertEqual(RouteName.HOME);
    });

    it('opens text diagnosis with TEXT and home origin', 0, () => {
      const fixture = setup();
      fixture.navigation.openTextDiagnosis();
      const params = fixture.stack.paths[0].param as DiagnosisRouteParams;

      expect(params.sourceType).assertEqual(SourceType.TEXT);
      expect(params.origin).assertEqual(RouteName.HOME);
    });

    it('opens tools and history with only the home origin', 0, () => {
      const fixture = setup();
      fixture.navigation.openTools();
      const tools = fixture.stack.paths[0].param as ToolsRouteParams;
      expect(tools.origin).assertEqual(RouteName.HOME);
      expect(JSON.stringify(tools)).assertEqual('{"origin":"home"}');

      fixture.navigation.openHistory();
      const history = fixture.stack.paths[1].param as HistorySettingsRouteParams;
      expect(history.origin).assertEqual(RouteName.HOME);
      expect(JSON.stringify(history)).assertEqual('{"origin":"home"}');
    });

    it('opens a recent report with only reportId and home origin', 0, () => {
      const fixture = setup();
      fixture.navigation.openReport('synthetic-report-route');
      const path: RoutePathInfo = fixture.stack.paths[0];
      const params = path.param as ReportRouteParams;
      const serialized = JSON.stringify(params);

      expect(path.name).assertEqual(RouteName.REPORT);
      expect(params.reportId).assertEqual('synthetic-report-route');
      expect(params.origin).assertEqual(RouteName.HOME);
      expect(serialized.includes('"reportId":"synthetic-report-route"')).assertTrue();
      expect(serialized.includes('"origin":"home"')).assertTrue();
      expect(serialized.includes('sessionId')).assertFalse();
      expect(serialized.includes('rawText')).assertFalse();
    });
  });
}
