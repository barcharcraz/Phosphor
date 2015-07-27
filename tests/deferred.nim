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
import glfw
import freeimage
const vs = """
#version 150
in vec2 pos;
in vec2 uv;
out vec2 pos0;
out vec2 uv0;
void main() {
  gl_Position = vec4(pos, 0.5, 1.0);
  pos0 = pos;
  uv0 = uv;
}
"""
const ps = """
#version 150
in vec2 pos0;
in vec2 uv0;
out vec3 PosOut;
out vec3 UVOut;
out vec3 colorOut;

void main() {
  PosOut = vec3(pos0, 0.0);
  UVOut = vec3(uv0, 0.0);
  colorOut = vec3(0.8, 0.2, 1.0);
}
"""

const secondPassVs = """
#version 150
in vec2 pos;
out vec2 uv;
void main() {
  gl_Position = vec4(pos, 0.5, 1);
  uv = (pos + 1.0) * 0.5;
}
"""

const secondPassPs = """
#version 150
in vec2 uv;
out vec4 outputColor;
uniform sampler2D tex;

void main() {
  outputColor = texture(tex, uv);
  //outputColor = vec4(1.0, 0.0, 0.0, 0.0);
}
"""

var verts: array[6, float32] = [0.0'f32, 0.5,
                                0.5,    -0.5,
                               -0.5,    -0.5]
var idx: array[3, uint32] = [2'u32, 1, 0]

var fullscreenQuad: array[8, float32] = [-1.0'f32, 1.0,
                                           1.0,    -1.0,
                                          -1.0,    -1.0,
                                           1.0,     1.0]
var fullscreenQuadIdx = [0'u32, 3, 2, 2, 1, 0]
glfw.init()
FreeImage_Initialise(0)
var win  = newGlWin(version=glv33, forwardCompat=true, profile=glpCore)
makeContextCurrent(win)
loadExtensions()
glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LEQUAL)
glViewport(0,0,640,480)
glDepthMask(true)
glEnable(GL_CULL_FACE)
glFrontFace(GL_CCW)
glClearColor(0,0,0,1)

var image = FreeImage_Load(FIF_TARGA, "diffuse.tga", 0)
var image32 = FreeImage_ConvertTo32Bits(image)
FreeImage_Unload(image)
var buffers: array[3, GLuint]
glGenTextures(3, addr buffers[0])
for tex in buffers:
  glBindTexture(GL_TEXTURE_2D, tex)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, 640, 480, 0, GL_BGR, cGL_UNSIGNED_BYTE, nil)
glBindTexture(GL_TEXTURE_2D, 0)
var depth: GLuint
glGenTextures(1, addr depth)
glBindTexture(GL_TEXTURE_2D, depth)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURe_MAG_FILTER, GL_LINEAR)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, 640, 480, 0, GL_DEPTH_COMPONENT, cGL_UNSIGNED_BYTE, nil)

var texBuffer: GLuint
glGenTextures(1, addr texBuffer)
glBindTexture(GL_TEXTURE_2D, texBuffer)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, 1024, 1024, 0, GL_BGRA, cGL_UNSIGNED_BYTE, FreeImage_GEtBits(image32))
var fbo = initFBO()
fbo.color[0] = buffers[0]
fbo.color[1] = buffers[1]
fbo.color[2] = buffers[2]
fbo.depth = depth
var program = CreateProgram(vs, ps)
var obj = initDrawObject(program)
obj.vertices = verts
obj.indices = idx
obj.framebuffer = fbo

var secondProg = CreateProgram(secondPassVs, secondPassPs)
var secondObj = initDrawObject(secondProg)
secondObj.vertices = fullscreenQuad
secondObj.indices = fullscreenQuadIdx
#secondObj.tex = buffers[2]
secondObj.tex = buffers[1]


while not win.shouldClose:
  DrawBundle(obj)
  DrawBundle(secondObj)
  win.update()
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)
  fbo.clear()
win.destroy()
FreeImage_DeInitialise()
glfw.terminate()

