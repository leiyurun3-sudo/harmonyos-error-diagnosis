import appLimitsTest from './unit/AppLimits.test';
import diagnosisModelsTest from './unit/DiagnosisModels.test';
import diagnosisRuleResourceTest from './unit/DiagnosisRuleResource.test';
import errorCodesTest from './unit/ErrorCodes.test';
import hiLogServiceTest from './unit/HiLogService.test';
import httpStatusResourceTest from './unit/HttpStatusResource.test';
import operationStateTest from './unit/OperationState.test';
import resultModelsTest from './unit/ResultModels.test';
import settingsModelsTest from './unit/SettingsModels.test';
import testFixtureTest from './unit/TestFixture.test';

export default function testsuite() {
  appLimitsTest();
  diagnosisModelsTest();
  diagnosisRuleResourceTest();
  errorCodesTest();
  hiLogServiceTest();
  httpStatusResourceTest();
  operationStateTest();
  resultModelsTest();
  settingsModelsTest();
  testFixtureTest();
}
