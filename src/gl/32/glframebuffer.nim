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
import tables

#stupid hack, we exploit the dot
#casting style so we can do fbo.Color[0] = ...
#there may be a better way to do this
type color* = distinct GLuint

proc initFBOInfo(): FBOInfo =
  result.drawBuffers = @[]

proc initFBO*(): GLuint =
  glGenFramebuffers(1, addr result)
  framebufferInfo.add(result, initFBOInfo())
proc `[]=`*(t: var color, n: int, tex: GLuint) =
  glBindFramebuffer(GL_FRAMEBUFFER, t.GLuint)
  #TODO: here we assume that we are attaching a 2d texture
  # also we always bind texture level 0, which is find since
  # there's little reason to use a different one
  glFramebufferTexture(GL_FRAMEBUFFER, GLenum(GL_COLOR_ATTACHMENT0 + n), tex, 0.GLint)
  #add the color buffer to our draw buffers array
  var info = addr framebufferInfo.mget(t.Gluint)
  while info.drawBuffers.len <= n:
    info.drawBuffers.add(GL_NONE)
  info.drawBuffers[n] = GLenum(GL_COLOR_ATTACHMENT0 + n)
  # and set the draw buffers
  glDrawBuffers(info.drawBuffers.len.GLsizei, addr info.drawBuffers[0])
  glBindFramebuffer(GL_FRAMEBUFFER, 0)

proc `depth=`*(fbo: var GLuint, tex: GLuint) =
  glBindFramebuffer(GL_FRAMEBUFFER, fbo)
  glFramebufferTexture(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, tex, 0.GLint)
  glBindFramebuffer(GL_FRAMEBUFFER, 0)

proc `stencil=`*(fbo: var GLuint, tex: GLuint) =
  glBindFramebuffer(GL_FRAMEBUFFER, fbo)
  glFramebufferTexture(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, tex, 0.GLint)
  glBindFramebuffer(GL_FRAMEBUFFER, 0)

proc clear*(fbo: GLuint) =
  ## clears an FBO so the caller need not use glBindFramebuffer and
  ## glClear in their calling code
  glBindFramebuffer(GL_FRAMEBUFFER, fbo)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)
  glBindFramebuffer(GL_FRAMEBUFFER, 0)
