static var parser: XMLParser = XMLParser.new()
static var sparrows_loaded: Dictionary[String,Dictionary]

const deg_90 = deg_to_rad(-90)

##Load the data from the xml file, [param file] have to be the EXACT LOCATION.[br][br]
## Example: [codeblock]
##loadSparrow("images/Image.xml") #Wrong
##loadSparrow("C:/Users/[Your Username]/Images/images/Image.xml") #Correct
##loadSparrow(Paths.detectFileFolder("images/Image.xml")) #Also works if the file are found.
##[/codeblock]
static func loadSparrow(file: String) -> Dictionary[StringName,Array]:
	
	if !file.ends_with('.xml'): file += '.xml'
	
	var sparrow: Dictionary[StringName,Array] = sparrows_loaded.get(
		file,
		Dictionary({},TYPE_STRING_NAME,&'',null,TYPE_ARRAY,&"",null)
	) #Aqui, ele já salva o arquivo no Dictionary tlgd
	if sparrow: return sparrow
	if !FileAccess.file_exists(file): return {}
	
	parser.open(file)
	while parser.read() == OK: #Aqui começa a ler
		if parser.get_node_type() != XMLParser.NODE_ELEMENT: continue
		var xmlName: StringName = parser.get_named_attribute_value_safe('name')
		if !xmlName:  continue;
		xmlName = xmlName.left(-4) #< ---Isso aqui, ele remove os numeros finais da string, os "0000"
		
		var animationFrames: Array[Dictionary] = sparrow.get_or_add(
			xmlName,
			Array([],TYPE_DICTIONARY,&'',null)
		)
		
		var region_data: Rect2 = Rect2(
			parser.get_named_attribute_value('x').to_float(),
			parser.get_named_attribute_value('y').to_float(),
			parser.get_named_attribute_value('width').to_float(),
			parser.get_named_attribute_value('height').to_float()
		) #Aqui a data
		var s: Vector2 = region_data.size
		var f_s: Vector2 = s
		var r: float
		var p: Vector2
		
		if parser.get_named_attribute_value_safe('rotated') == 'true':
			r = deg_90
			p.y += s.x
			s = Vector2(s.y,s.x)
		
		var frameData: Dictionary = {&"region_rect": region_data, &"position": p, &"size": s, &"rotation": r}
		
		if parser.has_attribute('frameX'):
			frameData[&"position"] -= Vector2(
				parser.get_named_attribute_value('frameX').to_float(),
				parser.get_named_attribute_value('frameY').to_float()
			)
			f_s =  Vector2(parser.get_named_attribute_value('frameWidth').to_float(),
				parser.get_named_attribute_value('frameHeight').to_float()
			)
			frameData[&"frameSize"] = f_s
			
		animationFrames.append(frameData)
	sparrows_loaded[file] = sparrow
	return sparrow
