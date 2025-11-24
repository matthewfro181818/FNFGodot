extends ShaderMaterial
var objects: PackedStringArray: set = set_objects
var shader_name: String
var uniforms: Dictionary

func loadShader(path: String):
	shader = Paths.loadShaderCode(path)
	if !shader: return
	uniforms = get_shader_uniforms(self)
	for i in uniforms: set_shader_parameter(i,uniforms[i].default)

func set_objects(new_objects: PackedStringArray):
	var not_more: PackedStringArray
	var news: PackedStringArray
	
	var i: int = 0
	while i < new_objects.size():
		if !new_objects[i]: new_objects.remove_at(i); continue
		
		var name = new_objects[i].strip_edges()
		new_objects[i] = name
		
		if !name in objects: news.append(name)
		i += 1
	
	
	#Check the objects that's will not have this shader anymore.
	i = 0
	while i < objects.size(): 
		if not objects[i] in new_objects: not_more.append(objects[i]); 
		i += 1
	
	for o in not_more: 
		var obj = FunkinGD.Reflect._find_object(o)
		if obj is FunkinCamera: obj.removeFilter(self)
		elif obj is CanvasItem and obj.material == self: obj.material = null
	
	
	#Add Shaders
	for o in news:
		var obj = FunkinGD.Reflect._find_object(o)
		if obj is FunkinCamera: obj.addFilter(self)
		elif obj is CanvasItem: obj.material = self
	objects = new_objects

static func get_shader_uniforms(material: Material):
	var list: Dictionary[String,Dictionary]
	var uid = material.shader.get_rid()
	for i in material.shader.get_shader_uniform_list(true):
		var type = i.type
		var default_value = RenderingServer.shader_get_parameter_default(uid,i.name)
		if default_value == null: default_value = MathUtils.get_new_value(type)
		var data: Dictionary[String,Variant] = {'default': default_value,'type': type}
		var hint_string: String = i.get('hint_string')
		if hint_string: 
			var split: Array
			for s in hint_string.split(','): split.append(snappedf(float(s),0.001))
			data.range = split
		list[i.name] = data
	return list
