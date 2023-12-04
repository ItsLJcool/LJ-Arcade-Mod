#pragma header

vec2 vTextureCoord;
uniform sampler1D u_texture;

void main() {
    vec2 pixelSize = 1.0/openfl_TextureSize;

    gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
    if (
    texture2D(bitmap, vec2(openfl_TextureCoordv.x - pixelSize.x, openfl_TextureCoordv.y)).a > 0.0
    || texture2D(bitmap, vec2(openfl_TextureCoordv.x + pixelSize.x, openfl_TextureCoordv.y)).a > 0.0
    || texture2D(bitmap, vec2(openfl_TextureCoordv.x, openfl_TextureCoordv.y - pixelSize.y)).a > 0.0
    || texture2D(bitmap, vec2(openfl_TextureCoordv.x, openfl_TextureCoordv.y + pixelSize.y)).a > 0.0
    ) {
        gl_FragColor = vec4(1.0);
    }
}
