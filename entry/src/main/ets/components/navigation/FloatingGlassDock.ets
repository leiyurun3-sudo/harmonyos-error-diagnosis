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
    Row() {
      ForEach(this.dockItems, (item: FloatingDockItem) => {
        Button() {
          Column({ space: 4 }) {
            Stack({ alignContent: Alignment.Center }) {
              Text(item.glyph)
                .fontSize(12 * this.appState.contentFontMultiplier)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isSelected(item) ? '#FFFFFF' : this.palette().secondaryText)
                .fontVariations([{ axis: 'wght', value: this.isSelected(item) ? 780 : 620 }])
            }
            .width(34).height(28)
            .borderRadius(10)
            .backgroundColor(this.isSelected(item) ? this.palette().accent : '#12000000')
            Text(item.label)
              .fontSize(10 * this.appState.contentFontMultiplier)
              .fontWeight(this.isSelected(item) ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(this.isSelected(item) ? this.palette().accent : this.palette().secondaryText)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .id(`dock_${item.destination}`)
        .layoutWeight(1)
        .height(62)
        .padding(0)
        .borderRadius(16)
        .backgroundColor(this.isSelected(item) ? '#105B8CFF' : '#00000000')
        .border({
          width: 0,
          color: '#00000000'
        })
        .shadow({
          radius: this.isSelected(item) && this.appState.visualEffectMode === VisualEffectMode.FULL ? 8 : 0,
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
    .padding({ left: 8, right: 8, top: 7, bottom: 7 })
    .alignItems(VerticalAlign.Center)
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
      offsetY: 7
    })
  }
}
