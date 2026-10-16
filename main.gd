extends Control
# Memory Match - Created by Armin

const CREDIT := "Created by Armin"
const MAX_LEVEL := 50

var diffs := {
	"Easy": {"color": Color("#2fbf8f"), "pre": 2.2, "pre_min": 0.8, "par": 6.0, "offset": 0,
		"tiers": [[2, 3], [2, 4], [3, 4], [3, 4], [4, 4]]},
	"Medium": {"color": Color("#f5a623"), "pre": 1.8, "pre_min": 0.6, "par": 5.0, "offset": 2,
		"tiers": [[3, 4], [4, 4], [4, 5], [4, 5], [4, 6]]},
	"Hard": {"color": Color("#ef476f"), "pre": 1.4, "pre_min": 0.3, "par": 4.0, "offset": 4,
		"tiers": [[4, 4], [4, 5], [4, 6], [4, 6], [4, 6]]},
}

# =====================================================
#  Animated background bubbles
# =====================================================
class Bubbles extends Control:
	var items: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in 16:
			items.append({
				"x": randf(), "y": randf(),
				"r": randf_range(14.0, 60.0),
				"s": randf_range(0.01, 0.035),
				"a": randf_range(0.04, 0.12),
				"ph": randf() * TAU,
			})

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		for it in items:
			it["y"] = float(it["y"]) - float(it["s"]) * delta * 2.0
			if float(it["y"]) < -0.1:
				it["y"] = 1.1
				it["x"] = randf()
		queue_redraw()

	func _draw() -> void:
		var tm: float = Time.get_ticks_msec() / 1000.0
		for it in items:
			var px: float = (float(it["x"]) + sin(tm + float(it["ph"])) * 0.02) * size.x
			var p: Vector2 = Vector2(px, float(it["y"]) * size.y)
			var a: float = float(it["a"])
			draw_circle(p, float(it["r"]), Color(1, 1, 1, a))
			draw_arc(p, float(it["r"]), 0.0, TAU, 32, Color(1, 1, 1, a * 1.6), 2.0, true)

