import appLimitsTest from './unit/AppLimits.test';
import diagnosisModelsTest from './unit/DiagnosisModels.test';
import errorCodesTest from './unit/ErrorCodes.test';
import hiLogServiceTest from './unit/HiLogService.test';
import operationStateTest from './unit/OperationState.test';
import resultModelsTest from './unit/ResultModels.test';
import settingsModelsTest from './unit/SettingsModels.test';
import testFixtureTest from './unit/TestFixture.test';

export default function testsuite() {
  appLimitsTest();
  diagnosisModelsTest();
  errorCodesTest();
  hiLogServiceTest();
  operationStateTest();
  resultModelsTest();
  settingsModelsTest();
  testFixtureTest();
}
