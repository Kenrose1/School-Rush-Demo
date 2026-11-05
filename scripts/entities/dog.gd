## The neighbor's dog: charges right-to-left through one warned lane.
## Inherits Hazard so the player's lane check, damage and i-frame pipeline
## apply without special cases (GDD Section VI). Frame animation lives in the
## scene's AnimationPlayer ("walk") so it can be previewed in the editor.
class_name Dog
extends Hazard

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	kind = Hazard.Kind.DOG
	super._ready()
	if _sprite == null:
		return
	# The walk sheet faces right; the dog runs left toward Elias.
	_sprite.flip_h = true


func _draw() -> void:
	# Ground shadow; the animated sprite is a child node.
	draw_circle(Vector2(0, 4), 42.0, Color(0.05, 0.04, 0.1, 0.35))
	super._draw()
