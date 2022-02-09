# Copyright 2019, NimGL contributors.

import imgui, imgui/[impl_opengl, impl_glfw]
import nimgl/[opengl, glfw]

import imkivy
import imkivy/window

import example_window

import std/os, std/times, std/monotimes

type
  Element* = enum
    Fire, Earth, Air, Water

widget WidgetsBasic:
  object:
    counter: uint
    check: bool
    radio: int32
    radio2: int32
    rptCounter: int32
    itemCurrent: int32
    str0: string
    inputInt: int32
    inputInt3: array[3, int32]
    inputFloat: float32
    inputFloat4: array[4, float32]
    dragInt: int32
    dragFlt: float32
    sliderInt: int32
    sliderFloat: float32
    sliderFloat2: float32
    sliderFloat3: float32
    sliderElement: Element
    listIndex: int32

  # Simple window
  CollapsingHeader("Basic"):

    Horizontal:
      Button("Button"):
        on_press: self.counter.inc()
      ShowWhen((self.counter mod 2) == 1):
        Text("Thanks for clicking me! ")

    Checkbox("checkbox", self.check)

    RadioButtons(self.radio2, horiz=true):
      ("radio a", 0)
      ("radio b", 1)
      ("radio c", 2)

    Text("radio: %d", self.radio2)

    for i in 0..<7:
      let fi = i.toFloat()
      if i > 0: SameLine()
      WidgetUniqueId():
        PushStyleColor(ImGuiCol.Button, ImColorHSV(fi / 7.0f, 0.6f, 0.6f))
        PushStyleColor(ImGuiCol.ButtonHovered, ImColorHSV(fi / 7.0f, 0.7f, 0.7f))
        PushStyleColor(ImGuiCol.ButtonActive, ImColorHSV(fi / 7.0f, 0.8f, 0.8f))
        Button("Click")
        PopStyleColor(3)

    igAlignTextToFramePadding()

    Horizontal:
      Text("Hold to repeat:")
      ArrowButton("##left"):
        repeat: true
        dir: ImGuiDir.Left
        on_press: self.rptCounter.dec()
      ArrowButton("##right"):
        repeat: true
        dir: ImGuiDir.Right
        on_press: self.rptCounter.inc()
      Text("%d", self.rptCounter)

    Horizontal:
      Text("Hover over me")
      ShowOnItemIsHovered:
        SetTooltip("I am a tooltip")
      Text("- or me")
      ShowOnItemIsHovered:
        Tooltip:
          Text("I am a fancy tooltip")
          let arr = [0.6'f32, 0.1f, 1.0f, 0.5f, 0.92f, 0.1f, 0.2f]
          PlotDataLines("Curve", arr)

    Separator()
    LabelText("label", "Value")

    let items = ["AAAA", "BBBB", "CCCC", "DDDD", "EEEE", "FFFF", "GGGG", "HHHH", "IIIIIII", "JJJJ", "KKKKKKK"]
    Combo("combo", self.itemCurrent, items)

    Input("input text", self.str0, 5)
    Input("input int", self.inputInt)
    Input("input int", self.inputInt3)
    Input("input float", self.inputFloat)
    Input("input float4", self.inputFloat4)
    Input("input scientific:", self.inputFloat, step=0.1'f32, format = "%e")
    DragInput("drag int", self.dragInt, rng = -100'i32..100'i32)
    DragInput("drag float", self.dragFlt, rng = -100'f32..100'f32)
    SliderInput("slider int", self.sliderInt, rng = -100'i32..100'i32)
    SliderInput("slider float", self.sliderFloat, rng = -100'f32..100'f32)
    SliderInput("slider float log", self.sliderFloat2, rng = -100'f32..100'f32, flags=Logarithmic)
    SliderAngle("slider float deg", self.sliderFloat3)
    # PlotDataLines("Frame Times", arr)
    # PlotHistogram("Histogram", arr, IM_ARRAYSIZE(arr), 0, NULL, 0.0f, 1.0f, ImVec2(0, 80.0f));

    # const char* elems_names[Element_COUNT] = { "Fire", "Earth", "Air", "Water" };
    # const char* elem_name = (elem >= 0 && elem < Element_COUNT) ? elems_names[elem] : "Unknown";
    SliderInput("slider enum", self.sliderElement)
    let listItems = ["Apple", "Banana", "Cherry", "Kiwi", "Mango", "Orange", "Pineapple", "Strawberry", "Watermelon"]
    ListBox("listbox", self.listIndex, listItems)
    ShowOnItemIsHovered:
      SetTooltip("list box item: " & listItems[self.listindex])

ImKivyMain():

  var show_demo: bool = true
  var bdData = WidgetsBasicData()

  ImKivyLoop:
    if show_demo:
      igShowDemoWindow(show_demo.addr)


    Window("Hello, world!"):

      Text("Application average %.3f ms/frame (%.1f FPS)",
           1000.0f / igGetIO().framerate, igGetIO().framerate)
      Button("Button"):
        size: (50, 20)
        on_press: 
          echo "demoData: ", repr(bdData)

    Window("Widgets"):
      WidgetsBasic(bdData)
      # WidgetsPlots(plData)

run()