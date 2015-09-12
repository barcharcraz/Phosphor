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
import logging
import opengl
import glutils

proc GetCompileErrors*(shader: GLuint): string =
  var status: GLint
  var infoLogLen: GLsizei
  glGetShaderiv(shader, GL_COMPILE_STATUS.GLenum, addr status)
  if status == GL_FALSE:
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH.GLenum, addr infoLogLen)
    result = newString(infoLogLen)
    glGetShaderInfoLog(shader, infoLogLen, nil, result.cstring)
  else:
    result = ""

proc GetIsCompiled*(shader: GLuint): bool =
  var rv: GLint = 0
  glGetShaderiv(shader, GL_COMPILE_STATUS.GLenum, addr rv)
  result = (rv != 0)

proc CompileShader*(stype: GLenum; source: string): GLuint =
  result = glCreateShader(stype)
  var csource: cstring = source.cstring
  glShaderSource(result, 1.GLsizei, cast[cstringArray](addr csource), nil)
  glCompileShader(result)
  var err = GetCompileErrors(result)
  if err != "":
    logging.error(err)
  if GetIsCompiled(result) == false:
    raise newException(EGraphicsAPI, err)

proc CheckLinkStatus*(program: GLuint): tuple[status: GLint, err: string] =
  glGetProgramiv(program, GL_LINK_STATUS, addr result.status)
  if result.status == GL_FALSE:
    var errLen: GLint = 0
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, addr errLen)
    result.err = newString(errLen)
    glGetProgramInfoLog(program, errLen.GLsizei, nil, result.err.cstring)

proc CreateProgram*(shaders: varargs[GLuint]): GLuint =
  result = glCreateProgram()
  for elm in shaders:
    glAttachShader(result, elm)
  #glBindAttribLocation(result, 0, "pos")
  #glBindAttribLocation(result, 1, "uv")
  #glBindAttribLocation(result, 2, "norm")
  glLinkProgram(result)
  var (res, err) = CheckLinkStatus(result)
  CheckError()
  if res == GL_FALSE:
    raise newException(EGraphicsAPI, err)
  for elm in shaders:
    glDetachShader(result, elm)

proc CreateProgram*(vs, ps: string): GLuint =
  var vert = CompileShader(GL_VERTEX_SHADER, vs)
  var pix = CompileShader(GL_FRAGMENT_SHADER, ps)
  result = CreateProgram(vert, pix)
