@icon("res://icons/FoldableContainer.svg")
@tool
extends Panel

const foldable_style = preload("uid://go6q2nvp2mu1")
@export var folded: bool = false: set = set_folded
@export_group("Text")
@export var text: String: set = set_text
@export var horizontal_aligmnent: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER: set = set_horizontal_alignment
@export var vertical_aligmnent: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER: set = set_vertical_alignment
@export var font_size: int = 16: set = set_font_size
@export var font: FontFile: set = set_font

@onready var button: Button: get = _get_button


func _get_button() -> Button:
	if button: return button
	button = get_node_or_null('Button')
	if button: return button
	button = Button.new()
	button.text = '>'
	button.add_theme_color_override(&'font_color',Color.DARK_GRAY)
	button.flat = true
	button.name = 'Button'
	add_child(button)
	return button

func _init(): 
	set("theme_override_styles/panel",foldable_style)
	resized.connect(queue_redraw)
	self_modulate = Color.GRAY

func _ready() -> void:
	_update_button_pos()
	_update_button_text()

func set_text(_s: String):  text = _s; queue_redraw()

func set_font(file: FontFile):
	font = file
	queue_redraw()

func set_font_size(_size: int) -> void: font_size = _size;queue_redraw()

func get_font() -> FontFile:
	if font: return font
	return ThemeDB.fallback_font

func set_horizontal_alignment(alignment: HorizontalAlignment) -> void: horizontal_aligmnent = alignment; queue_redraw()
func set_vertical_alignment(alignment: VerticalAlignment) -> void: vertical_aligmnent = alignment; queue_redraw();

func set_folded(enable: bool):
	folded = enable
	queue_redraw()

func _update_button_pos():
	match vertical_aligmnent:
		VERTICAL_ALIGNMENT_TOP: button.position.y = 0.0 - 5
		VERTICAL_ALIGNMENT_BOTTOM: button.position.y = size.y - button.size.y + 5
		_: button.position.y = (size.y- button.size.y - 5)*0.5 
	button.position.x = 5
func _update_button_text(): button.text = '>' if folded else 'v'

func _draw() -> void:
	var _font = get_font()
	var text_size = _font.get_string_size(text,horizontal_aligmnent,size.x,font_size)
	var text_pos = Vector2(20,text_size.y)
	custom_minimum_size = Vector2(text_size.x + text_pos.x + 5,maxi(text_size.y,20))
	match vertical_aligmnent:
		VERTICAL_ALIGNMENT_CENTER: text_pos.y += size.y; text_pos.y /= 2.0;
		VERTICAL_ALIGNMENT_BOTTOM: text_pos.y = size.y
	
	_update_button_pos()
	_update_button_text()

	if text: draw_string(_font,text_pos,text,horizontal_aligmnent,size.x,font_size)
