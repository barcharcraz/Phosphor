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
import tables
import logging
import hashes
import unsigned
import sets
import glattribgen
import glprogram
## implements draw data objects which store all the state reuqired for
## issueing a draw call, these are designed to be simpler and less error prone than
## all the binding stuff usually required
type TDrawElementsIndirectCommand* = object
  count: uint32
  primCount: uint32
  firstIndex: uint32
  baseVertex: uint32
  baseInstance: uint32
type TDrawCommand* = object
  mode: GLenum
  idxType: GLenum
  command: TDrawElementsIndirectCommand
type TDrawObject* = object
  program: GLuint
  drawCommand: TDrawCommand
  VertexBuffer: GLuint
  IndexBuffer: GLuint
  VertexAttributes: GLuint
  uniforms: seq[GLuint] ## sequence of uniform blocks, index is uniform block binding
  textures: seq[tuple[typ: GLenum, id: GLuint]] ## sequence of textures index is texture unit
  opaqueTypes: TTable[GLint, GLint] ## pairs of (location, value) for things to be bound to samplers
                                     ## the value is the texture unit

type TSamplerData = object
  location: GLint
  typ: GLenum
type TProgramData = object
  uniformBlocks: TTable[string, GLuint]
  opaqueNames: TTable[string, TSamplerData]

type EIdentifierTooLong = object of ESynch
type EUnsupportedSamplerType = object of Esynch
type ENameNotFound = object of ESynch
proc initProgramData(): TProgramData =
  result.uniformBlocks = initTable[string, GLuint]()
  result.opaqueNames = initTable[string, TSamplerData]()

const SamplerTypes = {GL_SAMPLER_1D, GL_SAMPLER_2D, GL_SAMPLER_3D, GL_SAMPLER_CUBE, GL_SAMPLER_1D_SHADOW, GL_SAMPLER_2D_SHADOW}
proc findTexTypeOfSampler(program, sampler: GLuint): GLenum =
  var sampler = sampler
  var typ: GLint
  glGetActiveUniformsiv(program, 1, addr sampler, GL_UNIFORM_TYPE, addr typ)
  case typ
  of GL_SAMPLER_1D: return GL_TEXTURE_1D
  of GL_SAMPLER_2D: return GL_TEXTURE_2D
  of GL_SAMPLER_3D: return GL_TEXTURE_3D
  of GL_SAMPLER_CUBE: return GL_TEXTURE_CUBE_MAP
  of GL_SAMPLER_1D_SHADOW: return GL_TEXTURE_1D
  of GL_SAMPLER_2D_SHADOW: return GL_TEXTURE_2D
  else: raise newException(EUnsupportedSamplerType, "sampler type is not supported")
proc initProgramData(program: GLuint): TProgramData =
  result = initProgramData()
  var indices: GLint
  var blockName: array[1..100, GLchar]
  var blockNameLength: GLsizei
  glGetProgramiv(program, GL_ACTIVE_UNIFORM_BLOCKS, addr indices)
  if indices != 0:
    for i in 0..indices - 1:
      glGetActiveUniformBlockName(program, i.GLuint, len(blockName).GLsizei, addr blockNameLength, addr blockName[1])
      if blockNameLength >= len(blockName):
        raise newException(EIdentifierTooLong, "max GLSL uniform identifier length is 99 chars")
      echo($(addr blockName[1]))
      result.uniformBlocks[$(addr blockName[1])] = i.GLuint
      glUniformBlockBinding(program, i.GLuint, i.GLuint)
  glGetProgramiv(program, GL_ACTIVE_UNIFORMS, addr indices)
  echo indices
  if indices != 0:
    for i in 0..indices - 1:
      var uniformType: GLint
      var idx = i.GLuint # we need to do this to take the address of the variable
      glGetActiveUniformsiv(program, 1, addr idx, GL_UNIFORM_TYPE, addr uniformType)
      if uniformType in SamplerTypes:
        glGetActiveUniformName(program, i.GLuint, len(blockName).GLsizei, addr blockNameLength, addr blockName[1])
        if blockNameLength >= len(blockName):
          raise newException(EIdentifierTooLong, "max GLSL uniform name length is 99 chars")
        result.opaqueNames[$(addr blockName[1])] = TSamplerData(location: i, typ: findTexTypeOfSampler(program, i.GLuint))

proc initDrawElementsIndirectCommand*(): TDrawElementsIndirectCommand =
  result.count = 0
  result.primCount = 1
  result.firstIndex = 0
  result.baseVertex = 0
  result.baseInstance = 0
