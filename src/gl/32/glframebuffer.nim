## The MIT License (MIT)
## 
## Copyright (c) 2015 Charlie Barto
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


## we use this module to manage framebuffer objects
## and provide a render-to-texture model that closely matches
## direct3d. That is we can simply add render targets and a single
## depth and sencil target
import opengl

#stupid hack, we exploit the dot
#casting style so we can do fbo.Color[0] = ...
#there may be a better way to do this
type Color = distinct GLuint
type Depth = distinct GLuint
type Stencil = distinct GLuint

var defaultFBO: GLuint = 0
proc initFBO(): GLuint =
  glGenFramebuffers(1, addr result)
## attach value to the nth color attachment
## we assume that value is a 2D texture and we use
## the first (0th) mip level
proc `[]=`(t: var Color, n: int, value: GLuint) =
    assert(t.GLuint == defaultFBO)
    glBindFramebuffer(t.Gluint)
