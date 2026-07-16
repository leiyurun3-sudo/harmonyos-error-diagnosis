import { common } from '@kit.AbilityKit';

/** HarmonyOS Agent Framework Kit 的真实平台边界，按需加载以兼容未预装 Agent HSP 的模拟器。 */
export class HarmonyAgentAdapter {
  async isSupported(context: common.UIAbilityContext, agentId: string): Promise<boolean> {
    if (agentId.trim().length === 0) {
      return false;
    }
    try {
      const kit = await import('@kit.AgentFrameworkKit');
      const controller = new kit.AgentController();
      return await controller.isAgentSupport(context, agentId.trim());
    } catch (_) {
      return false;
    }
  }
}