# =====================================================
#  Star helper + rating row
# =====================================================
class StarRow extends Control:
	var count := 0
	var progress := 0.0:
		set(v):
			progress = v
			queue_redraw()

	func _init() -> void:
		custom_minimum_size = Vector2(320, 100)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func animate(n: int) -> void:
		count = n
		progress = 0.0
		var t := create_tween()
		t.tween_property(self, "progress", 3.0, 1.1)

	func _star(c: Vector2, r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 10:
			var rad: float = r if i % 2 == 0 else r * 0.45
			var a: float = -PI / 2.0 + TAU * float(i) / 10.0
			pts.append(c + Vector2(cos(a), sin(a)) * rad)
		return pts

	func _draw() -> void:
		for i in 3:
			var c := Vector2(size.x / 2.0 + (i - 1) * 100.0, size.y / 2.0)
			draw_colored_polygon(_star(c, 40.0), Color(1, 1, 1, 0.18))
			if i < count:
				var k: float = clamp(progress - float(i), 0.0, 1.0)
				if k > 0.0:
					var s: float = k * (1.0 + 0.3 * sin(k * PI))
					draw_colored_polygon(_star(c, 40.0 * s), Color("#ffd54f"))

# =====================================================
#  Level tile (level select screen)
# =====================================================
class LevelTile extends Control:
	signal tapped(level)
	var level := 1
	var stars := 0
	var locked := false
	var accent := Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(0, 112)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not locked:
				tapped.emit(level)

	func _star(c: Vector2, r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 10:
			var rad: float = r if i % 2 == 0 else r * 0.45
			var a: float = -PI / 2.0 + TAU * float(i) / 10.0
			pts.append(c + Vector2(cos(a), sin(a)) * rad)
		return pts

	func _draw() -> void:
		var sb := StyleBoxFlat.new()
		if locked:
			sb.bg_color = Color(1, 1, 1, 0.07)
		elif stars > 0:
			sb.bg_color = accent
		else:
			sb.bg_color = accent.darkened(0.35)
		sb.set_corner_radius_all(20)
		sb.shadow_color = Color(0, 0, 0, 0.3)
		sb.shadow_size = 5
		sb.shadow_offset = Vector2(0, 3)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		var font: Font = ThemeDB.fallback_font
		if locked:
			# padlock
			var c := Vector2(size.x / 2.0, size.y / 2.0)
			draw_rect(Rect2(c + Vector2(-16, -2), Vector2(32, 26)), Color(1, 1, 1, 0.35))
			draw_arc(c + Vector2(0, -2), 11.0, PI, TAU, 16, Color(1, 1, 1, 0.35), 5.0, true)
			return
		draw_string(font, Vector2(0, size.y * 0.52), str(level), HORIZONTAL_ALIGNMENT_CENTER, size.x, 36, Color.WHITE)
		for i in 3:
			var c := Vector2(size.x / 2.0 + (i - 1) * 28.0, size.y * 0.78)
			draw_colored_polygon(_star(c, 11.0), Color("#ffd54f") if i < stars else Color(0, 0, 0, 0.28))

# =====================================================
#  Card
# =====================================================
class Card extends Control:
	signal clicked(card)
	var id := 0          # item index (0-11) inside the theme
	var theme_id := 0
	var back_col := Color("#5b3cc4")
	var face_up := false
	var matched := false
	var locked := false

	func _init() -> void:
		custom_minimum_size = Vector2(70, 70)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			pivot_offset = size / 2.0

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(self)

	func pop_in(delay: float) -> void:
		scale = Vector2.ZERO
		var t := create_tween()
		t.tween_property(self, "scale", Vector2.ONE, 0.32).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func flip_to(up: bool) -> void:
		locked = true
		var t := create_tween()
		t.tween_property(self, "scale:x", 0.0, 0.11)
		await t.finished
		face_up = up
		queue_redraw()
		var t2 := create_tween()
		t2.tween_property(self, "scale:x", 1.0, 0.11)
		await t2.finished
		locked = false

	func set_matched() -> void:
		matched = true
		queue_redraw()
		var t := create_tween()
		t.tween_property(self, "scale", Vector2(1.1, 1.1), 0.12)
		t.tween_property(self, "scale", Vector2.ONE, 0.14)

	func shake() -> void:
		var t := create_tween()
		t.tween_property(self, "rotation", 0.09, 0.05)
		t.tween_property(self, "rotation", -0.09, 0.08)
		t.tween_property(self, "rotation", 0.0, 0.05)

	func _draw() -> void:
		var bg := back_col
		var border := back_col.lightened(0.3)
		if face_up:
			bg = Color("#fff8e7")
			border = Color("#eadcb4")
		if matched:
			bg = Color("#dff7da")
			border = Color("#5fcf80")
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.border_color = border
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(20)
		sb.shadow_color = Color(0, 0, 0, 0.30)
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(0, 4)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))

		var c := size / 2.0
		var r: float = min(size.x, size.y) * 0.28
		if not face_up:
			var hl := StyleBoxFlat.new()
			hl.bg_color = Color(1, 1, 1, 0.12)
			hl.set_corner_radius_all(16)
			draw_style_box(hl, Rect2(Vector2(8, 8), Vector2(size.x - 16, size.y * 0.42)))
			draw_arc(c, r * 0.95, 0.0, TAU, 40, Color(1, 1, 1, 0.4), 3.0, true)
			var d := PackedVector2Array([c + Vector2(0, -r * 0.5), c + Vector2(r * 0.5, 0), c + Vector2(0, r * 0.5), c + Vector2(-r * 0.5, 0)])
			draw_colored_polygon(d, Color(1, 1, 1, 0.5))
			return
		Art.draw_item(self, theme_id, id, c, r, bg)

# =====================================================
#  State
# =====================================================
var cols := 3
var rows := 4
var current_diff := "Easy"
var current_level := 1
var current_theme := 0
var player: Dictionary = {}
var first = null
var second = null
var busy := false
var moves := 0
var matches := 0
var total_pairs := 0
var combo := 0
var score := 0
var elapsed := 0.0
var running := false
var game_token := 0
var board_diff := "Easy"
var sounds := {}
var music_player: AudioStreamPlayer
var music_thread: Thread
var music_bytes := PackedByteArray()
var bg_grad: Gradient

# UI refs
var menu_root: Control
var levels_root: Control
var game_root: Control
var board_root: Control
var win_root: Control
var name_edit: LineEdit
var grid: GridContainer
var score_label: Label
var moves_label: Label
var time_label: Label
var best_label: Label
var diff_label: Label
var win_panel: PanelContainer
var win_title: Label
var win_stats: Label
var win_record: Label
var star_row: StarRow
var next_btn: Button
var all_done_label: Label
var levels_title: Label
var levels_info: Label
var levels_grid: GridContainer
var board_list: VBoxContainer
var board_stats: Label
var board_tabs: Array = []
var sound_buttons: Array = []
var music_buttons: Array = []

