## Opening cutscene (GDD Section III - Cut scene #1): wake up > look at the
## clock > realize he is late > dash out of the door. Skippable.
class_name Cutscene
extends Node2D

signal finished

const DURATION := 8.2
const BACKGROUND_TEXTURE := preload("res://assets/backgrounds/opening_bedroom.png")
const BED_SLEEP_POSITION := Vector2(560, 470)
const BED_EXIT_POSITION := Vector2(760, 810)

var _time: float = 0.0
var _finished: bool = false
var _sfx_fired: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioDirector.stop_music(0.4)
	set_process(true)
	AudioDirector.play_sfx("click")


func _process(delta: float) -> void:
	_time += delta
	_queue_cues()
	queue_redraw()
	if _time >= DURATION:
		_finish()


func _input(event: InputEvent) -> void:
	if _finished:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		_finish()


func _queue_cues() -> void:
	if _time > 1.5 and not _sfx_fired.has("alarm"):
		_sfx_fired["alarm"] = true
		AudioDirector.play_sfx("bell")
	if _time > 4.9 and not _sfx_fired.has("dash"):
		_sfx_fired["dash"] = true
		AudioDirector.play_sfx("dash")
	if _time > 6.6 and not _sfx_fired.has("bell"):
		_sfx_fired["bell"] = true
		AudioDirector.play_sfx("bell")


func _finish() -> void:
	if _finished:
		return
	_finished = true
	finished.emit()


func _draw() -> void:
	var fade := 1.0
	if _time > 7.2:
		fade = clampf(1.0 - (_time - 7.2) / 0.9, 0.0, 1.0)
	var dim := Color(1, 1, 1, fade)
	_draw_background(dim)
	draw_rect(Rect2(0, 0, 1920, 170), Color(0.02, 0.03, 0.08, 0.18 * fade))
	draw_rect(Rect2(0, 820, 1920, 260), Color(0.02, 0.03, 0.08, 0.24 * fade))
	_draw_clock(Vector2(1155, 700), dim)
	_draw_character(dim)
	# Captions.
	var caption := ""
	var caption_color := Color("#ffd166")
	if _time < 1.4:
		caption = "ZZZ..."
		caption_color = Color("#9fb3d9")
	elif _time < 2.3:
		caption = "RING! RING! RING!"
		caption_color = Color("#ff5a4f")
	elif _time < 3.4:
		caption = "8:45?!"
		caption_color = Color("#ff5a4f")
	elif _time < 4.8:
		caption = "I'M LATE!"
		caption_color = Color("#ffd166")
	elif _time < 6.4:
		caption = "GO GO GO!"
		caption_color = Color("#7cf29c")
	else:
		caption = "SCHOOL RUSH"
		caption_color = Color("#7fe7ff")
	_draw_text_centered(caption, Rect2(0, 880, 1920, 90), 64, Color(caption_color.r, caption_color.g, caption_color.b, fade))
	# Skip hint.
	var hint_alpha := clampf(1.0 - _time / 1.2, 0.0, 0.55) * fade
	_draw_text_centered("SPACE / ESC  SKIP", Rect2(0, 1010, 1920, 40), 22, Color(1, 1, 1, hint_alpha))
	# "!" alert bubble.
	if _time > 2.3 and _time < 4.8:
		var bounce := absf(sin(_time * 8.0)) * 14.0
		draw_circle(Vector2(880, 380 - bounce), 44.0, Color("#171325"))
		draw_circle(Vector2(880, 380 - bounce), 36.0, Color("#ff5a4f"))
		draw_rect(Rect2(872, 348 - bounce, 16, 36), Color("#fff5f2"))
		draw_circle(Vector2(880, 398 - bounce), 8.0, Color("#fff5f2"))


func _draw_background(modulate: Color) -> void:
	var target := Vector2(1920, 1080)
	var source_size := BACKGROUND_TEXTURE.get_size()
	var target_ratio := target.x / target.y
	var source_ratio := source_size.x / source_size.y
	var source_rect := Rect2(Vector2.ZERO, source_size)
	if source_ratio > target_ratio:
		var cropped_width := source_size.y * target_ratio
		source_rect.position.x = (source_size.x - cropped_width) * 0.5
		source_rect.size.x = cropped_width
	elif source_ratio < target_ratio:
		var cropped_height := source_size.x / target_ratio
		source_rect.position.y = (source_size.y - cropped_height) * 0.5
		source_rect.size.y = cropped_height
	draw_texture_rect_region(BACKGROUND_TEXTURE, Rect2(Vector2.ZERO, target), source_rect, modulate)


