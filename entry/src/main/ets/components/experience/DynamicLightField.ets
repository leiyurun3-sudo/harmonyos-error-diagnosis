@Component
export struct DynamicLightField {
  @Prop active: boolean = true;
  @Prop reduced: boolean = false;
  @Prop dark: boolean = true;
  @State private moving: boolean = false;
  private startTimer: number = -1;
  private motionTimer: number = -1;

  aboutToAppear(): void {
    const duration = this.reduced ? 7200 : 4400;
    this.startTimer = setTimeout(() => this.move(duration), 180);
    this.motionTimer = setInterval(() => this.move(duration), duration + 120);
  }

  aboutToDisappear(): void {
    if (this.startTimer >= 0) clearTimeout(this.startTimer);
    if (this.motionTimer >= 0) clearInterval(this.motionTimer);
    this.startTimer = -1;
    this.motionTimer = -1;
  }

  private move(duration: number): void {
    animateTo({ duration: duration, curve: Curve.EaseInOut }, () => {
      this.moving = !this.moving;
    });
  }

  build() {
    Stack() {
      Circle()
        .width(this.reduced ? 250 : 340)
        .height(this.reduced ? 250 : 340)
        .fill(this.dark ? '#9A5B8CFF' : '#705B8CFF')
        .blur(this.reduced ? 72 : 96)
        .opacity(this.active ? (this.moving ? 0.82 : 0.62) : 0)
        .position({ x: this.moving ? 170 : -90, y: this.moving ? 110 : 430 })
      Circle()
        .width(this.reduced ? 220 : 310)
        .height(this.reduced ? 220 : 310)
        .fill(this.dark ? '#8A5CE1D0' : '#6A5CE1D0')
        .blur(this.reduced ? 68 : 92)
        .opacity(this.active ? (this.moving ? 0.58 : 0.78) : 0)
        .position({ x: this.moving ? -70 : 210, y: this.moving ? 650 : 250 })
      Circle()
        .width(210)
        .height(210)
        .fill('#22FFB36B')
        .blur(82)
        .opacity(this.active && !this.reduced ? (this.moving ? 0.62 : 0.38) : 0)
        .position({ x: this.moving ? 210 : 40, y: this.moving ? 850 : 720 })
    }
    .width('100%')
    .height('100%')
    .zIndex(-1)
    .hitTestBehavior(HitTestMode.None)
  }
}
