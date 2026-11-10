extends Node
class_name UIManager

signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)
signal tab_changed(tab_name: String)
signal notification_show(message: String, type: String, duration: float)

@onready var save_manager: SaveManager = SaveManager

var current_menu: String = ""
var menu_stack: Array[String] = []
var active_tooltips: Array[Dictionary] = []

# UI Theme colors (from GameData)
var colors: Dictionary = {
	"bg": Color(0.08, 0.08, 0.12),
	"panel": Color(0.12, 0.12, 0.18),
	"panel_hover": Color(0.16, 0.16, 0.22),
	"accent": Color(0.2, 0.7, 0.9),
	"accent_hover": Color(0.3, 0.8, 1.0),
	"gold": Color(1.0, 0.8, 0.2),
	"gem": Color(0.3, 0.9, 0.7),
	"text": Color(0.95, 0.95, 0.98),
	"text_dim": Color(0.7, 0.7, 0.8),
	"red": Color(0.9, 0.3, 0.3),
	"green": Color(0.3, 0.9, 0.4),
	"orange": Color(1.0, 0.6, 0.1),
	"purple": Color(0.8, 0.4, 1.0),
	"blue": Color(0.3, 0.7, 1.0),
	"border": Color(0.25, 0.25, 0.35),
	"border_focus": Color(0.4, 0.8, 1.0),
}

func _ready() -> void:
	# Initialize UI theme
	_apply_theme()


func _apply_theme() -> void:
	# This would apply to the entire project's theme
	# For now, we store colors for procedural UI drawing
	pass


# --- Menu Management ---

func open_menu(menu_name: String) -> void:
	if current_menu == menu_name:
		return

	if current_menu != "":
		menu_stack.append(current_menu)
		close_menu(current_menu)

	current_menu = menu_name
	menu_opened.emit(menu_name)


func close_menu(menu_name: String) -> void:
	if current_menu == menu_name:
		current_menu = ""
		if menu_stack.size() > 0:
			current_menu = menu_stack.pop_back()
		menu_closed.emit(menu_name)


func close_all_menus() -> void:
	while menu_stack.size() > 0:
		close_menu(menu_stack.pop_back())
	if current_menu != "":
		menu_closed.emit(current_menu)
		current_menu = ""


func get_current_menu() -> String:
	return current_menu


func is_menu_open(menu_name: String) -> bool:
	return current_menu == menu_name or menu_name in menu_stack


# --- Notification System ---

func show_notification(message: String, type: String = "info", duration: float = 3.0) -> void:
	notification_show.emit(message, type, duration)


func show_info(message: String, duration: float = 3.0) -> void:
	show_notification(message, "info", duration)


func show_success(message: String, duration: float = 3.0) -> void:
	show_notification(message, "success", duration)


func show_warning(message: String, duration: float = 4.0) -> void:
	show_notification(message, "warning", duration)


func show_error(message: String, duration: float = 5.0) -> void:
	show_notification(message, "error", duration)


# --- Tooltip System ---

func show_tooltip(text: String, position: Vector2, owner: Node = null) -> void:
	var tooltip = {
		"text": text,
		"position": position,
		"owner": owner,
		"time": Time.get_ticks_msec() / 1000.0,
	}
	active_tooltips.append(tooltip)


func hide_tooltip(owner: Node = null) -> void:
	if owner:
		active_tooltips = active_tooltips.filter(func(t): return t.owner != owner)
	else:
		active_tooltips.clear()


func get_active_tooltips() -> Array[Dictionary]:
	return active_tooltips.duplicate()


# --- Formatting Helpers ---

func format_number(num: int) -> String:
	if num >= 1_000_000_000_000:
		return "%.2fT" % (num / 1_000_000_000_000.0)
	elif num >= 1_000_000_000:
		return "%.2fB" % (num / 1_000_000_000.0)
	elif num >= 1_000_000:
		return "%.2fM" % (num / 1_000_000.0)
	elif num >= 1_000:
		return "%.2fK" % (num / 1_000.0)
	return str(num)


func format_number_full(num: int) -> String:
	# With thousand separators
	var str = str(num)
	var result = ""
	for i in range(str.length()):
		if i > 0 and (str.length() - i) % 3 == 0:
			result += ","
		result += str[i]
	return result


