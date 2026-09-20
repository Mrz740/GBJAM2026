shader_type canvas_item;

uniform vec3 color: source_color;
uniform float dither_amount: hint_range(-1.0, 1.0, 0.001) = 0.0;
uniform int direction;
uniform sampler2D bayer_texture: filter_nearest;

void fragment() {
	float bayer = texture(bayer_texture, UV).r;
	
	float dither = 0.0;
	if (direction > 0)
		dither = step(UV.x, dither_amount + bayer);
	else
		dither = step(1.0-UV.x, dither_amount + bayer);
	
	COLOR = vec4(color, dither);
}
