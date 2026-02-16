shader_type canvas_item;

uniform float speed : hint_range(0.0, 5.0) = 2.0;
uniform float distortion_strength : hint_range(0.0, 0.5) = 0.2;
uniform float noise_scale : hint_range(0.1, 10.0) = 3.0;

// 简单噪声函数
float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// 分形布朗运动（FBM）
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 3; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

void fragment() {
    vec2 uv = UV;
    
    // 添加噪声扭曲
    vec2 distortion = vec2(
        fbm(uv * noise_scale + TIME * 0.5) - 0.5,
        fbm(uv * noise_scale * 1.2 + TIME * 0.7) - 0.5
    ) * distortion_strength;
    
    uv += distortion;
    
    vec4 tex_color = texture(TEXTURE, uv);
    
    // 多层流光
    float flow1 = sin(uv.y * 8.0 - TIME * speed) * 0.5 + 0.5;
    float flow2 = sin(uv.y * 12.0 + TIME * speed * 0.7) * 0.5 + 0.5;
    float flow3 = sin(uv.y * 6.0 - TIME * speed * 1.3) * 0.5 + 0.5;
    
    float flow = (flow1 + flow2 * 0.7 + flow3 * 0.3) / 2.0;
    flow = smoothstep(0.3, 0.7, flow);
    
    // 动态颜色
    vec3 glow_color = vec3(
        0.8 + sin(TIME) * 0.2,
        0.4 + cos(TIME * 1.3) * 0.2,
        1.0 + sin(TIME * 0.7) * 0.2
    );
    
    vec3 final_color = tex_color.rgb;
    final_color += glow_color * flow * tex_color.a * 1.5;
    
    COLOR = vec4(final_color, tex_color.a);
}