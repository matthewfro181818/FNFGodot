extends Node2D
const AlphabetText = preload("uid://b8v0hkg10y6g3")
const FunkinCheckBox = preload("uid://7ipxxo56l60m")
const NumberRange = preload("uid://7g33qugw2fc1")
const TextRange = preload("uid://csxpt0kkmvoci")
var data: Array
var optionIndex: int : set = set_option_index
var cur_data: Dictionary

signal on_index_changed
func _ready(): set_process_input(visible)

func set_option_index(value: int):
	if !data: return
	
	value = wrapi(value,0,data.size())
	
	optionIndex = value
	if cur_data:
		var last_node = get_node(cur_data.name)
		if last_node: last_node.modulate = Color.DARK_GRAY
		FunkinGD.playSound('scrollMenu')
	
	cur_data = data[optionIndex]
	var node = get_node(cur_data.name)
	if node: node.modulate = Color.WHITE
	on_index_changed.emit()
	
func loadInterators():
	var index: int = 0
	while index < data.size():
		var pos = Vector2(20,50 + 120*index)
		var data = data[index]
		
		var text_n = AlphabetText.new()
		text_n.scale = Vector2(0.8,0.8)
		var obj = data.get(&'object')
		var value_type: int = TYPE_NIL
		var value = null
		
	
		if data.has(&'getter'): 
			var params = data.get(&'getter_params')
			if params: value = data.getter.callv(params)
			else: value = data.getter.call()
		elif obj: value = obj.get(data.property)
		
		value_type = typeof(value)
		data.type = value_type
			
		text_n.modulate = Color.DARK_GRAY
		if value_type:
			text_n.text = data.name+': '
			createOptionInterator(data,value,text_n)
			
		else: text_n.text = data.name
		add_child(text_n)
		
		text_n.name = data.name
		text_n.position = pos
		index += 1
	set_option_index(0)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP: optionIndex -= 1
			KEY_DOWN: optionIndex += 1

static func createOptionInterator(option_data: Dictionary, value: Variant, at: AlphabetText = null) -> Node:
	var object
	var pos = Vector2.ZERO
	var value_options = option_data.get('options')
	var min = option_data.get('min')
	var max = option_data.get('max')
	
	var type = typeof(value)
	match type:
		TYPE_BOOL: 
			object = FunkinCheckBox.new();
			pos.y -= 50
		TYPE_FLOAT,TYPE_INT: 
			if value_options:
				object = TextRange.new()
				object.variables = value_options
			else: 
				object = NumberRange.new()
				object.int_value = type == TYPE_INT
				if min != null:
					object.limit_min = true
					object.value_min = min
				if max != null:
					object.limit_max = true
					object.value_max = max
	
	#Set Current Value
	if object is TextRange: object.set_index_from_key(value)
	else: object.value = value
	object.name = &'value'
	
	if at: 
		var target = Vector2(at.width+pos.x,pos.y)
		object.set_position(target);
		at.add_child(object)
	return object
