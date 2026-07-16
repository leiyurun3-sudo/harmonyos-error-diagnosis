import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { sensor } from '@kit.SensorServiceKit';
import { uiMaterial } from '@kit.ArkUI';

@Component
export struct InteractiveDiagnosticCard {
  @State private activated: boolean = false;
  @State private sensorStatus: string = '点击启用摇一摇，也可直接点击卡片演示';
  private lastTriggerAt: number = 0;
  private readonly material: uiMaterial.ImmersiveMaterial = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.THIN,
    materialColor: '#221A3B5C',
    applyShadow: true,
    interactive: true,
    lightEffect: { color: '#5CE1D0' }
  });

  private trigger(): void {
    const now = Date.now();
    if (now - this.lastTriggerAt < 700) {
      return;
    }
    this.lastTriggerAt = now;
    animateTo({ duration: 420, curve: Curve.EaseOut }, () => {
      this.activated = !this.activated;
    });
  }

  private simulateTrigger(): void {
    this.trigger();
    this.sensorStatus = this.activated ? '模拟器入口已触发，互动卡片恢复待机' :
      '模拟器入口已触发，动态诊断信息正在展示';
  }

  private async enableShake(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const manager = abilityAccessCtrl.createAtManager();
      const permission: Permissions = 'ohos.permission.ACCELEROMETER';
      const result = await manager.requestPermissionsFromUser(context, [permission]);
      if (result.authResults.length === 0 || result.authResults[0] !== 0) {
        this.sensorStatus = '未获得传感器权限，可点击卡片演示动态效果';
        return;
      }
      sensor.on(sensor.SensorId.ACCELEROMETER, (data: sensor.AccelerometerResponse): void => {
        const strength = Math.sqrt(data.x * data.x + data.y * data.y + data.z * data.z);
        if (strength > 19) {
          this.trigger();
          this.sensorStatus = '检测到摇一摇，互动卡片已切换';
        }
      }, { interval: 100000000 });
      this.sensorStatus = '传感器已启用，请摇动设备';
    } catch (_) {
      this.sensorStatus = '模拟器传感器不可用，可点击卡片演示';
    }
  }

  aboutToDisappear(): void {
    try {
      sensor.off(sensor.SensorId.ACCELEROMETER);
    } catch (_) {
    }
  }

  build() {
    Column({ space: 12 }) {
      Stack({ alignContent: Alignment.Center }) {
        Column({ space: 10 }) {
          Text(this.activated ? '动态诊断正在运行' : '互动诊断体验')
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#FFFFFFFF')
            .fontVariations([{ axis: 'wght', value: this.activated ? 820 : 650 }])
          Text(this.activated ? '已匹配 12 项本地规则' : '模拟器可直接启动，无需摇动设备')
            .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#E8EEFF')
          Text(this.activated ? '分析阶段：定位首个根因错误 · 生成可执行修复步骤' :
            '点击下方入口，查看卡片展开、状态变化和诊断进度。')
            .fontSize(12).lineHeight(19).fontColor('#C8D5F2').textAlign(TextAlign.Center)
        }
        .padding({ left: 22, right: 22 })
        .translate({ y: this.activated ? -5 : 0 })
      }
      .width('100%').height(190).backgroundColor('#243A78').systemMaterial(this.material)
      .linearGradient({
        angle: 128,
        colors: this.activated ? [['#184B8A', 0], ['#6A3DE8', 0.5], ['#0B8F83', 1]] :
          [['#172B4D', 0], ['#3157A4', 0.55], ['#7A3FC1', 1]]
      })
      .border({ width: 1, color: this.activated ? '#8EF3E5' : '#9DB9FF' }).borderRadius(24)
      .shadow({ radius: this.activated ? 28 : 14, color: this.activated ? '#665CE1D0' : '#44315BE8', offsetY: 8 })
      .scale({ x: this.activated ? 1.015 : 1, y: this.activated ? 1.015 : 1 })
      .onClick(() => this.simulateTrigger())
      Text(this.sensorStatus).width('100%').fontSize(12).fontColor('#52627A')
      Row({ space: 10 }) {
        Button(this.activated ? '收起互动卡片' : '直接展示互动卡片')
          .layoutWeight(1).height(48).fontColor('#FFFFFFFF').backgroundColor('#5B5BEF').borderRadius(14)
          .linearGradient({ angle: 90, colors: [['#5B8CFF', 0], ['#7658E8', 1]] })
          .onClick(() => this.simulateTrigger())
        Button('启用实体机摇一摇')
          .layoutWeight(1).height(48).fontColor('#FFFFFFFF').backgroundColor('#0A8F83').borderRadius(14)
          .linearGradient({ angle: 90, colors: [['#0A8F83', 0], ['#19B57A', 1]] })
          .onClick(() => this.enableShake())
      }.width('100%')
    }.width('100%')
  }
}
