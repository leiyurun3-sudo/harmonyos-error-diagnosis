import { describe, expect, it } from '@ohos/hypium';
import {
  DockDestination,
  getFloatingDockItems,
  getFloatingDockVisualSpec
} from '../../main/ets/model/FloatingDockModels';

export default function floatingDockModelsTest() {
  describe('FloatingDockModels', () => {
    it('keeps the four course-design top-level destinations in stable order', 0, () => {
      const items = getFloatingDockItems();

      expect(items.length).assertEqual(4);
      expect(items[0].destination).assertEqual(DockDestination.HOME);
      expect(items[1].destination).assertEqual(DockDestination.TOOLS);
      expect(items[2].destination).assertEqual(DockDestination.RECORDS);
      expect(items[3].destination).assertEqual(DockDestination.SETTINGS);
    });

    it('returns independent item arrays', 0, () => {
      const first = getFloatingDockItems();
      first.pop();

      expect(getFloatingDockItems().length).assertEqual(4);
    });

    it('uses a compact centered and lightly translucent dock specification', 0, () => {
      const spec = getFloatingDockVisualSpec();

      expect(spec.horizontalInset).assertEqual(18);
      expect(spec.height).assertEqual(64);
      expect(spec.cornerRadius).assertEqual(25);
      expect(spec.lightSurface).assertEqual('#38FFFFFF');
      expect(spec.fullGlowRadius).assertEqual(18);
    });
  });
}