func _ready() -> void:
	randomize()
	_setup_audio()
	_build_background()
	_build_menu()
	_build_levels()
	_build_game()
	_build_board()
	_build_win()
	_show_screen(menu_root)
	_start_music_generation()

func _exit_tree() -> void:
	if music_thread != null and music_thread.is_started():
		music_thread.wait_to_finish()

func _process(delta: float) -> void:
	if running:
		elapsed += delta
		time_label.text = _fmt(elapsed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()

func _go_back() -> void:
	if game_root.visible:
		_open_levels(current_diff)
	elif not menu_root.visible:
		_show_screen(menu_root)

# =====================================================
#  Audio: effects + soft background music (all generated in code)
# =====================================================
func _synth(notes: Array, vol: float = 0.35) -> AudioStreamWAV:
	var rate := 22050
	var total := 0
	for n in notes:
		total += int(rate * float(n[1]))
	var bytes := PackedByteArray()
	bytes.resize(total * 2)
	var pos := 0
	for n in notes:
		var f: float = float(n[0])
		var cnt: int = int(rate * float(n[1]))
		for i in cnt:
			var t: float = float(i) / float(rate)
			var frac: float = float(i) / float(cnt)
			var env: float = min(frac / 0.05, 1.0) * (1.0 - frac)
			var s: float = 0.0
			if f > 0.0:
				s = sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.0 * t)
			var v: int = int(clamp(s * env * vol, -1.0, 1.0) * 32767.0)
			bytes.encode_s16(pos * 2, v)
			pos += 1
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	return w

func _setup_audio() -> void:
	var defs := {
		"click": [[640, 0.05]],
		"flip": [[520, 0.06]],
		"match": [[660, 0.09], [880, 0.16]],
		"miss": [[240, 0.10], [190, 0.16]],
		"win": [[523, 0.12], [659, 0.12], [784, 0.12], [1047, 0.34]],
	}
	for k in defs.keys():
		var p := AudioStreamPlayer.new()
		p.stream = _synth(defs[k])
		add_child(p)
		sounds[k] = p
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -9.0
	add_child(music_player)

func _play(sname: String) -> void:
	if DB.get_setting("sound", true) and sounds.has(sname):
		sounds[sname].play()

func _vibrate(ms: int) -> void:
	if DB.get_setting("vibrate", true):
		Input.vibrate_handheld(ms)

# --- music: a calm 16s music-box loop (Cmaj7 - Am7 - Fmaj7 - G6), built in a thread ---
func _start_music_generation() -> void:
	music_thread = Thread.new()
	music_thread.start(_generate_music)

func _generate_music() -> void:
	var rate := 11025
	var chord_len := 4.0
	var n: int = int(rate * chord_len * 4.0)
	var mix := PackedFloat32Array()
	mix.resize(n)
	# chord tones (Hz): root-position voicings for arpeggio, bass, and slow melody
	var chords := [
		[261.63, 329.63, 392.00, 493.88],
		[220.00, 261.63, 329.63, 392.00],
		[174.61, 220.00, 261.63, 329.63],
		[196.00, 246.94, 293.66, 329.63],
	]
	var bass := [130.81, 110.0, 87.31, 98.0]
	var melody := [[659.25, 783.99], [659.25, 523.25], [698.46, 659.25], [587.33, 659.25]]
	var pattern := [0, 1, 2, 3, 2, 1, 2, 3]
	for ci in 4:
		var t0: float = ci * chord_len
		# arpeggio (plucked, music-box like)
		for step in 8:
			var f: float = float(chords[ci][pattern[step]]) * (2.0 if step % 4 == 3 else 1.0)
			_add_pluck(mix, rate, t0 + step * 0.5, f, 1.8, 0.20)
		# soft bass pad
		_add_pad(mix, rate, t0, float(bass[ci]), chord_len, 0.22)
		# slow melody
		for m in 2:
			_add_pad(mix, rate, t0 + m * 2.0, float(melody[ci][m]), 2.0, 0.09)
	# gentle echo (circular so the loop is seamless)
	var d: int = int(rate * 0.375)
	for i in n:
		mix[i] += 0.30 * mix[(i - d + n) % n]
	# normalise
	var peak := 0.001
	for i in n:
		peak = max(peak, abs(mix[i]))
	var gain: float = 0.55 / peak
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clamp(mix[i] * gain, -1.0, 1.0) * 32767.0))
	music_bytes = bytes
	call_deferred("_music_ready", rate, n)

