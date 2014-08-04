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
import opengl
type EAttribNameNotFound = object of ESynch
type EUnsupportedAttribType = object of ESynch
proc GetAttribInfo(program, attrib: GLuint): tuple[typ: GLenum, len: GLint] =
  glGetActiveAttrib(program, attrib, 0, nil, addr result.len, addr result.typ, nil)
  case result.typ
  of cGL_FLOAT:
    result.len = 1
    result.typ = cGL_FLOAT
  of GL_FLOAT_VEC2:
    result.len = 2
    result.typ = cGL_FLOAT
  of GL_FLOAT_VEC3:
    result.len = 3
    result.typ = cGL_FLOAT
  of GL_FLOAT_VEC4:
    result.len = 4
    result.typ = cGL_FLOAT
  else:
    raise newException(EUnsupportedAttribType, "attrib type " & repr(result.typ) & " not supported")
proc GetSizeOfGLType(typ: GLenum): int =
  case typ
  of cGL_FLOAT:
    return 4
  else:
    raise newException(EUnsupportedAttribType, "coudl not get type size")
proc SetUpAttribArray(program, vao, verts, indices: GLuint; typ: typedesc) =
  var typInst: ptr typ = cast[ptr typ](nil)
  glBindVertexArray(vao)
  glBindBuffer(GL_ARRAY_BUFFER, verts)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indices)
  var attribIdx = 0.GLuint
  var attribLoc: GLint = -1
  for name, val in fieldPairs(typInst[]):
    glEnableVertexAttribArray(attribIdx)
    attribLoc = glGetAttribLocation(program, name)
    if attribLoc == -1: 
      raise newException(EAttribNameNotFound, name & " is not an attrib in the program")
    var (typ, len) = GetAttribInfo(program, attribLoc.GLuint)
    assert(sizeof(val) == GetSizeOfGLType(typ) * len)
    glVertexAttribPointer(attribLoc.GLuint, len, typ, false, GLsizei(sizeof(typ) * len), cast[pointer](addr val))
    inc(attribIdx)

proc CreateVertexInputs*[T](program, vao: GLuint, verts: var openarray[T]): GLuint =
  glBindVertexArray(vao)
  glGenBuffers(1, addr result)
  glBindBuffer(GL_ARRAY_BUFFER, result)
  var vertSize = sizeof(T) * verts.len
  glBufferData(GL_ARRAY_BUFFER, vertSize.GLsizeiptr, addr verts[0], GL_STATIC_DRAW)
  SetUpAttribArray(program, vao, result, 0, T)
proc CreateIndexInputs*[T](program, vao: GLuint, indices: var openarray[T]): GLuint =
  glGenBuffers(1, addr result)
  glBindVertexArray(vao)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, result)
  var idxSize = sizeof(T) * indices.len
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, idxSize.GLsizeiptr, addr indices[0], GL_STATIC_DRAW) 
  glBindVertexArray(0)

proc CreateShaderInputs*[T,U](program: GLuint; verts: openarray[T]; indices: openarray[U]): tuple[vao, verts, indices: GLuint] =
  glGenVertexArrays(1, addr result.vao)
  result.verts = CreateVertexInputs(program, result.vao, verts)
  result.indices = CreateIndexInputs(program, result.vao, indices)
