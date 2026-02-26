shader_type canvas_item;

uniform float speed : hint_range(0.5, 10.0) = 3.0;
uniform float frequency : hint_range(0.1, 10.0) = 2.0;
uniform float amplitude : hint_range(0.0, 50.0) = 5.0;

void vertex() {
	float strength = abs(UV.y - 0.5) * 2.0;
	strength = pow(strength, 1.5);
	float wave = sin(TIME * speed + VERTEX.y * 0.05 * frequency) * amplitude;
	VERTEX.x += wave * strength;
}