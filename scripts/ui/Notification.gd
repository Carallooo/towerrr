extends Control
class_name Notification

var message: String = ""
var type: String = "info"
var duration: float = 3.0
var timer: float = 0.0
var anim_progress: float = 0.0

@onready var ui_manager: UIManager = UIManager

func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	offset_top = 0
	offset_bottom = 60
	offset_left = 20
	offset_right = -20


func initialize(msg: String, t: String, dur: float) -> void:
	message = msg
	type = t
	duration = dur
	timer = 0.0
	anim_progress = 0.0

	# Add close button
	var close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(24, 24)
	close_btn.flat = true
	close_btn.pressed.connect(queue_free)
	add_child(close_btn)
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_top = 4
	close_btn.offset_right = -4


func _process(delta: float) -> void:
	timer += delta

	# Slide in animation
	if anim_progress < 1.0:
		anim_progress = min(1.0, anim_progress + delta * 8.0)

	# Slide out animation
	if timer > duration - 0.5:
		anim_progress = max(0.0, anim_progress - delta * 4.0)
		if anim_progress <= 0.0:
			queue_free()

	# Update position
	var y = lerp(-80, 0, anim_progress)
	offset_top = y
	offset_bottom = y + 60


func _draw() -> void:
	var colors = {
		"info": Color(0.2, 0.7, 0.9),
		"success": Color(0.3, 0.9, 0.4),
		"warning": Color(1.0, 0.7, 0.1),
		"error": Color(0.9, 0.3, 0.3),
	}
	var bg_color = colors.get(type, colors["info"])

	# Background
	var rect = Rect2(Vector2.ZERO, Vector2(size.x, 50))
	draw_rect(rect, Color(bg_color.r, bg_color.g, bg_color.b, 0.9 * anim_progress))
	draw_rect(rect, bg_color, false, 2)

	# Icon
	var icons = {"info": "ℹ️", "success": "✅", "warning": "⚠️", "error": "❌"}
	var icon = icons.get(type, "ℹ️")
	draw_string(get_theme_font(), Vector2(10, 30), icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)

	# Message
	draw_string(get_theme_font(), Vector2(40, 30), message, HORIZONTAL_ALIGNMENT_LEFT, size.x - 50, 16, Color(1, 1, 1, anim_progress))

	# Progress bar
	if duration > 0:
		var prog = 1.0 - (timer / duration)
		var bar_rect = Rect2(0, 50, size.x * prog, 3)
		draw_rect(bar_rect, bg_color)