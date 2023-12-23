shader_type canvas_item;

uniform sampler2D noise : repeat_enable;
uniform float factor : hint_range(-1.0, 1.0, 0.01);

void fragment()
{
	COLOR.rgb = texture(TEXTURE, UV).rgb;
	float noise1 = texture(noise, UV + TIME * 0.1).r;
	float noise2 = texture(noise, UV - noise1).r;
	
	COLOR.a = noise2 + factor;
}