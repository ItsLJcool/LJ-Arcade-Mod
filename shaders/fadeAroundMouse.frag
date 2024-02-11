// Automatically converted with https://github.com/TheLeerName/ShadertoyToFlixel

#pragma header

#define round(a) floor(a + 0.5)
#define iResolution vec3(openfl_TextureSize, 0.)
#define iChannel0 bitmap
#define texture flixel_texture2D

// third argument fix
vec4 flixel_texture2D(sampler2D bitmap, vec2 coord, float bias) {
	vec4 color = texture2D(bitmap, coord, bias);
	if (!hasTransform) return color;

	if (color.a == 0.0) return vec4(0.0, 0.0, 0.0, 0.0);

	if (!hasColorTransform) return color * openfl_Alphav;

	color = vec4(color.rgb / color.a, color.a);
	mat4 colorMultiplier = mat4(0);
	colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
	colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
	colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
	colorMultiplier[3][3] = openfl_ColorMultiplierv.w;
	color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);

	if (color.a > 0.0) return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	
	return vec4(0.0, 0.0, 0.0, 0.0);
}

// variables which is empty, they need just to avoid crashing shader
uniform vec4 iMouse;
uniform vec2 radiusCircle;
uniform float radius;
uniform float smoothRadius;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Define the resolution of the screen
    vec2 resolution = iResolution.xy;
    
    // Normalize mouse position
    vec2 mousePos = iMouse.xy / radiusCircle;
    
    float transparency = 0.0;

    // Calculate distance from current pixel to the mouse position
    float distanceToMouse = distance(mousePos, fragCoord.xy / radiusCircle);
    // Calculate the transparency based on distance to mouse
    transparency = smoothstep(radius - smoothRadius, radius + smoothRadius, distanceToMouse);
    
    // Sample the sprite texture
    vec3 spriteColor = texture(iChannel0, fragCoord.xy / resolution).rgb;
    
    // Blend between the original color and transparency
    vec3 finalColor = mix(spriteColor, vec3(0.0), transparency);
    
    // Output the final color
    fragColor = vec4(finalColor, 1.0 - transparency); // Make the background transparent
}


void main() {
	mainImage(gl_FragColor, openfl_TextureCoordv*openfl_TextureSize);
}