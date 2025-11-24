class_name StringUtils

static func split_no_space(text: String, delimiter: String) -> Array:
	var split = []
	for splits in text.split(delimiter):
		while splits.begins_with(" "):
			splits = splits.substr(1)
		split.append(splits)
	return split

static func replace_chars_from_dict(string: String,chars_to_replace: Dictionary):
	var new_s: PackedStringArray = []
	for i in string:
		if chars_to_replace.has(i):
			new_s.append(chars_to_replace[i])
			continue
		new_s.append(i)
	return ''.join(new_s)

static func first_letter_upper(string: String) -> String: return string[0].to_upper() + string.right(-1)

static func get_function_data(string: String) -> Array:
	var parameters = PackedStringArray()
	
	var find_first_parentese = string.find('(')
	var _parentese_index = _find_last_parentese(string)
	
	var func_name: String = string if find_first_parentese == -1 else string.left(find_first_parentese)
	var variables: String = string.substr(find_first_parentese+1,_parentese_index-find_first_parentese-1)
	
	if _parentese_index == -1:
		return [func_name,[]]
	

	for i in variables.split(','):
		i = parse_default_value_string(i)
		parameters.append(i)
	
	var last_var = parameters[parameters.size()-1]
	if last_var.ends_with(')'):
		parameters[parameters.size()-1] = last_var.left(-1)
	return [func_name,parameters]
	
static func parse_default_value_string(s: String) -> String:
	s = s.strip_edges()
	if (s.begins_with("'") and s.ends_with("'")) or (s.begins_with('"') and s.ends_with('"')):
		s = s.substr(1, s.length() - 2)  # remove as aspas externas
	return s
	
static func _find_last_parentese(string: String) -> int:
	var parenteses_founded: int = 0
	var last_parentese: int = 0
	
	for i in string:
		match i:
			'(':
				parenteses_founded += 1
			')':
				if parenteses_founded <= 0:
					return last_parentese
				parenteses_founded -= 1
		last_parentese += 1
		
	return -1
