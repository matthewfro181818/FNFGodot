class_name ShaderUtils

const replace_frag: Dictionary = {
	'#pragma header': '',
	'main': 'fragment',
	'openfl_TextureSize': 'vec2(textureSize(bitmap,0))',
	'flixel_texture2D': 'texture',
	'flixel_texture': 'texture',
	'texture2D': 'texture',
	'gl_FragColor': 'COLOR'
}

static var _blends_created: Dictionary[String,Material] = {}

static func fragToGd(shaderCode: String) -> String:
	for r in replace_frag: shaderCode = shaderCode.replace(r,replace_frag[r])
	if not 'shader_type canvas_item;' in shaderCode: shaderCode = 'shader_type canvas_item;\n'+shaderCode
	
	shaderCode = shaderCode.replace('openfl_TextureCoordv','UV').replace('bitmap','TEXTURE')
	shaderCode = shaderCode.replace('texture(TEXTURE,UV)','COLOR').replace('texture(TEXTURE, UV)','COLOR')
	return shaderCode
	
#region Blend Methods
static func get_blend(blend: StringName) -> Material:
	blend = blend.to_lower()
	if _blends_created.has(blend): return _blends_created[blend]
	
	var canvas: Material
	match blend:
		&'add': canvas = CanvasItemMaterial.new(); canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		&'mix': canvas = CanvasItemMaterial.new(); canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
		&'multiply': canvas = CanvasItemMaterial.new(); canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
		&'subtract': canvas = CanvasItemMaterial.new(); canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
		&'premult_alpha': canvas = CanvasItemMaterial.new(); canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
		&'overlay':
			canvas = ShaderMaterial.new()
			canvas.shader = Shader.new()
			canvas.shader.code = "
			shader_type canvas_item;
			uniform sampler2D screen_texture : hint_screen_texture;
			void fragment(){
				vec4 color = texture(screen_texture,SCREEN_UV);
				vec4 tex = texture(TEXTURE,UV);
				COLOR = mix(2.0 * COLOR * tex, 1.0 - 2.0 * (1.0 - COLOR) * (1.0 - tex), step(0.5, tex));
			}
			"
		_: return null
	_blends_created[blend] = canvas
	return canvas

static func set_object_blend(object,blendMode: Variant) -> void:
	if !object: return
	var material: CanvasItemMaterial
	if blendMode is CanvasItemMaterial.BlendMode: material = CanvasItemMaterial.new(); material.blend_mode = blendMode
	else: material = get_blend(blendMode)
	
	object.set('material',material)
	
"""
static func set_texture_hue(texture: ImageTexture, hue_shift: float):
	if !texture: return
	var image = texture.get_image().duplicate()
	if !image: return
	for x in image.get_width():
		for y in image.get_height():
			var color = image.get_pixel(x, y)
			color.h = fmod(color.h + hue_shift, 1.0)
			if color.h < 0: color.h += 1.0
			image.set_pixel(x, y, Color.from_hsv(color.h, color.s, color.v, color.a))
	texture.update(image)
"""
#endregion
