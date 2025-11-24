extends Sprite2D
const EventNoteUtils = preload("uid://dqymf0mowy0dt")

var events: Array[Dictionary] = []

var strumTime: float:
	set(value):
		for i in events: i.t = value
		strumTime = value

var event_selected: Dictionary:
	set(value):
		event_selected = value
		event_selected_variables = value.v
		event_selected_name = value.e
	
var event_selected_variables: Dictionary
var event_selected_name: String
var event_index: int = -1

func _init():
	texture = Paths.texture('eventArrow')
	centered = false
	scale = Vector2(0.4,0.4)

func set_variable(variable: String, value: Variant):
	if not event_selected_variables.has(variable): return
	event_selected_variables[variable] = value

func selectEvent(index: int = event_index):
	index = clamp(index,0,events.size()-1)
	event_index = index
	event_selected = ArrayUtils.get_array_index(events,index,['',{}])

func addEvent(event_name: StringName = &'', variables: Dictionary = {},at: int = -1) -> Array:
	var event_default_vars = EventNoteUtils.get_event_variables(event_name)
	var event_vars: Dictionary
	var event_data = [event_name,event_vars]
	
	#Set the default value to event
	for vars in event_default_vars:
		event_vars[vars] = variables.get(vars,event_default_vars[vars].default_value)
	
	at = clamp(at,0,events.size())
	if at < events.size()-1: events.insert(at,event_data)
	else: events.append(event_data)
	
	event_selected = event_data
	return event_data

func replaceEvent(replace_to: String):
	addEvent(replace_to,event_selected_variables,event_index)
	if event_index != -1:
		events.remove_at(event_index)
	
func removeEvent(index: int = event_index) -> Array:
	var data = events.get(index)
	if !data: return []
	events.remove_at(index)
	return data
