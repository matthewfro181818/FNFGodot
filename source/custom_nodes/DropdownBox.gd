@tool
class_name DropdownBox extends Control

@export var items: PackedStringArray: set = set_texts
@onready var folder_container: FoldableContainer = $FoldableContainer
@onready var separator: VBoxContainer = $FoldableContainer/VBoxContainer
@onready var label: Label = $Label
var _labels_created: Array[Label]
var _separators_created: Array[Separator]

@export var folded: bool:
	set(val): if folder_container: folder_container.folded = val
	get(): return folder_container.folded if folder_container else false

@export var icon: Texture: set = set_icon
@export var icon_max_width: float = 25.0: set = set_icon_max_width
var _icon_sprite: Sprite2D

signal items_changed()
func show_separator(show: bool = false):
	separator.visible = show
	update_text()

func _ready():
	separator.show_behind_parent = true
	folder_container.minimum_size_changed.connect(_update_minimum_size.call_deferred)
	_update_minimum_size()
	
	_update_label_pos()
	label.show_behind_parent = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.minimum_size_changed.connect(_update_folder_size)
	
	resized.connect(_update_folder_size)
	_update_folder_size()
	
	resized.connect(update_separator_pos)
	update_separator_pos()
	
	update_text()
	update_items()


func _update_minimum_size():
	custom_minimum_size = folder_container.get_combined_minimum_size()

func _update_folder_size():
	var label_size = label.get_minimum_size().x + label.position.x + 10.0
	folder_container.custom_minimum_size.x = maxf(size.x,label_size)
	folder_container.size.x = folder_container.custom_minimum_size.x

func update_separator_pos():
	separator.position = Vector2(get_minimum_size().x+30,label.size.y+6)

func _update_label_pos():
	if _icon_sprite: label.position.x = _icon_sprite.position.x + 5 + _icon_sprite.texture.get_size().x*_icon_sprite.scale.x
	else: label.position.x = 20

func update_items():
	_create_texts()
	_remove_deleted_texts()
	
	items_changed.emit()
	if !items:
		folder_container.folded = true
		return
	var index: int = 0
	while index < _labels_created.size():
		_labels_created[index].text = items[index]
		index += 1

func _create_texts():
	var length = _labels_created.size()
	while length < items.size():
		var h_separator = HSeparator.new()
		_separators_created.append(h_separator)
		separator.add_child(h_separator)
		
		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_labels_created.append(label)
		separator.add_child(label)
		length += 1

func _remove_deleted_texts():
	var length = _labels_created.size()
	while length > items.size():
		length -= 1
		_separators_created.pop_back().queue_free() #Remove Separator
		_labels_created.pop_back().queue_free() 

func update_text(): label.text = name

func _notification(what: int) -> void:
	if what == NOTIFICATION_PATH_RENAMED: if is_node_ready(): update_text()

func _on_v_box_container_minimum_size_changed() -> void: 
	custom_minimum_size.y = maxf(
		label.get_combined_minimum_size().y,
		separator.get_combined_minimum_size().y
	)

func set_texts(_texts: PackedStringArray) -> void: items = _texts; if is_node_ready(): update_items()

func _update_icon_texture():
	if _icon_sprite:
		custom_minimum_size.y = _icon_sprite.texture.get_size().y*_icon_sprite.scale.y
	else:
		custom_minimum_size.y = 0
	_update_label_pos()

func _update_icon_width():
	if !_icon_sprite: return
	if icon_max_width:
		var _scale = minf(1.0,icon_max_width/_icon_sprite.texture.get_size().x)
		_icon_sprite.scale = Vector2(_scale,_scale)
	else:
		_icon_sprite.scale = Vector2.ONE

func set_icon(texture: Texture):
	icon = texture
	if !texture and _icon_sprite:
		_icon_sprite.queue_free()
		_icon_sprite = null
		_update_label_pos()
	elif texture:
		if !_icon_sprite: 
			_icon_sprite = Sprite2D.new()
			_icon_sprite.position.x = 22
			_icon_sprite.centered = false
			add_child(_icon_sprite)
		_icon_sprite.texture = texture
		_update_icon_width()
		
	_update_icon_texture()
		
func set_icon_max_width(value: float):
	icon_max_width = value
	_update_icon_width()
	_update_label_pos()
