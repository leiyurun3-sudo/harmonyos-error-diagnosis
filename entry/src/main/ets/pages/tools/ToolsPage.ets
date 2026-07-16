import { AppRouter } from '../../router/AppRouter';
import { AppStateStore } from '../../store/AppStateStore';
import { getThemePalette, ThemePalette, themeStatusText } from '../../theme/ThemeModels';
import { ToolsRootView } from './ToolsRootView';

@Component
export struct ToolsPage {
  @Consume('appRouter')
  router: AppRouter;
  @Consume('appState')
  appState: AppStateStore;

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  build() {
    NavDestination() {
      ToolsRootView()
    }
    .title($r('app.string.route_tools_title'))
    .backgroundColor(this.palette().navigationBackground)
  }
}
