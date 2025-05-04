// You can either use `@latest` or load a specific version with, for example, `@0.4.0`.
await loadScript(
  'https://cdn.jsdelivr.net/npm/hydra-midi@latest/dist/index.js'
)

// Use midi messages from all channels of all inputs.
await midi.start({ channel: '*', input: '*' })
// Show a small midi monitor (similar to hydra's `a.show()`).
midi.show()

// Use any note to control the red amount of hydra's `solid()` function.
osc(note('*', '1').adsr(300, 200, 1, 300).range(5, 25),-0.5,0.51).rotate(note('*', 1).adsr(300, 200, 1, 300).range(2, 255)).kaleid(50).out()

osc(10,note('c2', 1).adsr(0, 50, 0.5, 50).range(-0.1, -0.2), note('*', '3').adsr(100, 400, 0, 300).range(-0.1, -0.2)).kaleid(50).diff(noise(note('*', '2').adsr(0, 400, 0, 400).range(0, -5))).pixelate(128, 128).out(o0)