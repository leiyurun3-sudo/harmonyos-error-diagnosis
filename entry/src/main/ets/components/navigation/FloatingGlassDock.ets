import { uiMaterial } from '@kit.ArkUI';
import {
  DockDestination,
  FloatingDockItem,
  FloatingDockVisualSpec,
  getFloatingDockItems,
  getFloatingDockVisualSpec
} from '../../model/FloatingDockModels';
import { VisualEffectMode } from '../../model/SettingsModels';
import { AppStateStore } from '../../store/AppStateStore';
import { EffectiveTheme, getThemePalette, ThemePalette } from '../../theme/ThemeModels';

@Component
export struct FloatingGlassDock {
  @ObjectLink
  appState: AppStateStore;
  @Prop
  selected: DockDestination = DockDestination.HOME;
  onSelect: (destination: DockDestination) => void = (): void => {};

  private readonly dockItems: Array<FloatingDockItem> = getFloatingDockItems();
  private readonly visualSpec: FloatingDockVisualSpec = getFloatingDockVisualSpec();
  private readonly glassMaterial: uiMaterial.ImmersiveMaterial = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    materialColor: getFloatingDockVisualSpec().materialTint,
    colorInvert: false,
    applyShadow: false,
    interactive: true,
    lightEffect: { color: Color.White }
  });

  private palette(): ThemePalette {
    return getThemePalette(this.appState.effectiveTheme, this.appState.accentTheme);
  }

  private isSelected(item: FloatingDockItem): boolean {
    return item.destination === this.selected;
  }

  build() {
    Row({ space: 4 }) {
      ForEach(this.dockItems, (item: FloatingDockItem) => {
        Button() {
          Column({ space: 2 }) {
            Text(item.glyph)
              .fontSize(20 * this.appState.contentFontMultiplier)
              .fontWeight(this.isSelected(item) ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(this.isSelected(item) ? this.palette().accent : this.palette().secondaryText)
            Text(item.label)
              .fontSize(11 * this.appState.contentFontMultiplier)
              .fontWeight(this.isSelected(item) ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(this.isSelected(item) ? this.palette().accent : this.palette().secondaryText)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .id(`dock_${item.destination}`)
        .layoutWeight(1)
        .height(50)
        .padding({ left: 4, right: 4, top: 4, bottom: 4 })
        .borderRadius(17)
        .backgroundColor(this.isSelected(item) ? this.palette().accentSurface : '#00000000')
        .border({
          width: this.isSelected(item) ? 1 : 0,
          color: this.isSelected(item) ? this.palette().accent : '#00000000'
        })
        .shadow({
          radius: this.isSelected(item) && this.appState.visualEffectMode === VisualEffectMode.FULL ? 6 : 0,
          color: this.isSelected(item) ? this.palette().accentSurface : '#00000000',
          offsetX: 0,
          offsetY: 0
        })
        .accessibilityText(item.label)
        .onClick((): void => this.onSelect(item.destination))
      }, (item: FloatingDockItem): string => item.destination)
    }
    .width('100%')
    .height(this.visualSpec.height)
    .padding(6)
    .borderRadius(this.visualSpec.cornerRadius)
    .backgroundColor(this.appState.effectiveTheme === EffectiveTheme.DARK ?
      this.visualSpec.darkSurface : this.visualSpec.lightSurface)
    .systemMaterial(this.appState.visualEffectMode === VisualEffectMode.OFF ? undefined : this.glassMaterial)
    .border({ width: 1, color: this.palette().focusBorder })
    .shadow({
      radius: this.appState.visualEffectMode === VisualEffectMode.FULL ? this.visualSpec.fullGlowRadius :
        (this.appState.visualEffectMode === VisualEffectMode.REDUCED ? this.visualSpec.reducedGlowRadius : 3),
      color: this.appState.visualEffectMode === VisualEffectMode.OFF ? '#1F000000' : this.palette().focusGlow,
      offsetX: 0,
      offsetY: 5
    })
  }
}
