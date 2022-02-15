import macros
import imkivy
import imkivy/window

widget ExampleWindow:
  # Simple window
  object:
    show_demo: bool
    somefloat: float32
    counter: int

  Window("Hello, world!"):
    Text: "This is some useful text."
    Checkbox("Demo Window", self.show_demo)
    Slider("float", self.somefloat, rng = 0'f32..1.0'f32)

    Horizontal:
      Button("Button"):
        size: (50, 20)
        on_press: inc(self.counter)
      Button("Button"):
        size: (50, 20)
        on_press: inc(self.counter)
      Text("counter = %d", self.counter)

    Text("Application average %.3f ms/frame (%.1f FPS)",
         1000.0f / igGetIO().framerate, igGetIO().framerate)

when isMainModule:
  ImKivyMain():
    var show_demo: bool = true
    var bdData = ExampleWindowData()

    ImKivyLoop:
      ExampleWindow(bdData)

  run()