func _add_pluck(mix: PackedFloat32Array, rate: int, start: float, freq: float, dur: float, vol: float) -> void:
	var n: int = mix.size()
	var cnt: int = int(rate * dur)
	var s0: int = int(start * rate)
	var e1 := 1.0
	var e2 := 1.0
	var d1: float = exp(-2.6 / rate)
	var d2: float = exp(-5.0 / rate)
	var w1: float = TAU * freq / rate
	var w2: float = w1 * 2.0
	for i in cnt:
		var att: float = min(float(i) / 60.0, 1.0)
		mix[(s0 + i) % n] += (sin(w1 * i) * e1 + 0.25 * sin(w2 * i) * e2) * att * vol
		e1 *= d1
		e2 *= d2

func _add_pad(mix: PackedFloat32Array, rate: int, start: float, freq: float, dur: float, vol: float) -> void:
	var n: int = mix.size()
	var cnt: int = int(rate * dur)
	var s0: int = int(start * rate)
	var w1: float = TAU * freq / rate
	for i in cnt:
		var frac: float = float(i) / float(cnt)
		var env: float = min(frac / 0.2, 1.0) * min((1.0 - frac) / 0.35, 1.0)
		mix[(s0 + i) % n] += sin(w1 * i) * env * vol

func _music_ready(rate: int, n: int) -> void:
	music_thread.wait_to_finish()
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = music_bytes
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	music_player.stream = w
	if DB.get_setting("music", true):
		music_player.play()

# =====================================================
#  UI helpers
# =====================================================
func _fmt(t: float) -> String:
	return "%02d:%02d" % [int(t / 60.0), int(t) % 60]

func _label(text: String, font_size: int, col: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _style_button(b: Button, col: Color, radius: int = 26) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		var c := col
		if state == "hover":
			c = col.lightened(0.12)
		elif state == "pressed":
			c = col.darkened(0.15)
		sb.bg_color = c
		sb.set_corner_radius_all(radius)
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(0, 4)
		sb.content_margin_left = 20
		sb.content_margin_right = 20
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for fc in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(fc, Color.WHITE)

func _button(text: String, font_size: int, min_size: Vector2, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.custom_minimum_size = min_size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_button(b, col)
	b.pressed.connect(_play.bind("click"))
	return b

func _screen() -> MarginContainer:
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 56)
	m.add_theme_constant_override("margin_bottom", 32)
	add_child(m)
	return m

func _chip(caption: String) -> Array:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.10)
	sb.set_corner_radius_all(18)
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	v.add_child(_label(caption, 16, Color("#b9b4e8")))
	var val := _label("0", 32)
	v.add_child(val)
	return [p, val]

func _sound_text() -> String:
	return "Sound: ON" if DB.get_setting("sound", true) else "Sound: OFF"

func _music_text() -> String:
	return "Music: ON" if DB.get_setting("music", true) else "Music: OFF"

func _toggle_sound() -> void:
	DB.set_setting("sound", not DB.get_setting("sound", true))
	for b in sound_buttons:
		b.text = _sound_text()

func _toggle_music() -> void:
	var on: bool = not DB.get_setting("music", true)
	DB.set_setting("music", on)
	for b in music_buttons:
		b.text = _music_text()
	if music_player.stream != null:
		if on:
			music_player.play()
		else:
			music_player.stop()

func _set_bg(top: Color, bottom: Color) -> void:
	bg_grad.set_color(0, top)
	bg_grad.set_color(1, bottom)

func _set_bg_default() -> void:
	_set_bg(Color("#1a1446"), Color("#43207a"))

func _show_screen(n: Control) -> void:
	game_token += 1
	running = false
	busy = false
	win_root.visible = false
	menu_root.visible = (n == menu_root)
	levels_root.visible = (n == levels_root)
	game_root.visible = (n == game_root)
	board_root.visible = (n == board_root)
	if n != game_root:
		_set_bg_default()

# =====================================================
#  Build screens
# =====================================================
func _build_background() -> void:
	bg_grad = Gradient.new()
	var tex := GradientTexture2D.new()
	tex.gradient = bg_grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 256
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	_set_bg_default()
	var b := Bubbles.new()
	b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(b)

