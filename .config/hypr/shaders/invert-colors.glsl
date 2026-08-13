// Inverts the screen.
//
// Ported to `#version 300 es` (GLSL ES 3.00). It was previously written against
// GLSL ES 1.00 -- no #version directive, plus `varying` / `texture2D` /
// `gl_FragColor` -- which Hyprland's own vertex shader has since outgrown.
// Loading it produced "Screen shader parser: Error linking program: error: all
// shaders must use same shading language version" as a banner across the top of
// the screen, and the banner outlived the shader being switched back off.
//
// The version, the `in`/`out` declarations and the `tex` uniform name all have
// to match what Hyprland links against; see the shaders shipped in
// /usr/share/hyprshade/shaders for the reference form.

#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // Alpha is left alone -- inverting it would make the whole screen
    // transparent rather than negative.
    fragColor = vec4(1.0 - pixColor.rgb, pixColor.a);
}