proc initDrawCommand*(): TDrawCommand =
  result.command = initDrawElementsIndirectCommand()
  result.idxType = GL_UNSIGNED_INT
  result.mode = GL_TRIANGLES

proc hash*(x:GLuint): THash = hash(x.int)
var programinfo = initTable[GLuint, TProgramData]()
## the ownedUBOs set consists of all the UBOs that we created
## when somebody assigned a nimrod object to a uniform in the shader
var ownedBuffers = initSet[GLuint]()
proc initDrawObject*(program: GLuint): TDrawObject =
  if not programinfo.hasKey(program):
    programinfo[program] = initProgramData(program)
  result.program = program
  glGenVertexArrays(1, addr result.VertexAttributes)
  result.drawCommand = initDrawCommand()
  newSeq(result.uniforms, len(programinfo[program].uniformBlocks))
  result.opaqueTypes = initTable[GLint, GLint]()
  result.textures = @[]
proc SetVertexBuffer(self: var TDrawObject, val: GLuint) = 
  if self.VertexBuffer in ownedBuffers:
    ownedBuffers.excl(self.VertexBuffer)
    glDeleteBuffers(1, addr self.VertexBuffer)
  self.VertexBuffer = val
proc SetIndexBuffer(self: var TDrawObject, val: GLuint) =
  if self.IndexBuffer in ownedBuffers:
    ownedBuffers.excl(self.IndexBuffer)
    glDeleteBuffers(1, addr self.IndexBuffer)
  self.IndexBuffer = val

proc SetUniformBuffer(self: var TDrawObject, name: string, val: GLuint) =
  var info = addr programinfo.mget(self.program)
  var binding = info.uniformBlocks.mget(name)
  var oldBuffer = self.uniforms[binding.int]
  if oldBuffer in ownedBuffers:
    ownedBuffers.excl(oldBuffer)
    glDeleteBuffers(1, addr oldBuffer)
  self.uniforms[binding.int] = val

proc UpdateBuffer(typ: GLenum, buff: GLuint, val: ptr, num: int) =
  var size: GLint
  glBindBuffer(typ, buff)
  glGetBufferParameteriv(typ, GL_BUFFER_SIZE, addr size)
  if (sizeof(type(val[])) * num) > size:
    glBufferData(typ, (sizeof(type(val[])) * num).GLsizeiptr, cast[pointer](val), GL_STATIC_DRAW)
  else:
    glBufferSubData(typ, 0.GLintPtr, (sizeof(type(val[])) * num).GLsizeiptr, cast[pointer](val))
  glBindBuffer(typ, 0)

proc UpdateUniformBuffer(self: var TDrawObject, name: string, val: ptr, num: int) =
  var info = mget(programinfo, self.program)
  var bindingLoc = info.uniformBlocks[name]
  var ubo = self.uniforms[bindingLoc.int]
  assert(ubo in ownedBuffers)
  UpdateBuffer(GL_UNIFORM_BUFFER, ubo, val, num)

proc SetUniformBuffer(self: var TDrawObject, name: string, val: ptr, num: int) =
  var info = mget(programinfo, self.program)
  var bindingLoc = info.uniformBlocks[name]
  var ubo = self.uniforms[bindingLoc.int]
  if ubo notin ownedBuffers:
    var buffer: GLuint
    glGenBuffers(1, addr buffer)
    SetUniformBuffer(self, name, buffer)
    incl(ownedBuffers, buffer)
  UpdateUniformBuffer(self, name, val, num)


proc SetUniformBuffer(self: var TDrawObject, name: string, val: var) =
  SetUniformBuffer(self, name, addr val, 1)
proc SetUniformBuffer[T](self: var TDrawObject, name: string, vals: var openarray[T]) =
  SetUniformBuffer(self, name, addr vals[0], len(vals))

proc SetVertexBuffer[T](self: var TDrawObject, vals: var openarray[T]) =
  if self.VertexBuffer in ownedBuffers:
    UpdateBuffer(GL_ARRAY_BUFFER, self.VertexBuffer, addr vals[0], vals.len)
  else:
    assert(self.VertexAttributes != 0.GLuint)
    var buffer = CreateVertexInputs(self.program, self.VertexAttributes, vals)
    SetVertexBuffer(self, buffer)
    incl(ownedBuffers, buffer)
