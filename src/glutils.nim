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

import unsigned
import opengl
type EGraphicsAPI* = object of ESynch
proc EnumString*(val: GLenum): string =
  ## gets the string representation of
  ## `val`
  case val
  of GL_INVALID_ENUM: result = "GL_INVALID_ENUM"
  of GL_INVALID_OPERATION: result = "GL_INVALID_OPERATION"
  of GL_INVALID_VALUE: result = "GL_INVALID_VALUE"
  else: result = "unrecognised enum"
proc CheckError*() =
  var err = glGetError()
  if err != GL_NO_ERROR:
    var errStr = EnumString(err)
    raise newException(EGraphicsAPI, errStr)

