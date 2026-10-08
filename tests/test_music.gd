extends SceneTree
## Procedural soundtrack: two synthesized loops wired to run state + mute.
var checks: int = 0
var failures: int = 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var MusicBoxScript = load("res://scripts/core/music_box.gd")
	var menu: AudioStreamWAV = MusicBoxScript.make_menu_loop()
	var run: AudioStreamWAV = MusicBoxScript.make_run_loop()
	check(menu != null and run != null, "both loops synthesize")
	check(menu is AudioStreamWAV and run is AudioStreamWAV, "loops are AudioStreamWAV")
	check(menu.loop_mode == AudioStreamWAV.LOOP_FORWARD, "menu loop is LOOP_FORWARD")
	check(run.loop_mode == AudioStreamWAV.LOOP_FORWARD, "run loop is LOOP_FORWARD")
	check(menu.mix_rate == 22050 and run.mix_rate == 22050, "loops render at 22050")
	check(run.data.size() >= 22050 * 2 * 8, "run loop runs at least 8 seconds (%d bytes)" % run.data.size())
	check(menu.data.size() >= 22050 * 2 * 8, "menu loop runs at least 8 seconds (%d bytes)" % menu.data.size())
	check(run.data.size() != menu.data.size(), "the two loops are distinct recordings")
	check(_peak(run.data) > 6000, "run loop actually sounds (peak %d)" % _peak(run.data))
	check(_peak(menu.data) > 2000, "menu loop actually sounds (peak %d)" % _peak(menu.data))
	check(_peak(run.data) < 32000, "run loop stays out of clipping (peak %d)" % _peak(run.data))
	check(absi(run.data.decode_s16(run.data.size() - 2)) < 800, "run loop tail fades so the wrap never clicks")

	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	check(game.music_player != null, "the game owns a music player")
	check(game.menu_music != null and game.run_music != null, "the game generated both loops")
	check(game.music_player.stream == game.menu_music, "title plays the menu loop")
	check(game.music_player.playing, "music is audible on the title")
	game.start_run()
	check(game.music_player.stream == game.run_music, "running swaps to the run loop")
	game.model.toggle_pause()
	game._apply_music()
	check(game.music_player.stream_paused, "pausing the run pauses the music")
	game.model.toggle_pause()
	game._apply_music()
	check(not game.music_player.stream_paused, "resuming unpauses the music")
	game.muted = true
	game._apply_music()
	check(not game.music_player.playing, "the Sound toggle silences music")
	game.muted = false
	game._apply_music()
	check(game.music_player.playing, "unmuting brings music back")
	game.model.state = "dead"
	game._apply_music()
	check(game.music_player.stream == game.menu_music, "the result screen returns to the menu loop")
	print("MUSIC: %d/%d checks passed (menu %.1fs, run %.1fs)" % [checks - failures, checks, menu.data.size() / 2.0 / 22050.0, run.data.size() / 2.0 / 22050.0])
	game.free()
	quit(1 if failures else 0)

func _peak(data: PackedByteArray) -> int:
	var peak: int = 0
	var samples: int = data.size() / 2
	for i in range(0, samples, 7):
		peak = maxi(peak, absi(data.decode_s16(i * 2)))
	return peak
