shader_type canvas_item;
uniform vec3 contorn_color: source_color = vec3(1.0);
uniform bool inverted = false;
uniform float limit: hint_range(0.0, 1.0, 0.05) = 0.7;
float vec3_max(vec3 vec){return max(vec.x,max(vec.y,vec.z));}
void fragment(){
	if(COLOR.a <= 0.0) discard;
	float col_max = vec3_max(COLOR.rgb);
	
	if(inverted) col_max = smoothstep(limit,0.0,col_max);
	else col_max = smoothstep(0.0,1.0,col_max);
	COLOR.rgb = contorn_color*col_max;
}