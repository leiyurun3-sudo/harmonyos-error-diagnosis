/** Top-level destinations shown by the floating Dock. Flow pages are intentionally excluded. */
export enum DockDestination {
  HOME = 'HOME',
  TOOLS = 'TOOLS',
  RECORDS = 'RECORDS',
  SETTINGS = 'SETTINGS'
}

export interface FloatingDockItem {
  destination: DockDestination;
  label: string;
  glyph: string;
}

export interface FloatingDockVisualSpec {
  horizontalInset: number;
  bottomInset: number;
  height: number;
  cornerRadius: number;
  lightSurface: string;
  darkSurface: string;
  materialTint: string;
  fullGlowRadius: number;
  reducedGlowRadius: number;
}

/** Stable visual geometry shared by the Dock component and its tests. */
export function getFloatingDockVisualSpec(): FloatingDockVisualSpec {
  return {
    horizontalInset: 18,
    bottomInset: 22,
    height: 76,
    cornerRadius: 24,
    lightSurface: '#38FFFFFF',
    darkSurface: '#3829303A',
    materialTint: '#16FFFFFF',
    fullGlowRadius: 18,
    reducedGlowRadius: 8
  };
}

/** Returns a fresh array so view state cannot mutate the shared navigation definition. */
export function getFloatingDockItems(): Array<FloatingDockItem> {
  return [
    { destination: DockDestination.HOME, label: '首页', glyph: 'HM' },
    { destination: DockDestination.TOOLS, label: '智能', glyph: 'AI' },
    { destination: DockDestination.RECORDS, label: '记录', glyph: 'RC' },
    { destination: DockDestination.SETTINGS, label: '设置', glyph: 'ST' }
  ];
}
