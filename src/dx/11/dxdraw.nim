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
import d3d11

## we always use instanced rendering, possibly with
## only one instance. This structure contains
## all the data needed to actually issue a draw call
## and indeed if put in a buffer could presumably be used
## for an indirect draw
type TDrawIndexedInstancedCommand* = object
  uint32 IndexCountPerInstance
  uint32 InstanceCount
  uint32 StartIndexLocation
  int32 BaseVertexLocation
  uint32 StartInstanceLocation

type TVertexShaderObject = object
  vs: ptr ID3D11VertexShader
  constants: seq[ptr ID3D11Buffer]
  texViews: seq[ptr ID3D11ShaderResourceView]
  samplers: seq[ptr ID3D11SamplerState]
type TPixelShaderObject = object
  ps: ptr ID3D11PixelShader
  constants: seq[ptr ID3D11Buffer]
  texViews: seq[ptr ID3D11ShaderResourceView]
  samplers: seq[ptr ID3D11SamplerState]
type TDrawObject* = object
  vs: TVertexShaderObject
  ps: TPixelShaderObject
  vertexBuffer: ptr ID3D11Buffer
  indexBuffer: ptr ID3D11Buffer
  inputLayout: ptr ID3D11InputLayout