func format_time(seconds: float) -> String:
	if seconds < 60:
		return "%.1fs" % seconds
	elif seconds < 3600:
		return "%dm %.0fs" % [int(seconds / 60), fmod(seconds, 60)]
	elif seconds < 86400:
		return "%dh %dm" % [int(seconds / 3600), int(fmod(seconds, 3600) / 60)]
	else:
		return "%dd %dh" % [int(seconds / 86400), int(fmod(seconds, 86400) / 3600)]


func format_percent(value: float, decimals: int = 1) -> String:
	return "%.%%f%%" % [decimals] % (value * 100)


func format_mult(value: float, decimals: int = 2) -> String:
	return "%.%%fx" % [decimals] % value


# --- Color Helpers ---

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"Common": return Color(0.7, 0.7, 0.7)
		"Rare": return Color(0.3, 0.7, 1.0)
		"Epic": return Color(0.8, 0.4, 1.0)
		"Legendary": return Color(1.0, 0.7, 0.2)
		"Mythic": return Color(1.0, 0.3, 0.5)
	return colors.text


func get_currency_color(currency: String) -> Color:
	match currency:
		"cash": return Color(0.2, 0.8, 0.3)
		"coins": return Color(1.0, 0.8, 0.2)
		"gems": return Color(0.3, 0.9, 0.7)
		"power_stones": return Color(0.7, 0.4, 1.0)
		"medals": return Color(1.0, 0.6, 0.1)
		"elite_cells": return Color(0.9, 0.3, 0.9)
		"keys": return Color(0.9, 0.7, 0.2)
		"bits": return Color(0.5, 0.7, 1.0)
		"tokens": return Color(0.2, 0.9, 0.9)
		"module_shards": return Color(1.0, 0.5, 0.8)
		"reroll_shards": return Color(0.8, 0.8, 0.3)
	return colors.text


func get_currency_icon(currency: String) -> String:
	match currency:
		"cash": return "💵"
		"coins": return "🪙"
		"gems": return "💎"
		"power_stones": return "🔮"
		"medals": return "🏅"
		"elite_cells": return "🧬"
		"keys": return "🔑"
		"bits": return "⚙️"
		"tokens": return "🎫"
		"module_shards": return "✨"
		"reroll_shards": return "🔄"
	return "?"


# --- UI Drawing Helpers (for CanvasItem.draw) ---

func draw_panel(canvas: CanvasItem, rect: Rect2, bg_color: Color = null, border_color: Color = null, rounded: float = 8.0) -> void:
	bg_color = bg_color or colors.panel
	border_color = border_color or colors.border

	# Background
	canvas.draw_rect(rect, bg_color)

	# Border
	canvas.draw_rect(rect, border_color, false, 2.0)


func draw_progress_bar(canvas: CanvasItem, rect: Rect2, progress: float, fg_color: Color = null, bg_color: Color = null, border_color: Color = null, rounded: float = 4.0) -> void:
	progress = clamp(progress, 0.0, 1.0)
	fg_color = fg_color or colors.accent
	bg_color = bg_color or colors.bg
	border_color = border_color or colors.border

	# Background
	canvas.draw_rect(rect, bg_color)

	# Fill
	if progress > 0:
		var fill_rect = Rect2(rect.position, Vector2(rect.size.x * progress, rect.size.y))
		canvas.draw_rect(fill_rect, fg_color)

	# Border
	canvas.draw_rect(rect, border_color, false, 1.5)


func draw_text_with_outline(canvas: CanvasItem, text: String, position: Vector2, font_size: int, color: Color = null, outline_color: Color = null, halign: int = 0) -> void:
	color = color or colors.text
	outline_color = outline_color or Color(0, 0, 0, 0.8)

	# This is a placeholder - actual implementation would use a font
	# For now, we just document the interface
	pass


func draw_currency_display(canvas: CanvasItem, currency: String, amount: int, position: Vector2, font_size: int = 16, show_icon: bool = true) -> void:
	var icon = get_currency_icon(currency) if show_icon else ""
	var text = "%s %s" % [icon, format_number(amount)]
	var color = get_currency_color(currency)
	# Placeholder for actual drawing
	pass


# --- Button/Interactive Helpers ---