func _build_menu() -> void:
	menu_root = _screen()
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 18)
	menu_root.add_child(vb)

	# decorative cards, one from each theme
	var deco := HBoxContainer.new()
	deco.alignment = BoxContainer.ALIGNMENT_CENTER
	deco.add_theme_constant_override("separation", 12)
	vb.add_child(deco)
	var deco_themes := [0, 1, 2, 3, 4]
	var deco_items := [0, 3, 0, 0, 6]
	for i in deco_themes.size():
		var c := Card.new()
		c.theme_id = deco_themes[i]
		c.id = deco_items[i]
		c.face_up = true
		c.custom_minimum_size = Vector2(100, 100)
		c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		deco.add_child(c)
		var t := c.create_tween().set_loops()
		t.tween_property(c, "rotation", 0.12, 0.9 + i * 0.12).set_trans(Tween.TRANS_SINE)
		t.tween_property(c, "rotation", -0.12, 0.9 + i * 0.12).set_trans(Tween.TRANS_SINE)

	var title := _label("MEMORY MATCH", 64, Color("#ffd54f"))
	vb.add_child(title)
	title.resized.connect(func(): title.pivot_offset = title.size / 2.0)
	var tt := title.create_tween().set_loops()
	tt.tween_property(title, "scale", Vector2(1.04, 1.04), 1.2).set_trans(Tween.TRANS_SINE)
	tt.tween_property(title, "scale", Vector2.ONE, 1.2).set_trans(Tween.TRANS_SINE)
	vb.add_child(_label("150 levels  |  fruits, players, animals & more", 20, Color("#c9c4f5")))

	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Enter your name"
	name_edit.max_length = 14
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_edit.custom_minimum_size = Vector2(0, 70)
	name_edit.text = String(DB.get_setting("last_player", ""))
	name_edit.add_theme_font_size_override("font_size", 28)
	name_edit.add_theme_color_override("font_color", Color.WHITE)
	name_edit.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.45))
	name_edit.add_theme_color_override("caret_color", Color("#ffd54f"))
	var nsb := StyleBoxFlat.new()
	nsb.bg_color = Color(1, 1, 1, 0.12)
	nsb.set_corner_radius_all(22)
	nsb.set_border_width_all(2)
	nsb.border_color = Color(1, 1, 1, 0.25)
	name_edit.add_theme_stylebox_override("normal", nsb)
	var nsb2 := nsb.duplicate()
	nsb2.border_color = Color("#ffd54f")
	name_edit.add_theme_stylebox_override("focus", nsb2)
	vb.add_child(name_edit)

	for d in ["Easy", "Medium", "Hard"]:
		var info: Dictionary = diffs[d]
		var b := _button("%s  -  %d levels" % [d, MAX_LEVEL], 30, Vector2(0, 84), info["color"])
		b.pressed.connect(_open_levels.bind(d))
		vb.add_child(b)

	var lb := _button("Leaderboard", 24, Vector2(0, 68), Color("#6c4be0"))
	lb.pressed.connect(func(): _open_board("Easy"))
	vb.add_child(lb)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	vb.add_child(row)
	var sb := _button(_sound_text(), 22, Vector2(0, 62), Color("#3d3a8f"))
	sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sb.pressed.connect(_toggle_sound)
	sound_buttons.append(sb)
	row.add_child(sb)
	var mb := _button(_music_text(), 22, Vector2(0, 62), Color("#3d3a8f"))
	mb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mb.pressed.connect(_toggle_music)
	music_buttons.append(mb)
	row.add_child(mb)

	vb.add_child(_label(CREDIT, 24, Color("#ffcc80")))

func _build_levels() -> void:
	levels_root = _screen()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	levels_root.add_child(vb)
	levels_title = _label("Easy - Levels", 46, Color("#ffd54f"))
	vb.add_child(levels_title)
	levels_info = _label("", 20, Color("#c9c4f5"))
	vb.add_child(levels_info)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	levels_grid = GridContainer.new()
	levels_grid.columns = 5
	levels_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	levels_grid.add_theme_constant_override("h_separation", 12)
	levels_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(levels_grid)
	var back := _button("Back", 28, Vector2(0, 72), Color("#6c4be0"))
	back.pressed.connect(func(): _show_screen(menu_root))
	vb.add_child(back)
	vb.add_child(_label(CREDIT, 18, Color("#9d96d8")))

