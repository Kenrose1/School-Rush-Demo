## Pulsing exclamation mark that warns which lane the dog will charge through.
## Displayed for GameConfig.DOG_WARNING_TIME, then dismissed as the dog spawns.
## Frame animation lives in the scene's AnimationPlayer ("alert").
class_name DogAlert
extends Node2D

@onready var _sprite: Sprite2D = $Sprite

var lane: int = 1

var _time: float = 0.0
var _dismissed: bool = false


func _ready() -> void:
	position = Vector2(GameConfig.DOG_ALERT_X, GameConfig.lane_y(lane) - GameConfig.DOG_ALERT_Y_OFFSET)
	if _sprite != null:
		_sprite.scale = Vector2.ONE * GameConfig.DOG_ALERT_SCALE


func _process(delta: float) -> void:
	_time += delta
	if _sprite == null:
		return
	var pulse := 1.0 + 0.08 * sin(_time * 18.0)
	_sprite.scale = Vector2.ONE * GameConfig.DOG_ALERT_SCALE * pulse
	_sprite.modulate.a = 0.82 + 0.18 * absf(sin(_time * 9.0))


func dismiss() -> void:
	if _dismissed:
		return
	_dismissed = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func() -> void: queue_free())
