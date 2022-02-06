# Copyright 2019, NimGL contributors.

import imgui, imgui/[impl_opengl, impl_glfw]
import nimgl/[opengl, glfw]

import imkivy
import imkivy/window

import example_window
import demo_window

import std/os, std/times, std/monotimes

ImKivyMain():

  var show_demo: bool = true
  var exData = ExampleWindowData()

  ImKivyLoop:
    if show_demo:
      igShowDemoWindow(show_demo.addr)

    Window("Hello, world!"):
      ExampleWindow(exData)
      Button("Button"):
        size: (50, 20)
        on_press: 
          echo "demoData: ", repr(demoData)


run()