func _build_game() -> void:
	game_root = _screen()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	game_root.add_child(vb)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	vb.add_child(top)
	var back := _button("< Levels", 22, Vector2(140, 54), Color("#3d3a8f"))
	back.pressed.connect(func(): _open_levels(current_diff))
	top.add_child(back)
	diff_label = _label("Easy", 30, Color("#ffd54f"))
	diff_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(diff_label)
	var sb := _button(_sound_text(), 20, Vector2(150, 54), Color("#3d3a8f"))
	sb.pressed.connect(_toggle_sound)
	sound_buttons.append(sb)
	top.add_child(sb)

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 10)
	vb.add_child(chips)
	var c1 := _chip("SCORE")
	var c2 := _chip("MOVES")
	var c3 := _chip("TIME")
	chips.add_child(c1[0])
	chips.add_child(c2[0])
	chips.add_child(c3[0])
	score_label = c1[1]
	moves_label = c2[1]
	time_label = c3[1]

	best_label = _label("", 20, Color("#ffe082"))
	vb.add_child(best_label)

	grid = GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	vb.add_child(grid)

	vb.add_child(_label(CREDIT, 18, Color("#9d96d8")))

func _build_board() -> void:
	board_root = _screen()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	board_root.add_child(vb)
	vb.add_child(_label("LEADERBOARD", 46, Color("#ffd54f")))

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	vb.add_child(tabs)
	for d in ["Easy", "Medium", "Hard"]:
		var b := _button(d, 24, Vector2(0, 62), Color("#3d3a8f"))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): _open_board(d))
		tabs.add_child(b)
		board_tabs.append(b)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	board_list = VBoxContainer.new()
	board_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_list.add_theme_constant_override("separation", 10)
	scroll.add_child(board_list)

	board_stats = _label("", 20, Color("#c9c4f5"))
	vb.add_child(board_stats)
	var back := _button("Back", 28, Vector2(0, 72), Color("#6c4be0"))
	back.pressed.connect(func(): _show_screen(menu_root))
	vb.add_child(back)
	vb.add_child(_label(CREDIT, 18, Color("#9d96d8")))

