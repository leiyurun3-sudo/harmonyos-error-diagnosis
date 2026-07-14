import homePageSmokeTest from './pages/HomePageSmoke.test';
import homePageFlowTest from './pages/HomePageFlow.test';
import navigationFlowTest from './pages/NavigationFlow.test';
import themeFlowTest from './pages/ThemeFlow.test';
import themeStateTest from './pages/ThemeState.test';
import commonComponentsFlowTest from './pages/CommonComponentsFlow.test';
import databaseManagerInstrumentTest from './repository/DatabaseManager.test';
import reportRepositoryInstrumentTest from './repository/ReportRepository.test';
import reportStoreInstrumentTest from './repository/ReportStore.test';

export default function testsuite() {
  homePageSmokeTest();
  homePageFlowTest();
  navigationFlowTest();
  themeFlowTest();
  themeStateTest();
  commonComponentsFlowTest();
  databaseManagerInstrumentTest();
  reportRepositoryInstrumentTest();
  reportStoreInstrumentTest();
}
