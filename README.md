Phosphor
========

A nimrod library for interfacing with video graphics accelerators

Phosphor centers around the `TDrawObject` structure. This structure
contains all the information needed to issue a draw call, save for
things like the viewport size and clear color. To create a DrawObject
you call `initDrawObject` with a handle to a shader program. Phosphor
inspects the shader program and populates its internal data structures
before returning a new DrawObject to you.

Phosphor keeps track of the names and locations of uniform blocks and
sampler variables in your shader so that you can set them with the
standard `.` syntax. So for example if I had a shader like
```glsl
#version 140
out vec4 outputColor;
uniform ColorBlock {
  vec4 color;
};
void main() {
  outputColor = color;
}
```
I could populate the ColorBlock uniform block by simply writing 
`obj.ColorBlock = [0.0'f32m 1.0, 0.0, 1.0]` in nimrod. This works
for more than just literal arrays, any kind of structure that has the
same data layout as the uniform block can be used. For this reason it is recommended
that you use the std140 layout on your uniform interface blocks.

A similar syntax can be used to attach textures to shaders, note that
textures are attached directly to samplers, there is no need to bind a
texture to an image unit and then bind the sampler to the same image unit.
The rationale for this is that the library handles assigning image units and
could even decide to use bindless textures if the graphics card supports them.

Textures are not managed through Phosphor, API texture handles (GLuints) are
directly assigned to samplers, there are many image loading libraries out
there already, the examples use the FreeImage library.
