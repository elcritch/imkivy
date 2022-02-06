# Copyright 2019, NimGL contributors.

import imgui, imgui/[impl_opengl, impl_glfw]
import nimgl/[opengl, glfw]

import imkivy
import imkivy/window

import example_window

import std/os, std/times, std/monotimes

widget WidgetsBasic:
  object:
    counter: uint
    check: bool
    radio: int32
    radio2: int32
    rptCounter: int32

  # Simple window
  Window("Widgets"):
    CollapsingHeader("Basic"):

      Horizontal:
        Button("Button"):
          on_press: self.counter.inc()
        ShowWhen((self.counter mod 2) == 1):
          Text("Thanks for clicking me! ")

      Checkbox("checkbox", self.check)

      Horizontal:
        RadioButton("radio a", self.radio, 0)
        RadioButton("radio b", self.radio, 1)
        RadioButton("radio c", self.radio, 2)

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
        igPushButtonRepeat(true)
        ArrowButton("##left"):
          dir: ImGuiDir.Left
          on_press: self.rptCounter.dec()
        ArrowButton("##right"):
          dir: ImGuiDir.Right
          on_press: self.rptCounter.inc()
        igPopButtonRepeat()
        Text("%d", self.rptCounter)

KivyMain():

  var show_demo: bool = true
  var bdData = WidgetsBasicData()

  KivyLoop:
    if show_demo:
      igShowDemoWindow(show_demo.addr)

    Window("Hello, world!"):
      WidgetsBasic(bdData)

      Button("Button"):
        size: (50, 20)
        on_press: 
          echo "demoData: ", repr(bdData)


run()