import { uiMaterial } from '@kit.ArkUI';
import { closeFlashControlWindow } from '../../service/window/WindowRuntime';

@Entry
@Component
struct FlashControlWindow {
  @State private progress: number = 68;
  @State private paused: boolean = false;
  private progressTimer: number = -1;
  private readonly material: uiMaterial.ImmersiveMaterial = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.THIN,
    materialColor: '#331A3355',
    applyShadow: true,
    interactive: true,
    lightEffect: { color: '#8AB4FF' }
  });

  private async closeWindow(): Promise<void> {
    await closeFlashControlWindow();
  }

  aboutToAppear(): void {
    this.progressTimer = setInterval(() => {
      if (!this.paused && this.progress < 100) {
        this.progress = Math.min(100, this.progress + 1);
      }
    }, 900);
  }

  aboutToDisappear(): void {
    if (this.progressTimer >= 0) {
      clearInterval(this.progressTimer);
      this.progressTimer = -1;
    }
  }

  build() {
    Column({ space: 18 }) {
      Row() {
        Column({ space: 4 }) {
          Text('诊断闪控窗').fontSize(26).fontWeight(FontWeight.Bold).fontColor('#F4F7FC')
            .fontVariations([{ axis: 'wght', value: 760 }])
          Text('实时状态 · 可拖动应用子窗').fontSize(13).fontColor('#AAB8CC')
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Text('LIVE').fontSize(11).fontWeight(FontWeight.Bold).fontColor('#5CE1D0')
      }.width('100%')
      Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
        .width('100%').height(12).color('#5B8CFF').backgroundColor('#24364E')
      Text(`${this.paused ? '诊断已暂停' : (this.progress >= 100 ? '诊断已完成' : '正在分析构建日志')} · ${this.progress}%`)
        .width('100%').fontSize(16).fontColor('#F4F7FC')
      Row({ space: 12 }) {
        Button('继续').layoutWeight(1).height(46).backgroundColor('#5B8CFF')
          .onClick(() => {
            this.paused = false;
            this.progress = Math.min(100, this.progress + 8);
          })
        Button(this.paused ? '恢复' : '暂停').layoutWeight(1).height(46).backgroundColor('#1B304A')
          .onClick(() => this.paused = !this.paused)
      }.width('100%')
      Button('关闭闪控窗').width('100%').height(46).backgroundColor('#B42318').borderRadius(14)
        .onClick(() => this.closeWindow())
      Text('标准系统闪控球需要平台能力开通；此处使用真实 WindowStage 子窗完成可运行演示。')
        .fontSize(12).lineHeight(20).fontColor('#91A0B8')
    }
    .width('100%').height('100%').padding(26).justifyContent(FlexAlign.Center)
    .backgroundColor('#E607111F').systemMaterial(this.material)
  }
}