func _build_win() -> void:
	win_root = Control.new()
	win_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(win_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	win_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	win_root.add_child(center)
	win_panel = PanelContainer.new()
	win_panel.custom_minimum_size = Vector2(600, 0)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color("#2a1f5e")
	psb.set_corner_radius_all(36)
	psb.set_border_width_all(3)
	psb.border_color = Color("#8f74f0")
	psb.content_margin_left = 32
	psb.content_margin_right = 32
	psb.content_margin_top = 28
	psb.content_margin_bottom = 24
	win_panel.add_theme_stylebox_override("panel", psb)
	center.add_child(win_panel)
	win_panel.resized.connect(func(): win_panel.pivot_offset = win_panel.size / 2.0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	win_panel.add_child(vb)
	win_title = _label("LEVEL COMPLETE!", 46, Color("#ffd54f"))
	vb.add_child(win_title)
	star_row = StarRow.new()
	vb.add_child(star_row)
	win_stats = _label("", 28)
	vb.add_child(win_stats)
	win_record = _label("NEW RECORD!", 30, Color("#7dffb0"))
	vb.add_child(win_record)
	next_btn = _button("Next Level  >", 32, Vector2(0, 84), Color("#2fbf8f"))
	next_btn.pressed.connect(func(): _start_level(current_level + 1))
	vb.add_child(next_btn)
	all_done_label = _label("You finished every level!", 26, Color("#7dffb0"))
	vb.add_child(all_done_label)
	var again := _button("Replay", 26, Vector2(0, 66), Color("#6c4be0"))
	again.pressed.connect(func(): _start_level(current_level))
	vb.add_child(again)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)
	var lv := _button("Levels", 24, Vector2(0, 62), Color("#3d3a8f"))
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.pressed.connect(func(): _open_levels(current_diff))
	row.add_child(lv)
	var mn := _button("Menu", 24, Vector2(0, 62), Color("#3d3a8f"))
	mn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mn.pressed.connect(func(): _show_screen(menu_root))
	row.add_child(mn)
	vb.add_child(_label(CREDIT, 20, Color("#ffcc80")))
	win_root.visible = false

# =====================================================
#  Level select
# =====================================================
func _ensure_player() -> void:
	var pname := name_edit.text.strip_edges()
	if pname == "":
		pname = "Player"
		name_edit.text = pname
	player = DB.get_or_create_player(pname)
	DB.set_setting("last_player", pname)

func _open_levels(diff: String) -> void:
	_ensure_player()
	current_diff = diff
	_show_screen(levels_root)
	levels_title.text = "%s - Levels" % diff
	for c in levels_grid.get_children():
		levels_grid.remove_child(c)
		c.queue_free()
	var pid := int(player["id"])
	var unlocked := DB.unlocked_level(pid, diff, MAX_LEVEL)
	var total := 0
	var accent: Color = diffs[diff]["color"]
	for lv in range(1, MAX_LEVEL + 1):
		var tile := LevelTile.new()
		tile.level = lv
		tile.stars = DB.level_stars(pid, diff, lv)
		tile.locked = lv > unlocked
		tile.accent = accent
		tile.tapped.connect(_start_level)
		total += tile.stars
		levels_grid.add_child(tile)
	levels_info.text = "%s   |   Stars: %d / %d   |   Unlocked: %d / %d" % [player["name"], total, MAX_LEVEL * 3, unlocked, MAX_LEVEL]

# =====================================================
#  Leaderboard
# =====================================================
func _open_board(diff: String) -> void:
	board_diff = diff
	_show_screen(board_root)
	var names := ["Easy", "Medium", "Hard"]
	for i in board_tabs.size():
		var col: Color = diffs[names[i]]["color"] if names[i] == diff else Color("#3d3a8f")
		_style_button(board_tabs[i], col)
	for c in board_list.get_children():
		board_list.remove_child(c)
		c.queue_free()
	var rows_data := DB.leaderboard(diff, 10)
	if rows_data.is_empty():
		var empty := _label("No games yet.\nFinish a level to get on the board!", 26, Color("#b9b4e8"))
		empty.custom_minimum_size = Vector2(0, 160)
		board_list.add_child(empty)
	var me := name_edit.text.strip_edges().to_lower()
	var medals := [Color("#ffd54f"), Color("#d5dbe6"), Color("#e0a068")]
	var rank := 0
	for r in rows_data:
		rank += 1
		var p := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		var mine: bool = String(r["name"]).to_lower() == me
		sb.bg_color = Color(1, 1, 1, 0.22) if mine else Color(1, 1, 1, 0.09)
		sb.set_corner_radius_all(18)
		sb.content_margin_left = 18
		sb.content_margin_right = 18
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		p.add_theme_stylebox_override("panel", sb)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		p.add_child(h)
		var rc: Color = medals[rank - 1] if rank <= 3 else Color("#b9b4e8")
		var rl := _label("#%d" % rank, 30, rc)
		rl.custom_minimum_size = Vector2(70, 0)
		h.add_child(rl)
		var mid := VBoxContainer.new()
		mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mid.add_theme_constant_override("separation", 0)
		var nl := _label(String(r["name"]), 26)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		mid.add_child(nl)
		var dl := _label("Levels %d/%d  |  %d pts" % [r["levels"], MAX_LEVEL, r["score"]], 16, Color("#b9b4e8"))
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		mid.add_child(dl)
		h.add_child(mid)
		h.add_child(_label("%d stars" % r["stars"], 26, rc))
		board_list.add_child(p)
	var pl := DB.find_player(name_edit.text)
	if pl.is_empty():
		board_stats.text = ""
	else:
		var st := DB.player_stats(int(pl["id"]))
		board_stats.text = "%s  |  Levels done: %d  |  Stars: %d  |  Best: %d" % [pl["name"], st["levels"], st["stars"], st["best"]]

# =====================================================
#  Game flow
# =====================================================
func _start_level(level: int) -> void:
	_ensure_player()
	_show_screen(game_root)
	var token := game_token
	var diff := current_diff
	var info: Dictionary = diffs[diff]
	current_level = level
	var tier: int = clampi(floori((level - 1) / 10.0), 0, 4)
	var dims: Array = info["tiers"][tier]
	cols = dims[0]
	rows = dims[1]
	current_theme = (level - 1 + int(info["offset"])) % Art.THEME_COUNT
	var bgc := Art.theme_bg(current_theme)
	_set_bg(bgc[0], bgc[1])

	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()
	grid.columns = cols
	total_pairs = cols * rows / 2
	var pool: Array = range(Art.ITEM_COUNT)
	pool.shuffle()
	var ids: Array = []
	for i in total_pairs:
		ids.append(pool[i])
		ids.append(pool[i])
	ids.shuffle()
	for id in ids:
		var card := Card.new()
		card.id = id
		card.theme_id = current_theme
		card.back_col = Art.theme_accent(current_theme)
		card.clicked.connect(_on_card_clicked)
		grid.add_child(card)
	for i in grid.get_child_count():
		grid.get_child(i).pop_in(i * 0.03)

	first = null
	second = null
	moves = 0
	matches = 0
	combo = 0
	score = 0
	elapsed = 0.0
	running = false
	busy = true
	diff_label.text = "%s  Lv %d" % [diff, level]
	var best := DB.level_best(int(player["id"]), diff, level)
	best_label.text = "%s   |   Best: %s" % [Art.theme_name(current_theme), str(best) if best > 0 else "-"]
	_update_hud()
	time_label.text = "00:00"
	_popup("Level %d - %s" % [level, Art.theme_name(current_theme)], Color("#ffd54f"))

	# preview so the player can memorise the cards (gets shorter on higher levels)
	var preview: float = max(float(info["pre_min"]), float(info["pre"]) - float(level - 1) * 0.03)
	await get_tree().create_timer(0.35 + grid.get_child_count() * 0.03 + 0.35).timeout
	if token != game_token:
		return
	for c in grid.get_children():
		c.flip_to(true)
	await get_tree().create_timer(0.3 + preview).timeout
	if token != game_token:
		return
	for c in grid.get_children():
		c.flip_to(false)
	await get_tree().create_timer(0.4).timeout
	if token != game_token:
		return
	busy = false

func _update_hud() -> void:
	score_label.text = str(score)
	moves_label.text = str(moves)

func _popup(text: String, col: Color) -> void:
	var l := _label(text, 40, col)
	l.custom_minimum_size = Vector2(600, 0)
	l.position = Vector2(size.x / 2.0 - 300.0, 260.0)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", 8)
	add_child(l)
	var t := l.create_tween()
	t.set_parallel(true)
	t.tween_property(l, "position:y", 190.0, 1.1)
	t.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.5)
	t.chain().tween_callback(l.queue_free)

