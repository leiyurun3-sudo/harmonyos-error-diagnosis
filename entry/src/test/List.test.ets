import appLimitsTest from './unit/AppLimits.test';
import diagnosisModelsTest from './unit/DiagnosisModels.test';
import diagnosisRuleResourceLoaderTest from './unit/DiagnosisRuleResourceLoader.test';
import diagnosisRuleResourceTest from './unit/DiagnosisRuleResource.test';
import errorCodesTest from './unit/ErrorCodes.test';
import hiLogServiceTest from './unit/HiLogService.test';
import httpStatusResourceTest from './unit/HttpStatusResource.test';
import httpStatusResourceLoaderTest from './unit/HttpStatusResourceLoader.test';
import operationStateTest from './unit/OperationState.test';
import rawResourceStoreTest from './unit/RawResourceStore.test';
import resultModelsTest from './unit/ResultModels.test';
import settingsModelsTest from './unit/SettingsModels.test';
import staticContentRepositoryTest from './unit/StaticContentRepository.test';
import testFixtureTest from './unit/TestFixture.test';

export default function testsuite() {
  appLimitsTest();
  diagnosisModelsTest();
  diagnosisRuleResourceLoaderTest();
  diagnosisRuleResourceTest();
  errorCodesTest();
  hiLogServiceTest();
  httpStatusResourceTest();
  httpStatusResourceLoaderTest();
  operationStateTest();
  rawResourceStoreTest();
  resultModelsTest();
  settingsModelsTest();
  staticContentRepositoryTest();
  testFixtureTest();
}
