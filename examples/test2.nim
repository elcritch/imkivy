# Copyright 2019, NimGL contributors.

import imgui, imgui/[impl_opengl, impl_glfw]
import nimgl/[opengl, glfw]

import imkivy
import imkivy/window

import example_window
import demo_window

import std/os, std/times, std/monotimes

KivyMain():

  var style = igGetStyle()
  style.framePadding = ImVec2(x: 5, y: 5) 
  style.cellPadding = ImVec2(x: 7, y: 4) 
  style.itemSpacing = ImVec2(x: 11, y: 5) 
  style.itemInnerSpacing = ImVec2(x: 7, y: 2) 
  style.scrollbarSize = 24.0
  style.grabMinSize = 24.0

  var show_demo: bool = true
  
  var exData = ExampleWindowData()
  var demoData = WidgetsBasicData()

do:
    glfwPollEvents()

    igOpenGL3NewFrame()
    igGlfwNewFrame()
    igNewFrame()

    if show_demo:
      igShowDemoWindow(show_demo.addr)

    Window("Hello, world!"):
      ExampleWindow(exData)
      WidgetsBasic(demoData)
      Button("Button"):
        size: (50, 20)
        on_press: 
          echo "demoData: ", repr(demoData)


main()