func create_button_data(text: String, rect: Rect2, enabled: bool = true, style: String = "normal") -> Dictionary:
	var colors_map = {
		"normal": {"bg": colors.panel, "text": colors.text, "border": colors.border},
		"primary": {"bg": colors.accent, "text": colors.text, "border": colors.accent},
		"success": {"bg": colors.green, "text": Color(0,0,0), "border": colors.green},
		"danger": {"bg": colors.red, "text": colors.text, "border": colors.red},
		"gold": {"bg": colors.gold, "text": Color(0,0,0), "border": colors.gold},
		"gem": {"bg": colors.gem, "text": Color(0,0,0), "border": colors.gem},
	}
	var c = colors_map.get(style, colors_map["normal"])
	if not enabled:
		c = {"bg": Color(0.2, 0.2, 0.25), "text": colors.text_dim, "border": Color(0.15, 0.15, 0.2)}

	return {
		"text": text,
		"rect": rect,
		"enabled": enabled,
		"style": style,
		"colors": c,
		"hovered": false,
		"pressed": false,
	}


func draw_button(canvas: CanvasItem, btn: Dictionary) -> void:
	var r = btn.rect
	var c = btn.colors

	# Background
	canvas.draw_rect(r, c.bg)

	# Border
	var border_w = 2.0 if btn.hovered else 1.5
	canvas.draw_rect(r, c.border, false, border_w)

	# Text (placeholder)
	# Actual text rendering would use a font


func point_in_rect(point: Vector2, rect: Rect2) -> bool:
	return point.x >= rect.position.x and point.x < rect.position.x + rect.size.x and \
		   point.y >= rect.position.y and point.y < rect.position.y + rect.size.y


# --- Layout Helpers ---

func layout_grid(items: Array, cols: int, item_size: Vector2, spacing: Vector2, start_pos: Vector2 = Vector2.ZERO) -> Array[Vector2]:
	var positions = []
	for i in range(items.size()):
		var col = i % cols
		var row = i / cols
		var pos = start_pos + Vector2(col * (item_size.x + spacing.x), row * (item_size.y + spacing.y))
		positions.append(pos)
	return positions


func layout_horizontal(items: Array, item_width: float, spacing: float, start_x: float = 0.0, center_y: float = 0.0) -> Array[Vector2]:
	var positions = []
	var total_width = items.size() * item_width + (items.size() - 1) * spacing
	var x = start_x - total_width / 2.0
	for i in range(items.size()):
		positions.append(Vector2(x + i * (item_width + spacing), center_y))
	return positions


func layout_vertical(items: Array, item_height: float, spacing: float, start_y: float = 0.0, center_x: float = 0.0) -> Array[Vector2]:
	var positions = []
	var total_height = items.size() * item_height + (items.size() - 1) * spacing
	var y = start_y - total_height / 2.0
	for i in range(items.size()):
		positions.append(Vector2(center_x, y + i * (item_height + spacing)))
	return positions


# --- Save/Load UI ---

func confirm_action(title: String, message: String, confirm_text: String = "Confirm", cancel_text: String = "Cancel") -> void:
	# Emits signal for confirmation dialog
	# Actual implementation would show a modal
	pass


# --- Settings UI ---

func create_slider_data(label: String, value: float, min_val: float, max_val: float, step: float = 0.01, format: String = "%.2f") -> Dictionary:
	return {
		"type": "slider",
		"label": label,
		"value": value,
		"min": min_val,
		"max": max_val,
		"step": step,
		"format": format,
	}


func create_toggle_data(label: String, value: bool) -> Dictionary:
	return {
		"type": "toggle",
		"label": label,
		"value": value,
	}


func create_dropdown_data(label: String, options: Array[String], selected: int) -> Dictionary:
	return {
		"type": "dropdown",
		"label": label,
		"options": options,
		"selected": selected,
	}


func create_button_row_data(label: String, buttons: Array[Dictionary]) -> Dictionary:
	return {
		"type": "button_row",
		"label": label,
		"buttons": buttons,  # Each: {text, action, style}
	}


# --- Accessibility ---

func set_high_contrast(enabled: bool) -> void:
	save_manager.set_setting("high_contrast", enabled)
	if enabled:
		colors.text = Color(1, 1, 1)
		colors.bg = Color(0, 0, 0)
		colors.panel = Color(0.1, 0.1, 0.1)
		colors.border = Color(0.5, 0.5, 0.5)
	else:
		_apply_theme()


func set_reduced_motion(enabled: bool) -> void:
	save_manager.set_setting("reduced_motion", enabled)


# --- Debug ---

func print_ui_tree(node: Node, indent: int = 0) -> void:
	var prefix = "  ".repeat(indent)
	print("%s%s (%s)" % [prefix, node.name, node.get_class()])
	for child in node.get_children():
		print_ui_tree(child, indent + 1)