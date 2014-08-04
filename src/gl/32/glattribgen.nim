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
proc ConfirmTypesMatch(typ: GLenum, nimtyp: typedesc): bool =
  ## confirms that a openGL type constant matches a nimrod type
  ## so for example GL_FLOAT would match nimrod's float32 type
  when nimtyp is float32:
    if typ == cGL_FLOAT: return true
  elif nimtyp is uint32:
    if typ == cGL_UNSIGNED_INT: return true
  elif nimtyp is uint16:
    if typ == cGL_UNSIGNED_SHORT: return true
  elif nimtyp is int32:
    if typ == cGL_INT: return true
  elif nimtyp is int16:
    if typ == cGL_SHORT: return true
proc GetSizeOfGLType(typ: GLenum): int =
  case typ
  of cGL_FLOAT:
    return 4
  else:
    raise newException(EUnsupportedAttribType, "coudl not get type size")
proc SetUpAttribArray(program, vao, verts, indices: GLuint; nimtyp: typedesc[tuple | object]) =
  var typInst: ptr nimtyp = cast[ptr nimtyp](nil)
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
    assert(ConfirmTypesMatch(typ, type(val)))
    glVertexAttribPointer(attribLoc.GLuint, len, typ, false, GLsizei(sizeof(typ) * len), cast[pointer](addr val))
    inc(attribIdx)
proc SetUpAttribArray(program, vao, verts, indices: GLuint, nimtyp: typedesc) =
  var activeAttribs: GLint
  glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES, addr activeAttribs)
  var offset = 0
  var stride = 0
  glBindVertexArray(vao)
  glBindBuffer(GL_ARRAY_BUFFER, verts)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indices)
  for i in 0..activeAttribs - 1:
    var (typ, len) = GetAttribInfo(program, i.GLuint)
    assert(ConfirmTypesMatch(typ, nimtyp))
    stride = stride + sizeof(nimtyp) * len
  for i in 0..activeAttribs - 1:
    var (typ, len) = GetAttribInfo(program, i.GLuint)
    glEnableVertexAttribArray(i.GLuint)
    glVertexAttribPointer(i.GLuint, len, typ, false, GLsizei(stride), cast[pointer](offset))
    offset = offset + sizeof(nimtyp) * len
  glBindVertexArray(0)
  glBindBuffer(GL_ARRAY_BUFFER, 0)


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
