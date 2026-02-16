shader_type canvas_item;

uniform vec4 glow_color : hint_color = vec4(0.8, 0.4, 1.0, 1.0);
uniform float width : hint_range(0.0, 1.0) = 0.3;
uniform float speed : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    float flow = sin(UV.x * 10.0 - TIME * speed) * 0.5 + 0.5;
    float pulse = sin(TIME * 2.0) * 0.5 + 0.5;
    float horizontal_mask = 1.0 - abs(UV.x - 0.5) * 2.0;
    flow = smoothstep(0.5 - width, 0.5 + width, flow);
    flow *= pulse;
    flow *= max(horizontal_mask, 0.0);
    
    vec3 final_color = tex_color.rgb;
    final_color += glow_color.rgb * flow * tex_color.a;
    final_color = clamp(final_color, vec3(0.0), vec3(1.0));
    
    COLOR = vec4(final_color, tex_color.a);
}