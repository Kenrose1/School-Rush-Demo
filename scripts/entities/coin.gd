## Fixed-value shop currency pickup.
class_name Coin
extends Area2D

const NORMAL_VALUE := 10
const RARE_VALUE := 50

@export var value: int = NORMAL_VALUE
@export var lane: int = 1

var collected: bool = false
var _phase: float = 0.0
var _base_y: float


func _ready() -> void:
	add_to_group("coins")
	add_to_group("scrolling")
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = true
	_base_y = GameConfig.lane_y(lane) - 74.0
	position.y = _base_y
	_phase = randf() * TAU
	var shape := CircleShape2D.new()
	shape.radius = 28.0
	$CollisionShape2D.shape = shape
	z_index = 6
	queue_redraw()


func _process(delta: float) -> void:
	_phase += delta * 3.0
	position.y = _base_y + sin(_phase) * 8.0
	queue_redraw()


func is_coin() -> bool:
	return true


func collect() -> void:
	if collected:
		return
	collected = true
	monitoring = false
	monitorable = false
	remove_from_group("scrolling")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.7, 1.7), 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var color := Color("#ffd43b") if value == NORMAL_VALUE else Color("#ff922b")
	draw_circle(Vector2.ZERO, 32.0, Color(color, 0.18))
	draw_circle(Vector2.ZERO, 24.0, Color("#171325"))
	draw_circle(Vector2.ZERO, 20.0, color)
	draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 20, Color("#fff3bf"), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(-7, 9), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#8f5b00"))
