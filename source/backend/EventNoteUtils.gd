
##A script to help with Event Notes.
static func _get_events_data(events: Array) -> Array[Dictionary]:
	var new_events: Array[Dictionary]
	var event_base = _get_event_base()
	for data in events:
		if data is Array: new_events.append_array(_convert_event_to_new(data))
		else:
			var event_variables = get_event_variables(data.e)
			data.merge(event_base,false);
			if data.v is Dictionary: 
				for i in event_variables: if !data.v.has(i): data.v[i] = event_variables[i].default_value
			else:
				var val = data.v
				data.v = {}
				for i in event_variables: data.v[i] = event_variables[i].default_value
				data.v[event_variables.keys()[0]] = val
			
			new_events.append(data)
	return new_events

static func _convert_event_to_new(data: Array) -> Array[Dictionary]:
	var new_events: Array[Dictionary]
	for i in data[1]: 
		var event = _get_event_base()
		var event_name: StringName = i[0]
		var variables = get_event_variables(event_name)
		var vars_keys = variables.keys()
		
		event.t = data[0]
		event.e = event_name
		
		var first_val = vars_keys[0]
		for v in variables: event.v[v] = variables[v].default_value
		
		event.v[first_val] = _convert_event_value_type(i[1],variables[first_val].type,event.v[first_val])
		if vars_keys.size() >= 2 and i.size() >= 3: 
			var second_val = vars_keys[1]
			event.v[second_val] = _convert_event_value_type(i[2],variables[second_val].type,event.v[second_val])
		new_events.append(event)
	return new_events

static func _convert_event_value_type(value: Variant, type: Variant.Type, default_value: Variant = null):
	if value == null: return MathUtils.get_new_value(type)
	var value_type = typeof(value)
	match type:
		TYPE_NIL: return value
		TYPE_FLOAT,TYPE_INT: if value_type == TYPE_STRING and !value and default_value: return default_value
	return type_convert(value,type)

static func loadEvents(chart: Array = []) -> Array[Dictionary]:
	var events = _get_events_data(chart)
	events.sort_custom(func(a,b):return a.t < b.t)
	return events

#region Chart Methods
static var event_variables: Dictionary
static var easing_types: PackedStringArray

const default_variables = {
	&'value1': {
		&'type': TYPE_STRING,
		&'default_value': ''
	},
	&'value2': {
		&'type': TYPE_STRING,
		&'default_value': ''
	}
}


static func _get_event_base() -> Dictionary[StringName,Variant]:
	return {
		&'t': 0.0, #Time
		&'v': {}, #Variables
		&'e': &'', #Event
		&'trigger_when_opponent': true,
		&'trigger_when_player': true
	}
static func _get_transitions():
	var trans: PackedStringArray
	for i in TweenService.transitions:
		i = StringUtils.first_letter_upper(i)
		trans.append("#"+i)
		if i == &'': trans.append("Linear"); continue
		for e in TweenService.easings: trans.append(i+e)
	return trans

##Return the variables of the a custom_event using "@vars" in his text.[br]
##The function returns a [Dictionary] that contains an [Array] with its type and its default value.[br][br]
##[b]Example:[/b] [code]{"value1": [TYPE_STRING,''], "value2": [TYPE_FLOAT,0.0]}[/code]
static func get_event_variables(event_name: StringName) -> Dictionary:
	if event_name in event_variables: return event_variables[event_name]
	var event_data = Paths.loadJson('custom_events/'+event_name+'.json')
	if !event_data or !event_data.has(&'variables'): return default_variables
	
	var variables: Dictionary
	for i in event_data.variables: variables[i] = _get_value_data(event_data.variables[i])
	event_variables[event_name] = variables
	return variables

static func _get_value_data(value: Dictionary):
	var type = value.get('type','String')

	var value_type: int
	var options: Array = value.get('options',[])
	match type:
		'EasingType':
			options.append_array(easing_types)
			value_type = TYPE_STRING
		_: value_type = MathUtils.type_via_string(type)
		
	var default_value: Variant = value.get('default_value')
	if !default_value or typeof(default_value) != value_type:
		default_value = MathUtils.get_new_value(value_type)
	
	var data = {'type': value_type,'default_value': default_value}

	var look_at = value.get('look_at')
	if look_at and look_at.get('directory'):
		var extension = look_at.get('extension','')
		var files_founded = []
		var last_mod: String = ''
		for i in Paths.getFilesAt(look_at.directory,true,extension):
			var file = i.get_file()
			if file in files_founded: continue
			var mod = Paths.getModFolder(i)
			if last_mod != mod:
				last_mod = mod
				options.append('#'+mod)
			files_founded.append(file)
			options.append(file)
	
	if options: data.options = options
	return data

static func _replace_look_at_to_enum(string: String) -> String:
	#Search for "LookAt" types
	var look_at_data = look_for_function_in_line(string,'LookAt')
	var look_at_created = look_at_data[0]
	
	string = look_at_data[1]
	
	var last_mod: String = ''
	for i in look_at_created:
		var data = look_at_created[i]
		var extension = data[1] if data.size() > 1 else ''
		var files = Paths.getFilesAt(data[0],true,extension)
		
		var func_data: String = ''
		
		for f in files:
			var mod = Paths.getModFolder(f)
			if last_mod != mod:
				func_data += ',#'+mod
				last_mod = mod
			func_data += ','+f.get_file()
		string = string.replace(i,'Enum('+func_data.right(-1)+')')
	return string
	
static func look_for_function_in_line(string: String, function: String):
	var index: int = 0
	var functions_created = {}
	
	var function_length = function.length()
	while true:
		index = string.find(function,index)
		if index == -1: break
		
		var index_find = index
		index += function_length
		
		var func_data = string.right(-index-1)
		var func_name = function+String.num_int64(index)
		
		var variables = func_data.left(StringUtils._find_last_parentese(func_data)+1)
		var variables_array = StringUtils.get_function_data(variables)[1]
		
		functions_created[func_name] = variables_array
		string = string.erase(index_find,function_length+variables.length()+1)
		string = string.insert(index_find,func_name)
	
	return [functions_created,string]
	
static func get_event_description(event_name: StringName) -> String:
	var text = Paths.text('custom_events/'+event_name)
	if !text:
		return ''
	var new_description: String = ''
	for i in text.split('\n'):
		if !i.begins_with('@vars'):
			new_description += i
	return new_description
#endregion
