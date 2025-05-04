// FIRST
s0.initScreen();

//1
a.setBins(6);
a.setSmooth(0.98);
osc(90)
  .color(0.1, 0.1, 0.1)
  .rotate(a.fft[5] * 1, () => a.fft[1] * 0.06)
  .modulate(
    osc(9)
      .rotate(() => a.fft[0] * 0.2)
      .add(o0, () => a.fft[0] * 0.09),
  )
  .add(osc(20, () => a.fft[0] * 0.9, 0.1).color(0, () => a.fft[5] * 0.3, 0.3))
  .out(o0);
osc(2, () => a.fft[2] * 0.1, 0.4)
  .color(1, 0.7, 0.5)
  .diff(o0)
  .modulate(o1, () => a.fft[3] * 2)
  .modulate(s0, () => a.fft[2] * 3)
  .diff(s0)
  .out(o1);
render(o1);

// 2
src(o0)
  .saturate(1.01)
  .scale(1.001)
  .color(
    () => a.fft[0] + 0.7,
    () => a.fft[1] + 0.8,
    () => a.fft[2] + 0.8,
  )
  .hue(0.01)
  .modulateHue(
    src(o1)
      .hue(() => a.fft[0] + a.fft[1])
      .posterize(() => a.fft[1] * -2)
      .contrast(0.7),
    () => a.fft[1] + 0.8,
  )
  .layer(src(s0).luma().mult(gradient().saturate(0.8)))
  .layer(src(s0).luma().mult(gradient(4)))
  .out(o0);
noise(1, 0.2)
  .rotate(3.421, 0.5)
  .layer(src(s0).scrollX(() => a.fft[0]) * 5)
  .out(o1);
render(o0);

// 3
shape(200, 0.1, 2)
  .scale(0.2, 0.2)
  .color([osc(4, 0.9), osc(3, 2)].smooth(1), 0.7, 0)
  .repeat(2, 5)
  .modulateScale(osc(2, 0.9), -0.8)
  .add(o0, 0.2)
  .scale(0.2)
  .out();

// 4

osc(18, 0.1, 0)
  .color(2, 0.1, 2)
  .mult(osc(20, 0.01, 0))
  .repeat(1.5, 10)
  .rotate(0.5)
  .modulate(o1)
  .scale(1, () => a.fft[0] * 0.9 + 2)
  .diff(o1)
  .out(o0);
osc(10, 0.2, 0)
  .color(1, 0.7, 0.1)
  .mult(osc(10))
  .diff(s0)
  .modulateRotate(o0, 0.1)
  .rotate(0.2)
  .out(o1);
