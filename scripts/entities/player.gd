## Elias - the playable student.
## Three-lane movement, jump, slide, dash, 3 hearts, 1.5s i-frames,
## hitbox 10% smaller than the sprite (GDD Section II / VI).
class_name Player
extends CharacterBody2D

signal lane_changed(lane: int)
signal jumped
signal slid
signal dashed
signal hit_taken(hearts_left: int)
signal defeated
signal item_picked(kind: String, world_position: Vector2)
signal coin_picked(value: int, world_position: Vector2)

@export var lane: int = 1
@export var max_hearts: int = GameConfig.MAX_HEARTS

var hearts: int = GameConfig.MAX_HEARTS
var invuln_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown: float = 0.0
var slide_timer: float = 0.0
var jump_height: float = 0.0
var jump_speed: float = 0.0
var airborne: bool = false
var sliding: bool = false
var defeated_state: bool = false
var input_enabled: bool = true
var can_control: bool = true
var speed_ref: float = 430.0

var _run_phase: float = 0.0
var _bob: float = 0.0
var _hurt_flash: float = 0.0
var _lane_tween: Tween
var _shape: RectangleShape2D
var _hitbox: Area2D
var _hitbox_shape: CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	add_to_group("player")
	_hitbox = $Hitbox
	_hitbox_shape = $Hitbox/CollisionShape2D
	_shape = RectangleShape2D.new()
	_shape.size = GameConfig.HITBOX_SIZE * GameConfig.HITBOX_SCALE
	_hitbox_shape.shape = _shape
	_hitbox.collision_layer = 1
	_hitbox.collision_mask = 2 | 4
	_hitbox.monitoring = true
	_hitbox.monitorable = true
	_hitbox.area_entered.connect(_on_hitbox_area_entered)
	position.y = GameConfig.lane_y(lane)
	hitbox_updated()
	_update_sprite()
	queue_redraw()


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	_update_jump(delta)
	_update_slide(delta)
	_run_phase += delta * (speed_ref / 92.0)
	_bob = sin(_run_phase * 2.0) * 3.0 if not airborne else 0.0
	if _hurt_flash > 0.0:
		_hurt_flash = maxf(0.0, _hurt_flash - delta)
	if invuln_timer > 0.0 and not defeated_state:
		modulate.a = 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.02))
	else:
		modulate.a = 1.0
	position.x = GameConfig.PLAYER_X
	hitbox_updated()
	_update_sprite()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or not can_control or defeated_state:
		return
	if get_tree().paused:
		return
	if event.is_action_pressed("lane_up"):
		move_lane(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("lane_down"):
		move_lane(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("jump"):
		try_jump()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("slide"):
		try_slide()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dash"):
		try_dash()
		get_viewport().set_input_as_handled()


# --- Movement ---------------------------------------------------------------

func move_lane(direction: int) -> bool:
	if not can_control or defeated_state:
		return false
	var next_lane: int = GameConfig.clamp_lane(lane + direction)
	if next_lane == lane:
		return false
	lane = next_lane
	if _lane_tween != null and _lane_tween.is_valid():
		_lane_tween.kill()
	_lane_tween = create_tween()
	_lane_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_lane_tween.tween_property(self, "position:y", GameConfig.lane_y(lane), GameConfig.LANE_SWITCH_TIME)
	lane_changed.emit(lane)
	AudioDirector.play_sfx("lane")
	hitbox_updated()
	return true


func try_jump() -> bool:
	if not can_control or defeated_state or airborne or sliding:
		return false
	airborne = true
	jump_speed = GameConfig.JUMP_VELOCITY
	jump_height = 1.0
	jumped.emit()
	AudioDirector.play_sfx("jump")
	hitbox_updated()
	return true


func try_slide() -> bool:
	if not can_control or defeated_state or airborne:
		return false
	if sliding:
		return false
	sliding = true
	slide_timer = GameConfig.SLIDE_TIME
	slid.emit()
	AudioDirector.play_sfx("slide")
	hitbox_updated()
	return true


func try_dash() -> bool:
	if not can_control or defeated_state:
		return false
	if dash_cooldown > 0.0 or dash_timer > 0.0:
		return false
	dash_timer = GameConfig.DASH_TIME
	dash_cooldown = SaveManager.shop_dash_cooldown()
	invuln_timer = maxf(invuln_timer, GameConfig.DASH_TIME)
	dashed.emit()
	AudioDirector.play_sfx("dash")
	return true


func is_invulnerable() -> bool:
	return invuln_timer > 0.0 or dash_timer > 0.0 or defeated_state


func is_dashing() -> bool:
	return dash_timer > 0.0


func get_dash_ratio() -> float:
	if dash_timer > 0.0:
		return 1.0
	return 1.0 - clampf(dash_cooldown / GameConfig.DASH_COOLDOWN, 0.0, 1.0)


# --- Damage -----------------------------------------------------------------

## Applies one damaging collision. Returns true when the hit landed.
func take_hit() -> bool:
	if defeated_state or is_invulnerable():
		return false
	hearts = maxi(0, hearts - 1)
	invuln_timer = GameConfig.INVULN_TIME
	_hurt_flash = 0.3
	sliding = false
	slide_timer = 0.0
	if hearts <= 0:
		defeated_state = true
		defeated.emit()
	else:
		hit_taken.emit(hearts)
	AudioDirector.play_sfx("hurt")
	hitbox_updated()
	return true


func reset_for_run() -> void:
	hearts = max_hearts
	invuln_timer = 0.0
	dash_timer = 0.0
	dash_cooldown = 0.0
	slide_timer = 0.0
	jump_height = 0.0
	jump_speed = 0.0
	airborne = false
	sliding = false
	defeated_state = false
	lane = 1
	position.y = GameConfig.lane_y(lane)
	modulate.a = 1.0
	hitbox_updated()
	_update_sprite()
	queue_redraw()


# --- Collisions -------------------------------------------------------------

func hitbox_updated() -> void:
	if _hitbox == null:
		return
	var size := GameConfig.HITBOX_SIZE * GameConfig.HITBOX_SCALE
	# The Area2D stays at the feet; the CollisionShape2D carries the offset so
	# the effective hitbox is exactly one body tall (or one crouched body).
	_hitbox.position = Vector2.ZERO
	if sliding:
		size.y *= 0.45
		_hitbox_shape.position = Vector2(0.0, -24.0 - jump_height)
	else:
		_hitbox_shape.position = Vector2(0.0, -52.0 - jump_height)
	_shape.size = size


func get_hitbox_rect() -> Rect2:
	var size := _shape.size if _shape != null else GameConfig.HITBOX_SIZE * GameConfig.HITBOX_SCALE
	var center := global_position + _hitbox_shape.position
	return Rect2(center - size * 0.5, size)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area == null:
		return
	if area.has_method("is_coin") and area.is_coin():
		if int(area.lane) == lane:
			coin_picked.emit(int(area.value), area.global_position)
			area.collect()
		return
	if not area.has_method("is_hazard") and not area.has_method("is_collectible"):
		return
	if area.has_method("is_collectible") and area.is_collectible():
		item_picked.emit(area.kind, area.global_position)
		area.collect()
		return
	if area.has_method("is_hazard") and area.is_hazard():
		var hazard := area as Hazard
		if hazard == null or hazard.lane != lane:
			return
		if take_hit():
			hazard.on_player_hit()


func _tick_timers(delta: float) -> void:
	invuln_timer = maxf(0.0, invuln_timer - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)


func _update_jump(delta: float) -> void:
	if not airborne:
		return
	jump_height += jump_speed * delta
	jump_speed -= GameConfig.GRAVITY * delta
	if jump_height <= 0.0 and jump_speed < 0.0:
		jump_height = 0.0
		jump_speed = 0.0
		airborne = false


func _update_slide(delta: float) -> void:
	if not sliding:
		return
	slide_timer -= delta
	if slide_timer <= 0.0:
		sliding = false
		slide_timer = 0.0


# --- Character presentation -------------------------------------------------

func _update_sprite() -> void:
	if _sprite == null:
		return
	var row := 2
	var frame := int(floor(_run_phase * 1.8)) % 6
	if defeated_state:
		row = 6
		frame = 5
	elif sliding:
		row = 6
		frame = int(floor(_run_phase * 1.4)) % 6
	elif airborne:
		row = 4
		frame = 2
	elif _hurt_flash > 0.0:
		row = 4
		frame = 0
	_sprite.frame = row * 6 + frame
	_sprite.position = Vector2(0.0, -50.0 - jump_height + _bob)
	_sprite.modulate = Color(1.0, 0.45, 0.45) if _hurt_flash > 0.0 else Color.WHITE

func _draw() -> void:
	# Ground shadow (stays on the lane).
	var shadow_alpha := clampf(1.0 - jump_height / 220.0, 0.15, 0.55)
	draw_circle(Vector2(0, 4), 34.0, Color(0.05, 0.04, 0.1, shadow_alpha * 0.6))
	draw_rect(Rect2(-34, 0, 68, 10), Color(0.05, 0.04, 0.1, shadow_alpha * 0.5))

	var y := -jump_height + _bob
	if is_dashing():
		_draw_dash_streaks(y)
	if invuln_timer > 0.0 and not is_dashing():
		draw_arc(Vector2(0, y - 58), 62.0, 0.0, TAU, 28, Color(0.75, 0.95, 1.0, 0.55), 4.0)


func _draw_dash_streaks(y: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for i in 7:
		var offset := fmod(t * 900.0 + i * 137.0, 420.0)
		var line_y := y - 20.0 - fmod(i * 53.0, 96.0)
		var alpha := 0.35 * (1.0 - offset / 420.0)
		draw_rect(Rect2(-offset - 40.0, line_y, 70.0, 4.0), Color(0.7, 0.95, 1.0, alpha))
