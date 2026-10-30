## Persistent upgrade shop shown from the home screen.
class_name ShopPanel
extends Control

signal closed

var _message: Label
var _points_label: Label
var _cards: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.make_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	queue_redraw()


func _build_ui() -> void:
	var title := UiKit.title("SCHOOL SHOP", 72, UiKit.GOLD)
	title.position = Vector2(110, 58)
	title.size = Vector2(1000, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(title)

	_points_label = UiKit.label("", 30, UiKit.CYAN)
	_points_label.position = Vector2(1160, 84)
	_points_label.size = Vector2(600, 60)
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_points_label)

	var subtitle := UiKit.label("Spend collected coins on permanent upgrades.", 24, UiKit.MUTED)
	subtitle.position = Vector2(116, 154)
	add_child(subtitle)

	var panel := UiKit.panel_container(UiKit.panel_style(Color(0.04, 0.05, 0.1, 0.94), Color(0.5, 0.9, 1.0, 0.35)))
	panel.position = Vector2(100, 220)
	panel.size = Vector2(1720, 650)
	add_child(panel)
	_cards = VBoxContainer.new()
	_cards.add_theme_constant_override("separation", 14)
	panel.add_child(_cards)
	for upgrade in GameConfig.SHOP_UPGRADES:
		_add_upgrade_card(upgrade)

	_message = UiKit.label("", 24, UiKit.GREEN)
	_message.position = Vector2(116, 900)
	_message.size = Vector2(1100, 42)
	add_child(_message)

	var back := UiKit.button("BACK TO HOME")
	back.position = Vector2(1450, 900)
	back.size = Vector2(370, 68)
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)
	back.grab_focus.call_deferred()
	_refresh()


func _add_upgrade_card(upgrade: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 132)
	row.add_theme_constant_override("separation", 18)
	_cards.add_child(row)

	var icon := _Icon.new()
	icon.upgrade = upgrade
	icon.custom_minimum_size = Vector2(92, 92)
	row.add_child(icon)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(UiKit.label(GameConfig.SHOP_NAMES[upgrade], 30, UiKit.INK))
	copy.add_child(UiKit.label(GameConfig.SHOP_DESCRIPTIONS[upgrade], 22, UiKit.MUTED))
	var level := UiKit.label("", 22, UiKit.CYAN)
	level.name = "Level"
	copy.add_child(level)
	row.add_child(copy)

	var buy := UiKit.button("UPGRADE", true)
	buy.custom_minimum_size = Vector2(260, 74)
	buy.name = "Buy"
	buy.pressed.connect(func() -> void: _buy(upgrade))
	row.add_child(buy)


func _refresh() -> void:
	_points_label.text = "COINS  %s" % GameConfig.format_score(SaveManager.shop_points)
	for row in _cards.get_children():
		var upgrade := ""
		for candidate in GameConfig.SHOP_UPGRADES:
			if row.get_child(1).get_child(0).text == GameConfig.SHOP_NAMES[candidate]:
				upgrade = candidate
				break
		if upgrade.is_empty():
			continue
		var level := SaveManager.get_shop_level(upgrade)
		row.get_child(1).get_node("Level").text = "LEVEL %d / %d" % [level, GameConfig.SHOP_MAX_LEVEL]
		var button := row.get_node("Buy") as Button
		if level >= GameConfig.SHOP_MAX_LEVEL:
			button.text = "MAX LEVEL"
			button.disabled = true
		else:
			button.text = "UPGRADE  %s" % GameConfig.format_score(SaveManager.get_shop_cost(upgrade))
			button.disabled = SaveManager.shop_points < SaveManager.get_shop_cost(upgrade)


func _buy(upgrade: String) -> void:
	if SaveManager.purchase_upgrade(upgrade):
		_message.text = "%s upgraded! It applies on your next run." % GameConfig.SHOP_NAMES[upgrade]
		_message.add_theme_color_override("font_color", UiKit.GREEN)
	else:
		_message.text = "Not enough coins for that upgrade."
		_message.add_theme_color_override("font_color", UiKit.RED)
	_refresh()


func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color("#101a30"))
	for i in 12:
		var y := 210.0 + float(i) * 74.0
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.5, 0.9, 1.0, 0.035), 1.0)


class _Icon extends Control:
	var upgrade: String = ""

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		var color: Color = [UiKit.GOLD, UiKit.CYAN, UiKit.PINK, UiKit.VIOLET][GameConfig.SHOP_UPGRADES.find(upgrade)]
		draw_circle(Vector2(46, 46), 40.0, Color(color, 0.16))
		draw_arc(Vector2(46, 46), 40.0, 0.0, TAU, 32, color, 3.0)
		match upgrade:
			"speed":
				draw_line(Vector2(25, 55), Vector2(61, 55), color, 8.0, true)
				draw_line(Vector2(61, 55), Vector2(72, 43), color, 8.0, true)
				draw_line(Vector2(37, 43), Vector2(55, 43), color, 6.0, true)
			"recovery":
				draw_rect(Rect2(29, 28, 34, 39), color, false, 6.0)
				draw_line(Vector2(36, 28), Vector2(36, 20), color, 5.0)
				draw_line(Vector2(56, 28), Vector2(56, 20), color, 5.0)
				draw_line(Vector2(37, 47), Vector2(55, 47), color, 5.0)
			"dash":
				draw_circle(Vector2(46, 48), 19.0, color)
				draw_line(Vector2(46, 17), Vector2(46, 31), color, 6.0, true)
				draw_line(Vector2(46, 65), Vector2(46, 79), color, 6.0, true)
			"score":
				draw_colored_polygon(PackedVector2Array([Vector2(46, 18), Vector2(54, 37), Vector2(75, 38), Vector2(59, 51), Vector2(64, 72), Vector2(46, 60), Vector2(28, 72), Vector2(33, 51), Vector2(17, 38), Vector2(38, 37)]), color)
