import { AppStateStore } from '../../store/AppStateStore';
import { getThemePalette, ThemePalette } from '../../theme/ThemeModels';

@Component
export struct ToolsRootView {
  @Consume('appState')
  appState: AppStateStore;

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  @Builder
  private toolCard(title: string, description: string) {
    Column({ space: 6 }) {
      Text(title)
        .width('100%')
          .fontSize(18 * this.appState.contentFontMultiplier)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.palette().primaryText)
      Text(description)
        .width('100%')
          .fontSize(14 * this.appState.contentFontMultiplier)
        .fontColor(this.palette().secondaryText)
    }
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(18)
    .backgroundColor(this.palette().surfaceBackground)
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('验证工具')
          .width('100%')
          .fontSize(30 * this.appState.contentFontMultiplier)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().primaryText)
        Text('常用开发数据的本地验证入口')
          .width('100%')
          .fontSize(15 * this.appState.contentFontMultiplier)
          .fontColor(this.palette().secondaryText)
        this.toolCard('JSON 格式化', '检查并格式化 JSON 文本')
        this.toolCard('HTTP 状态码', '查询常见状态码含义与排查建议')
        this.toolCard('URL 编解码', '处理 URL 参数中的特殊字符')
        this.toolCard('Base64 编解码', '进行本地文本编码和解码')
        this.toolCard('正则验证', '快速验证正则表达式与测试文本')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 24, bottom: 112 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.palette().pageBackground)
  }
}
