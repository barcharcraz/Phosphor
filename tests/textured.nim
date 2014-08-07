## The MIT License (MIT)
## 
## Copyright (c) 2014 Charlie Barto
## 
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
## 
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
## 
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.

import phosphor
import opengl
import glfw/glfw
import sets, unsigned, tables
import freeimage

const vs = """
#version 150
in vec2 pos;
out VertData {
  vec2 uv;
} outData;
void main() {
  gl_Position = vec4(pos, 0.5, 1);
  outData.uv = pos;
}
"""
const ps = """
#version 150
out vec4 outputColor;
in VertData {
  vec2 uv;
} inData;
uniform sampler2D tex;
void main() {
  outputColor = texture(tex, inData.uv);
}
"""
var verts: array[6, float32] = [0.0'f32, 0.5,
                              0.5'f32, -0.5,
                              -0.5'f32, -0.5]
var idx: array[3, uint32] = [2'u32,1,0]

proc main() =
  glfw.init()
  FreeImage_Initialise(0)
  var win = newWin(GL_API = initGL_API(version = glv44))
  makeContextCurrent(win)
  loadExtensions()
  glEnable(GL_DEPTH_TEST)
  glDepthFunc(GL_LEQUAL)
  glDepthMask(true)
  glEnable(cGL_CULL_FACE)
  glFrontFace(GL_CCW)
  glClearColor(0, 0, 0, 1)

  var image = FreeImage_Load(FIF_TARGA, "diffuse.tga", 0)
  var image32 = FreeImage_ConvertTo32Bits(image)
  FreeImage_Unload(image)
  var texture: GLuint
  glGenTextures(1, addr texture)
  glBindTexture(GL_TEXTURE_2D, texture)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, 1024, 1024, 0, GL_BGRA, cGL_UNSIGNED_BYTE, FreeImage_GetBits(image32))
  glBindTexture(GL_TEXTURE_2D, 0)

  var program = CreateProgram(vs, ps)
  var obj = initDrawObject(program)
  obj.vertices = verts
  obj.indices = idx
  obj.tex = texture
  while not win.shouldClose:
    DrawBundle(obj)
    win.update()
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)
  win.destroy()
  FreeImage_DeInitialise()
  glfw.terminate()
main()
