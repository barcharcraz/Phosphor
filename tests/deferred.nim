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
const vs = """
#version 140
in vec3 pos;
in vec2 uv;
out vec3 pos0;
out vec2 uv0;
void main() {
  gl_Position = vec4(pos, 1.0);
  pso0 = pos;
  uv0 = uv;
}
"""
const ps = """
#version 140
in vec3 pos0;
in vec2 uv0;
layout (location = 0) out vec3 PosOut;
layout (location = 1) out vec2 UVOut;

void main() {
  PosOut = pos0;
  UVOut = uv0;
}
"""
 
glfw.init()
var win  = newWin(GL_API = initGL_API(version = glv31))
makeContextCurrent(win)
loadExtensions()
glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LEQUAL)
glDepthMaxk(true)
glEnable(cGL_CULL_FACE)
glFrontFace(GL_CCW)
glClearColor(0,0,0,1)

var program = CreateProgram(vs, ps)
var obj = initDrawObject(program)

