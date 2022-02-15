# ImKivy 

An attempt to implement a Kivy-esque api around ImGui. 

Here's a code sample: 


```nim
import macros
import imkivy

widget ExampleWindow:
  # Simple window
  object:
    show_demo: bool
    somefloat: float32
    counter: int

  Window("Hello, world!"):
    Text: "This is some useful text."
    Checkbox("Demo Window", self.show_demo)
    Slider("float", self.somefloat)

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
```