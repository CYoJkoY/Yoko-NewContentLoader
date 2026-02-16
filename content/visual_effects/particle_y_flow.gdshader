shader_type canvas_item;

uniform float particle_count : hint_range(1.0, 50.0) = 20.0;
uniform float particle_size : hint_range(0.0, 0.2) = 0.05;
uniform float move_speed : hint_range(0.0, 5.0) = 2.0;
uniform float trail_length : hint_range(0.0, 1.0) = 0.3;

// 伪随机数生成
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    float particle_effect = 0.0;
    
    // 生成多个粒子
    for (float i = 0.0; i < particle_count; i += 1.0) {
        // 每个粒子的起始位置（随机）
        float seed = i * 123.456;
        float start_pos = rand(vec2(seed, 0.0));
        
        // 粒子当前位置（随时间移动）
        float particle_pos = fract(start_pos + TIME * move_speed * 0.1);
        
        // 粒子轨迹
        float dist = abs(UV.y - particle_pos);
        float trail = smoothstep(trail_length, 0.0, dist);
        
        // 粒子头部（更亮）
        float head_size = particle_size * 0.3;
        float head = smoothstep(head_size, 0.0, dist);
        
        // 组合效果
        particle_effect += (trail * 0.5 + head * 0.5) / particle_count;
    }
    
    // 颜色变化
    vec3 particle_color = vec3(
        0.9 + sin(TIME * 2.0) * 0.1,
        0.5 + cos(TIME * 1.5) * 0.2,
        1.0 + sin(TIME * 0.8) * 0.1
    );
    
    vec3 final_color = tex_color.rgb;
    final_color += particle_color * particle_effect * tex_color.a * 2.0;
    
    COLOR = vec4(final_color, tex_color.a);
}