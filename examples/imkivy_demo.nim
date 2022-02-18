# Copyright 2019, NimGL contributors.

import imgui, imgui/[impl_opengl, impl_glfw]
import nimgl/[opengl, glfw]
import std/math

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
        onPress: self.counter.inc()
      ShowWhen((self.counter mod 2) == 1):
        Text("Thanks for clicking me! ")

    Checkbox("checkbox", self.check)

    RadioButtons(self.radio2, horiz=true):
      ("radio a", 0)
      ("radio b", 1)
      ("radio c", 2)

    Text("radio: %d", self.radio2)

    for clr in PrimaryColors.low..PrimaryColors.high:
      if clr.ord > 0: SameLine()
      WidgetUniqueId(clr.ord):
        withColor(clr):
          if Button("Click"):
            echo "Clicked: ", clr

    igAlignTextToFramePadding()

    Horizontal:
      Text("Hold to repeat:")
      ArrowButton("##left"):
        repeat: true
        dir: ImGuiDir.Left
        onPress: self.rptCounter.dec()
      ArrowButton("##right"):
        repeat: true
        dir: ImGuiDir.Right
        onPress: self.rptCounter.inc()
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
    SliderInput("slider float deg", self.sliderFloat3, rng = -360'f32..360'f32, format = "%.3f def")

    # PlotDataLines("Frame Times", arr)
    # PlotHistogram("Histogram", arr, IM_ARRAYSIZE(arr), 0, NULL, 0.0f, 1.0f, ImVec2(0, 80.0f));

    # const char* elems_names[Element_COUNT] = { "Fire", "Earth", "Air", "Water" };
    # const char* elem_name = (elem >= 0 && elem < Element_COUNT) ? elems_names[elem] : "Unknown";
    SliderInput("slider enum", self.sliderElement)
    let listItems = ["Apple", "Banana", "Cherry", "Kiwi", "Mango", "Orange", "Pineapple", "Strawberry", "Watermelon"]
    ListBox("listbox", self.listIndex, listItems)
    ShowOnItemIsHovered:
      SetTooltip("list box item: " & listItems[self.listindex])

widget WidgetsPlots:
  object:
    animate: bool
    refresh_time: float32
    values: array[120, float32]
    values2: array[200, float32]
    values3: array[200, float32]
    values_offset: int32
    values_offset2: int32
    phase: float32
    phase2: float32

  # Simple window
  CollapsingHeader("Plots"):
    Checkbox("Animate", self.animate)

    let arr = [0.6f, 0.1f, 1.0f, 0.5f, 0.92f, 0.1f, 0.2f]
    PlotDataLines("Frame Times", arr)
    PlotDataHistogram("Histogram", arr)

    #// Fill an array of contiguous float values to plot
    #// Tip: If your float aren't contiguous but part of a structure, you can pass a pointer to your first float
    #// and the sizeof() of your structure in the "stride" parameter.

    if not self.animate or self.refresh_time == 0.0'f32:
      self.refresh_time = igGetTime()

    if self.animate:
      self.values[self.values_offset] = cos(self.phase)/3.0
      self.values2[self.values_offset2] = sin(self.phase2)
      self.values3[self.values_offset2] = 1.0/3.0 * self.values2[self.values_offset2] 
      self.values_offset = (self.values_offset + 1) mod len(self.values).int32
      self.values_offset2 = (self.values_offset2 + 1) mod len(self.values2).int32
      self.phase += 0.10'f32 * self.values_offset.toFloat()
      self.phase2 += 0.17'f32 * self.values_offset2.toFloat()
      self.refresh_time += 1.0'f32 / 60.0'f32
    
    var average = 0.0
    for n in 0..<len(self.values): average += self.values[n]
    average /= len(self.values).toFloat()
    var overlay = "avg " & $average
    PlotDataLines("Lines", self.values, self.values_offset,
                  overlay, -1.0f, 1.0f, ImVec2(x: 0'f32, y: 80.0'f32))
    PlotDataLines("Lines2", self.values2, self.values_offset2,
                  overlay, -1.0f, 1.0f, ImVec2(x: 0'f32, y: 120.0'f32))
    PlotDataLines("Lines3", self.values3, self.values_offset2,
                  overlay, -1.0f, 1.0f, ImVec2(x: 0'f32, y: 120.0'f32))

widget WidgetsOther:
  object:
    intVal: int32
    values: array[7, float32]

  CollapsingHeader("Vertical Sliders"):
    let spacing = 4.0'f32
    withStyle(ItemSpacing, ImVec2(x: 4*spacing, y: spacing)):
      Slider("##int", self.intVal):
        rng: 0'i32..5'i32
        orient: Orient(dir: Vert, size: ImVec2(x: 28, y: 160))
      SameLine()

    # Colored Sliders
    for clr in PrimaryColors.low..PrimaryColors.high:
      WidgetUniqueId(clr.ord()):
        withColor(clr):
          Slider("##v", self.values[clr.ord]):
            rng: 0.0'f32..1.0'f32
            orientation: Orient(dir: Vert, size: ImVec2(x: 28, y: 160))
          ShowOnItemIsHovered:
            SetTooltip("%.3f", self.values[clr.ord])
        SameLine()
    
    # Debug button
    Button("Button"):
      size: (50, 20)
      onPress: 
        echo "vertial sliders: ", repr(self.values)

ImKivyMain():

  var show_demo: bool = true
  var bdData = WidgetsBasicData()
  var plData = WidgetsPlotsData(animate: true)
  let values: array[7, float32] = [0.0'f32, 0.60, 0.35, 0.9, 0.70, 0.20, 0.0]
  var woData = WidgetsOtherData(values: values)

  let fonts: ptr ImFontAtlas = igGetIO().fonts
  # fonts.addFontDefault()
  fonts.addFontFromFileTTF("Roboto-Medium.ttf", 16.0)

  ImKivyLoop:
    if show_demo:
      igShowDemoWindow(show_demo.addr)


    Window("Hello, world!"):

      Text("Application average %.3f ms/frame (%.1f FPS)",
           1000.0f / igGetIO().framerate, igGetIO().framerate)
      Button("Button"):
        size: (50, 20)
        onPress: 
          echo "demoData: ", repr(bdData)

    Window("Widgets"):
      WidgetsBasic(bdData)
      WidgetsPlots(plData)
      WidgetsOther(woData)

run()