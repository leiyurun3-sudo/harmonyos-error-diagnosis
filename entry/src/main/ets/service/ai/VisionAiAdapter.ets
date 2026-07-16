import { image } from '@kit.ImageKit';

/** Core Vision Kit OCR 适配器，识别过程在设备端完成。 */
export class VisionAiAdapter {
  async recognize(pixelMap: image.PixelMap): Promise<string> {
    try {
      const kit = await import('@kit.CoreVisionKit');
      const ready = await kit.textRecognition.init();
      if (!ready) {
        return '当前设备没有启用 Core Vision OCR 服务。';
      }
      try {
        const result = await kit.textRecognition.recognizeText(
          { pixelMap: pixelMap },
          { isDirectionDetectionSupported: true }
        );
        return result.value.trim().length === 0 ? '图片中没有识别到可用文字。' : result.value;
      } finally {
        await kit.textRecognition.release();
      }
    } catch (_) {
      return '视觉 AI 识别失败，请换一张更清晰的报错截图后重试。';
    }
  }
}
