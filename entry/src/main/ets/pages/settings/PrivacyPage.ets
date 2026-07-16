import { AppRouter } from '../../router/AppRouter';
import { AppStateStore } from '../../store/AppStateStore';
import { getThemePalette, ThemePalette } from '../../theme/ThemeModels';

@Component
export struct PrivacyPage {
  @Consume('appRouter')
  router: AppRouter;
  @Consume('appState')
  appState: AppStateStore;

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 14 }) {
        Text($r('app.string.route_privacy_title'))
          .width('100%')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().primaryText)
          .fontVariations([{ axis: 'wght', value: 780 }])
        Text('本地优先，敏感内容由你掌控')
          .width('100%')
          .fontSize(16)
          .fontColor(this.palette().secondaryText)
        ForEach([
          ['诊断文本', '仅在当前会话内存中处理；只有主动保存报告时才写入本地数据库。'],
          ['截图与视觉 AI', '通过系统图片选择器按次授权，Core Vision Kit 默认在设备端识别。'],
          ['在线 API', '默认关闭。切换到 API 模式后仅发送输入框中明确提交的文本。'],
          ['Agent 与 Skill', '本地 Agent 和 Skill 不上传日志；系统 Agent 需填写已注册的 Agent ID。'],
          ['数据删除', '可在记录页删除单条报告，也可在设置中清除本地数据。']
        ], (item: string[]) => {
          Column({ space: 6 }) {
            Text(item[0]).width('100%').fontSize(17).fontWeight(FontWeight.Bold)
              .fontColor(this.palette().primaryText)
            Text(item[1]).width('100%').fontSize(14).fontColor(this.palette().secondaryText)
          }
          .width('100%').alignItems(HorizontalAlign.Start).padding(16)
          .backgroundColor(this.palette().surfaceBackground).borderRadius(16)
        })
        Button($r('app.string.route_back_history_settings'))
          .width('100%').height(48)
          .onClick(() => this.router.back())
        }
        .width('100%').padding(24)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.palette().pageBackground)
    }
    .title($r('app.string.route_privacy_title'))
    .backgroundColor(this.palette().navigationBackground)
  }
}