func _on_card_clicked(card) -> void:
	if busy or card.face_up or card.matched or card.locked:
		return
	running = true
	_play("flip")
	card.flip_to(true)
	if first == null:
		first = card
		return
	second = card
	busy = true
	moves += 1
	_update_hud()
	var token := game_token
	await get_tree().create_timer(0.6).timeout
	if token != game_token:
		return
	if first.id == second.id:
		combo += 1
		var gain: int = 100 + (combo - 1) * 50
		score += gain
		first.set_matched()
		second.set_matched()
		matches += 1
		_play("match")
		_popup("+%d" % gain if combo < 2 else "Combo x%d!  +%d" % [combo, gain], Color("#7dffb0"))
		first = null
		second = null
		_update_hud()
		busy = false
		if matches == total_pairs:
			_win()
	else:
		combo = 0
		score = max(0, score - 10)
		_play("miss")
		_vibrate(30)
		first.shake()
		second.shake()
		first.flip_to(false)
		second.flip_to(false)
		first = null
		second = null
		_update_hud()
		busy = false

func _win() -> void:
	running = false
	busy = true
	var token := game_token
	var info: Dictionary = diffs[current_diff]
	var par_time: float = total_pairs * float(info["par"])
	score += int(max(0.0, par_time - elapsed)) * 5
	var stars := 1
	if moves <= int(total_pairs * 1.5):
		stars = 3
	elif moves <= int(total_pairs * 2.2):
		stars = 2
	var pid := int(player["id"])
	var record := DB.set_level_result(pid, current_diff, current_level, stars, score)
	DB.add_game(pid, current_diff, current_level, moves, elapsed, score, stars)
	_update_hud()
	win_title.text = "LEVEL %d COMPLETE!" % current_level
	win_stats.text = "Score: %d\nMoves: %d    Time: %s" % [score, moves, _fmt(elapsed)]
	win_record.visible = record
	var last: bool = current_level >= MAX_LEVEL
	next_btn.visible = not last
	all_done_label.visible = last
	_play("win")
	await get_tree().create_timer(0.7).timeout
	if token != game_token:
		return
	win_root.visible = true
	win_panel.scale = Vector2(0.6, 0.6)
	var t := win_panel.create_tween()
	t.tween_property(win_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	star_row.animate(stars)
	_confetti()

func _confetti() -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(size.x / 2.0, -20.0)
	p.amount = 120
	p.lifetime = 3.2
	p.one_shot = true
	p.explosiveness = 0.2
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(size.x / 2.0, 10.0)
	p.direction = Vector2(0, 1)
	p.spread = 25.0
	p.gravity = Vector2(0, 320)
	p.initial_velocity_min = 150.0
	p.initial_velocity_max = 420.0
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.scale_amount_min = 7.0
	p.scale_amount_max = 14.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	g.colors = PackedColorArray([Color("#ffd54f"), Color("#ef476f"), Color("#2fbf8f"), Color("#4a90e2"), Color("#ec5fa5")])
	p.color_initial_ramp = g
	add_child(p)
	p.emitting = true
	get_tree().create_timer(4.5).timeout.connect(p.queue_free)
