extends RefCounted
## Procedural soundtrack — two loops synthesized at boot, zero audio assets.
##
## MENU (96 BPM, 4 bars): warm pad chords (Am–F–C–G), slow sine bass roots,
## and a soft pluck shimmer — the title/result surface.
## RUN (140 BPM, 8 bars): kick on every beat, snare backbeat, off-eighth
## hats, a driving square bass with octave jumps, and a square lead hook
## that enters for the second half (bars 5-8) so every run builds.
##
## Both render through the same additive voice bank into a 16-bit mono
## AudioStreamWAV with LOOP_FORWARD; the last 5 ms fade to zero so the wrap
## never clicks.

const RATE := 22050
const MASTER := 0.82

const KIND_SINE := 0
const KIND_SQUARE := 1
const KIND_TRI := 2
const KIND_HAT := 3
const KIND_KICK := 4
const KIND_SNARE := 5

const MENU_BPM := 96.0
const RUN_BPM := 140.0

## Verse roots: i–VI–III–VII (Am–F–C–G), twice through the run form.
const RUN_ROOTS := [45, 41, 48, 43, 45, 41, 48, 43]
## Lead hook (bars 5-8): authored eighth grid, 0 = rest, chord-toned.
const RUN_LEAD := [
	[65, 0, 69, 72, 0, 77, 76, 72], # F
	[72, 0, 76, 79, 0, 76, 72, 67], # C
	[79, 0, 74, 71, 0, 74, 76, 79], # G
	[81, 0, 76, 72, 0, 69, 72, 76], # Am — resolves back to the loop top
]
## Menu pads: one chord per bar (Am–F–C–G), plus roots an octave down.
const MENU_PADS := [[57, 60, 64], [53, 57, 60], [55, 60, 64], [55, 59, 62]]
const MENU_ROOTS := [45, 41, 48, 43]


static func make_menu_loop() -> AudioStreamWAV:
	var eighth: float = 60.0 / MENU_BPM / 2.0
	var bar: float = eighth * 8.0
	var events: Array = []
	for b in range(4):
		var t0: float = b * bar
		for midi in MENU_PADS[b]:
			events.append([t0, bar, _hz(midi), 0.05, KIND_TRI, 0.6])
		events.append([t0, 1.0, _hz(MENU_ROOTS[b] - 12), 0.12, KIND_SINE, 0.02])
		events.append([t0 + 4.0 * eighth, 1.0, _hz(MENU_ROOTS[b] - 12), 0.1, KIND_SINE, 0.02])
		# Shimmer pluck: a chord tone up an octave, deterministic per bar.
		var tone: int = MENU_PADS[b][(b * 2) % 3] + 12
		events.append([t0 + 5.0 * eighth, 0.5, _hz(tone), 0.055, KIND_TRI, 0.004])
	return _render(events, bar * 4.0)


static func make_run_loop() -> AudioStreamWAV:
	var eighth: float = 60.0 / RUN_BPM / 2.0
	var bar: float = eighth * 8.0
	var events: Array = []
	for b in range(8):
		var t0: float = b * bar
		for e in range(8):
			var t: float = t0 + e * eighth
			# Drums: kick on the beat, snare backbeat, hats off-eighth.
			if e % 2 == 0:
				events.append([t, 0.16, 0.0, 0.5, KIND_KICK, 0.001])
			else:
				events.append([t, 0.05, 0.0, 0.09, KIND_HAT, 0.001])
			if e == 2 or e == 6:
				events.append([t, 0.12, 180.0, 0.2, KIND_SNARE, 0.001])
			# Bass: square eighths with octave jumps on the pickups.
			var oct: int = 12 if (e == 3 or e == 7) else 0
			events.append([t, eighth * 0.9, _hz(RUN_ROOTS[b] + oct), 0.16, KIND_SQUARE, 0.003])
		# The hook rides the second half of the form.
		if b >= 4:
			for e in range(8):
				var midi: int = RUN_LEAD[b - 4][e]
				if midi > 0:
					var t: float = t0 + e * eighth
					events.append([t, eighth * 0.85, _hz(midi), 0.1, KIND_SQUARE, 0.003])
					events.append([t, eighth * 0.85, _hz(midi - 12), 0.045, KIND_SQUARE, 0.003])
	return _render(events, bar * 8.0)


static func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


static func _render(events: Array, length: float) -> AudioStreamWAV:
	var n := int(length * RATE)
	var mix := PackedFloat32Array()
	mix.resize(n)
	for ev in events:
		_add(mix, ev[0], ev[1], ev[2], ev[3], ev[4], ev[5])
	return _stream(mix)


## Additive voice bank: one note, straight into the mix buffer.
static func _add(mix: PackedFloat32Array, start: float, dur: float, freq: float,
		gain: float, kind: int, attack: float) -> void:
	var n := mix.size()
	var i0 := maxi(0, int(start * RATE))
	var i1 := mini(n, int((start + dur) * RATE))
	var ph := 0.0
	var ph2 := 0.0
	var prev_noise := 0.0
	var decay := 3.0
	match kind:
		KIND_SINE:
			decay = 2.0
		KIND_SQUARE:
			decay = 5.0
		KIND_TRI:
			decay = 6.0
		KIND_HAT:
			decay = 55.0
		KIND_KICK:
			decay = 22.0
		KIND_SNARE:
			decay = 26.0
	for i in range(i0, i1):
		var t := float(i - i0) / RATE
		var env := gain * minf(1.0, t / attack) * exp(-t * decay)
		var s := 0.0
		match kind:
			KIND_SINE:
				s = sin(TAU * ph)
				ph += freq / RATE
			KIND_SQUARE:
				s = 0.8 if fmod(ph, 1.0) < 0.5 else -0.8
				ph += freq / RATE
			KIND_TRI:
				s = 2.0 * absf(2.0 * fmod(ph, 1.0) - 1.0) - 1.0
				ph += freq / RATE
			KIND_HAT:
				var nz := randf() * 2.0 - 1.0
				s = nz - prev_noise
				prev_noise = nz
			KIND_KICK:
				var f := 150.0 * pow(45.0 / 150.0, minf(t / 0.1, 1.0))
				s = sin(ph2)
				ph2 += TAU * f / RATE
			KIND_SNARE:
				var nz2 := randf() * 2.0 - 1.0
				s = nz2 + 0.5 * sin(ph2)
				ph2 += TAU * 180.0 / RATE
		mix[i] += s * env


static func _stream(mix: PackedFloat32Array) -> AudioStreamWAV:
	var n := mix.size()
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	# Fade the last 5 ms so LOOP_FORWARD wraps without a seam click.
	var fade := maxi(1, int(RATE * 0.005))
	for i in range(n):
		var v := clampf(mix[i] * MASTER, -1.0, 1.0)
		if i >= n - fade:
			v *= float(n - i) / fade
		bytes.encode_s16(i * 2, int(v * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = n
	wav.data = bytes
	return wav
