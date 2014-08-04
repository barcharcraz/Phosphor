import gldraw
import glprogram
import opengl
import glfw/glfw
import sets, unsigned
const vs = """
#version 440
in vec2 pos;
void main() {
  gl_Position = vec4(pos, 0.5, 1);
}
"""
const ps = """
#version 440
out vec4 outputColor;
void main() {
  //red color
  outputColor = vec4(1, 0, 0, 1);
}
"""
type TVert = object
  pos: array[2, float32]
var verts: array[3, TVert] = [TVert(pos: [0.0'f32, 0.5]),
                              TVert(pos: [0.5'f32, -0.5]),
                              TVert(pos: [-0.5'f32, -0.5])]
var idx: array[3, uint32] = [2'u32,1,0]
proc main() =
  glfw.init()
  var api = initGL_API(glv44, true, true, glpCore, glrNone)
  var wnd = newWin(dim = (w: 640, h: 480), title = "triangle", GL_API=api, refreshRate = 1)

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