proc SetIndexBuffer[T](self: var TDrawObject, vals: var openarray[T]) =
  self.drawCommand.command.count = vals.len.uint32
  if self.IndexBuffer in ownedBuffers:
    UpdateBuffer(GL_ELEMENT_ARRAY_BUFFER, self.IndexBuffer, addr vals[0], vals.len)
  else:
    assert(self.VertexAttributes != 0.GLuint)
    var buffer = CreateIndexInputs(self.program, self.VertexAttributes, vals)
    SetIndexBuffer(self, buffer)
    incl(ownedBuffers, buffer)

proc SetSamplerTexture(self: var TDrawObject, name: string, val: GLuint) =
  ## val is a texture handle, the assumption is that the texture has the correct type
  var info = addr programinfo.mget(self.program)
  var samplerInfo = info.OpaqueNames.mget(name)
  var newTex = (samplerInfo.typ, val)
  proc `==`(a,b: tuple[typ: GLenum, id: GLuint]): bool = a.id == b.id
  var texIdx = find(self.textures, newTex)
  if texIdx == -1:
    self.textures.add(newTex)
    texIdx = self.textures.high
  else:
    assert(self.textures[texIdx].typ == samplerInfo.typ)
  # make sure that there are no un-used textures
  if self.opaqueTypes.hasKey(samplerInfo.location):
    var oldTex = self.opaqueTypes[samplerInfo.location]
    self.opaqueTypes[samplerInfo.location] = -1
    # iterate over all the samplers we have 
    # in order to see if any of the others use
    # the same texture, if not we can reuse that
    # image unit
    # this a slowish operation but it is not common
    # and there will probably never be hundreds of samplers
    var isInUse = false
    for tex in self.opaqueTypes.values:
      if tex == oldTex: isInUse = true
    if not isInUse and texIdx == -1:
      # we were going to add the texture to the end of the textures array, but
      # we found that the old texture being used by the sampler was not used by anyone
      # else, so we use that image unit instead
      texIdx = oldTex
      self.textures[texIdx] = newTex
    elif not isInUse:
      # if the texture is not being used by anyone else
      # and we don't need a new texture slot for the new texture
      # then we go and set all samplers referenceing the last texture
      # to refernce the old texture unit and we swap them and delete
      # the old texture from the end of the textures array
      var highId = self.textures[self.textures.high].id
      for i,elm in self.opaqueTypes:
        if elm == highId.GLint:
          self.opaqueTypes[i] = oldTex
      self.textures.del(oldTex)
  # if we need to add the texture to the end then do it now
  if texIdx == -1:
    self.textures.add(newTex)
    texIdx = self.textures.high
  self.opaqueTypes[samplerInfo.location] = texIdx.GLint


proc BindDrawObject(obj: TDrawObject) =
  glUseProgram(obj.program)
  for i,elm in obj.uniforms:
    glBindBufferBase(GL_UNIFORM_BUFFER, i.GLuint, elm)
  for i,elm in obj.textures:
    glActiveTexture(GLenum(GL_TEXTURE0 + i))
    glBindTexture(elm.typ, elm.id)
  for key, elm in obj.opaqueTypes:
    glUniform1i(key, elm)
proc DrawBundle*(bundle: var TDrawObject) =
  BindDrawObject(bundle)
  glBindVertexArray(bundle.VertexAttributes)
  #glDrawElementsIndirect(bundle.drawCommand.mode, bundle.drawCommand.idxType, addr bundle.drawCommand.command)
  glDrawElements(bundle.drawCommand.mode, bundle.drawCommand.command.count.GLsizei,
                 bundle.drawCommand.idxType, nil)


## Public interface for setting various things
proc `vertices=`*[T](self: var TDrawObject, verts: var openarray[T]) =
  SetVertexBuffer(self, verts)
proc `indices=`*[T](self: var TDrawObject, indices: var openarray[T]) =
  SetIndexBuffer(self, indices)
proc SetShaderValue[T](self: var TDrawObject, name: string, val: var T) =
  var info = mget(programinfo, self.program)
  if hasKey(info.uniformBlocks, name):
    SetUniformBuffer(self, name, val)
  elif hasKey(info.opaqueNames, name):
    SetSamplerTexture(self, name, val)
  else:
    raise newException(ENameNotFound, "name not found in shader")
proc `.=`*[T](self: var TDrawObject, name: string, val: T) = 
  when T is var:
    SetShaderValue(self, name, val)
  else:
    var val = val
    SetShaderValue(self, name, val)
