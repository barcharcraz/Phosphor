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

type EAttribNameNotFound = object of Exception
type EUnsupportedAttribType = object of Exception
type EAttribNameTooLong = object of Exception
type TAttributeInfo = object
  typ: GLenum
  size: GLint
  name: string
  location: GLint
proc GetAttribInfo(program, attrib: GLuint): TAttributeInfo =
  var numAtts: GLint
  var nameBuffer: array[100, GLchar]
  var writtenLen: GLint
  glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES, addr numAtts)
  for i in 0..numAtts-1:
    glGetActiveAttrib(program, i.GLuint, 100,
      addr writtenLen,
      addr result.size,
      addr result.typ,
      addr nameBuffer[0])
  if writtenLen == 100:
    raise newException(EAttribNameTooLong,
      "Attribute names must be less than 100 characters")
  result.name = $cast[cstring](addr nameBuffer[0])
  result.location = glGetAttribLocation(program, addr nameBuffer[0])
proc GetVectorTypLength(typ: GLenum): GLint =
  case typ
  of cGL_FLOAT: result = 1
  of GL_FLOAT_VEC2: result = 2
  of GL_FLOAT_VEC3: result = 3
  of GL_FLOAT_VEC4: result = 4
  else: raise newException(EUnsupportedAttribType,
    "attrib type " & repr(typ) & " not supported")
proc GetVectorTypBaseTyp(typ: GLenum): GLenum =
  case typ
  of cGL_FLOAT: return cGL_FLOAT
  of GL_FLOAT_VEC2: return cGL_FLOAT
  of GL_FLOAT_VEC3: return cGL_FLOAT
  of GL_FLOAT_VEC4: return cGL_FLOAT
  else: raise newException(EUnsupportedAttribType,
    "attrib type " & repr(typ) & " not supported")

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
  ## the function is the core of Phosphor's smart(er) binding system
  ## it's generic (ofc) and takes some type, we use compile time magic
  ## to automaticly set up the vao to have an input attirbute of that type
  ## this version of the function works with structs of attribs (AoS style)
  
  # we need a "real" instance of the type to use fieldPairs, we never deref it though
  # we we'll just cast nil to the correct type
  var typInst: ptr nimtyp = cast[ptr nimtyp](nil)
  glBindVertexArray(vao)
  glBindBuffer(GL_ARRAY_BUFFER, verts)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indices)
  var attribIdx = 0.GLuint
  var attribLoc: GLint = -1
  for name, val in fieldPairs(typInst[]):
    # as we find fields we enable the relevant attrib indices
    glEnableVertexAttribArray(attribIdx)
    # we assume that the attribute name in the program
    # matches the name of the field of the struct, perhaps
    # someday there will be an override for this but honestly
    # if you need it you can just make your own VAO
    attribLoc = glGetAttribLocation(program, name)
    if attribLoc == -1:
      raise newException(EAttribNameNotFound, name & " is not an attrib in the program")
    var attribInfo = GetAttribInfo(program, attribLoc.GLuint)
    assert(sizeof(val) == GetSizeOfGLType(attribInfo.typ) * attribInfo.size)
    assert(ConfirmTypesMatch(attribInfo.typ, type(val)))
    glVertexAttribPointer(attribLoc.GLuint,
      attribInfo.size,
      attribInfo.typ,
      false,
      GLsizei(sizeof(attribInfo.typ) * attribInfo.size),
      cast[pointer](addr val))
    inc(attribIdx)

proc SetUpAttribArray(program, vao, verts, indices: GLuint, nimtyp: typedesc) =
  var activeAttribs: GLint
  glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES, addr activeAttribs)
  var offset = 0
  var stride = 0
  glBindVertexArray(vao)
  glBindBuffer(GL_ARRAY_BUFFER, verts)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indices)
  echo "activeAttribs", activeAttribs
  for i in 0..activeAttribs - 1:
    var info = GetAttribInfo(program, i.GLuint)
    # we convert types such as GL_FLOAT_VEC3 to GL_FLOAT
    # TODO: Make sure to check that the array is shaped so that
    # is /could/ be an array of vectors of the right length
    var baseType = GetVectorTypBaseTyp(info.typ)
    assert(ConfirmTypesMatch(baseType, nimtyp))
    echo info.name, info.size, " ", sizeof(nimtyp)
    stride = stride + sizeof(nimtyp) * info.size * GetVectorTypLength(info.typ)
  for i in 0..activeAttribs - 1:
    var info = GetAttribInfo(program, i.GLuint)
    glEnableVertexAttribArray(i.GLuint)
    var vecSize = GetVectorTypLength(info.typ)
    var baseType = GetVectorTypBaseTyp(info.typ)
    glVertexAttribPointer(i.GLuint, info.size * vecSize,
                          baseType, false, GLsizei(stride),
                          cast[pointer](offset))
    offset = offset + sizeof(nimtyp) * info.size * vecSize
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