func _draw_clock(pos: Vector2, dim: Color) -> void:
	var shake := 0.0
	if _time > 1.4 and _time < 2.6:
		shake = sin(_time * 60.0) * 4.0
	var center := pos + Vector2(0, -34 + shake)
	draw_circle(center, 38.0, Color("#171325") * dim)
	draw_circle(center, 32.0, Color("#f6f8ff") * dim)
	draw_line(center, center + Vector2(-16, -18), Color("#171325") * dim, 4.0)
	draw_line(center, center + Vector2(18, -6), Color("#e8453c") * dim, 4.0)
	draw_circle(center, 4.0, Color("#171325") * dim)
	draw_rect(Rect2(center.x - 30, center.y + 34, 60, 12), Color("#171325") * dim)


func _draw_character(dim: Color) -> void:
	var t := _time
	var base := BED_EXIT_POSITION
	var sitting := t > 2.3
	var running := t > 4.8
	var alpha: float = dim.a
	if running:
		var run_progress := clampf((t - 4.8) / 1.8, 0.0, 1.0)
		base = Vector2(BED_EXIT_POSITION.x + run_progress * 900.0, BED_EXIT_POSITION.y)
		var bob := sin(t * 22.0) * 8.0
		base.y += bob
		# Motion lines.
		for i in 5:
			draw_rect(
				Rect2(base.x - 120.0 - float(i) * 60.0, base.y - 150.0 + float(i) * 26.0, 90, 5),
				Color(1, 1, 1, 0.22 * alpha)
			)
	if not sitting:
		# Sleeping: blanket + head on pillow.
		draw_rect(Rect2(BED_SLEEP_POSITION + Vector2(-30, 0), Vector2(330, 80)), Color("#5d8fd6") * alpha)
		draw_circle(BED_SLEEP_POSITION + Vector2(-60, -30), 44.0, Color("#171325") * alpha)
		draw_circle(BED_SLEEP_POSITION + Vector2(-60, -30), 38.0, Color("#ffcda3") * alpha)
		draw_rect(Rect2(BED_SLEEP_POSITION + Vector2(-98, -70), Vector2(76, 26)), Color("#37241a") * alpha)
		for i in 3:
			var zz := fposmod(t * 40.0 + float(i) * 26.0, 90.0)
			_draw_text_at("Z", BED_SLEEP_POSITION + Vector2(-40 + zz * 0.8, -80 - zz), 26 + i * 6, Color(1, 1, 1, 0.7 * alpha))
		return
	# Sitting / running character.
	var leg_swing := sin(t * 22.0) * 30.0 if running else 0.0
	var hip := base + Vector2(0, -96)
	draw_line(hip, hip + Vector2(-14 + leg_swing, 96), Color("#1d2740") * alpha, 20.0, true)
	draw_line(hip, hip + Vector2(14 - leg_swing, 96), Color("#1d2740") * alpha, 20.0, true)
	draw_rect(Rect2(hip.x - 26, hip.y - 66, 52, 70), Color("#f6f8ff") * alpha)
	draw_rect(Rect2(hip.x - 26, hip.y - 66, 16, 56), Color("#2f6fd0") * alpha)
	draw_rect(Rect2(hip.x + 10, hip.y - 66, 16, 56), Color("#2f6fd0") * alpha)
	draw_rect(Rect2(hip.x - 46, hip.y - 62, 22, 46), Color("#f0b429") * alpha)
	draw_line(hip + Vector2(-20, -56), hip + Vector2(-40 - leg_swing * 0.6, -10), Color("#2f6fd0") * alpha, 12.0, true)
	draw_line(hip + Vector2(20, -56), hip + Vector2(40 + leg_swing * 0.6, -10), Color("#2f6fd0") * alpha, 12.0, true)
	draw_circle(hip + Vector2(0, -92), 30.0, Color("#171325") * alpha)
	draw_circle(hip + Vector2(0, -92), 26.0, Color("#ffcda3") * alpha)
	draw_rect(Rect2(hip.x - 26, hip.y - 124, 52, 16), Color("#37241a") * alpha)
	draw_rect(Rect2(hip.x + 8, hip.y - 94, 6, 8), Color("#171325") * alpha)
	draw_rect(Rect2(hip.x - 14, hip.y - 94, 6, 8), Color("#171325") * alpha)
	if _time > 3.4 and _time < 4.8:
		draw_rect(Rect2(hip.x - 14, hip.y - 82, 28, 5), Color("#171325") * alpha)


func _draw_text_centered(text: String, rect: Rect2, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, rect.position + Vector2(4, rect.size.y * 0.5 + size * 0.35 + 4), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, Color(0, 0, 0, color.a * 0.7))
	draw_string(font, rect.position + Vector2(0, rect.size.y * 0.5 + size * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, color)


func _draw_text_at(text: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
