#pragma header

vec2 vTextureCoord;
uniform sampler1D u_texture;

void main(void) {
    vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
    gl_FragColor = vec4(1.0 - color.r, 1.0 - color.g, 1.0 - color.b, 1.0 - color.a);
}