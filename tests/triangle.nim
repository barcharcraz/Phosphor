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
import sets, unsigned
const vs = """
#version 140
in vec2 pos;
void main() {
  gl_Position = vec4(pos, 0.5, 1);
}
"""
const ps = """
#version 140
out vec4 outputColor;
void main() {
  //red color
  outputColor = vec4(1, 0, 0, 1);
}
"""
type TVert = object
  pos: array[2, float32]
var verts: array[6, float32] = [0.0'f32, 0.5,
                              0.5'f32, -0.5,
                              -0.5'f32, -0.5]
var idx: array[3, uint32] = [2'u32,1,0]
proc main() =
  glfw.init()
  var api = initGL_API(glv31, true, true, glpAny, glrNone)
  var wnd = newGlWin(dim = (w: 640, h: 480), title = "triangle", version=glv32, profile=glpCore, 
                     forwardCompat=true, refreshRate = 1)

  makeContextCurrent(wnd)
  loadExtensions()
  glEnable(GL_DEPTH_TEST)
  glDepthFunc(GL_LEQUAL)
  glDepthMask(true)
  #glDepthRange(0.0'f32, 1.0'f32)
  glEnable(cGL_CULL_FACE)
  glFrontFace(GL_CCW)
  glViewport(0,0,640,480)
  glClearColor(0.0'f32, 0.0'f32, 0.0'f32, 1.0'f32)
  var program = CreateProgram(vs, ps)
  var obj = initDrawObject(program)
  obj.vertices = verts
  obj.indices = idx
  while not wnd.shouldClose:
    DrawBundle(obj)
    wnd.update()
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)
  wnd.destroy()
  glfw.terminate()
main()
