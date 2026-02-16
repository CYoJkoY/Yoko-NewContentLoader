shader_type canvas_item;

uniform float speed : hint_range(0.0, 5.0) = 2.0;
uniform float width : hint_range(0.0, 1.0) = 0.3;
uniform float color_speed : hint_range(0.0, 5.0) = 1.0;

// 将HSV颜色转换为RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // 基础流光
    float flow = sin(UV.x * 10.0 - TIME * speed) * 0.5 + 0.5;
    flow = smoothstep(0.5 - width, 0.5 + width, flow);
    
    // 动态彩虹色
    float hue = fract(TIME * color_speed * 0.1); // 0.0-1.0循环
    vec3 rainbow_color = hsv2rgb(vec3(hue, 0.8, 1.0));
    
    // 应用效果
    vec3 final_color = tex_color.rgb;
    final_color += rainbow_color * flow * tex_color.a;
    
    COLOR = vec4(final_color, tex_color.a);
}