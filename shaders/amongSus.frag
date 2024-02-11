#pragma header

uniform vec3 fillColor;
uniform vec3 outlineColor;

uniform vec2 fillGradientCap;
uniform vec2 outlineGradientCap;

uniform vec3 fillGradientColor;
uniform vec3 outlineGradientColor;

uniform vec2 enableGradient;

void main() {
    gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
    vec3 daFill = fillColor;
    vec3 daOut = outlineColor;
    if (abs(enableGradient.x) > 0) {
        float fillMult = smoothstep(fillGradientCap.x, fillGradientCap.y, openfl_TextureCoordv.x);
        float outlineMult = smoothstep(outlineGradientCap.x, outlineGradientCap.y, openfl_TextureCoordv.x);
        daFill *= fillMult;
        daOut *= outlineMult;
        if ((abs(enableGradient.y) > 0)) {
            daFill = mix(fillGradientColor, fillColor, fillMult);
            daOut = mix(outlineGradientColor, outlineColor, outlineMult);
        }
    }
    gl_FragColor.rgb = daFill * gl_FragColor.b + daOut * gl_FragColor.r;
}