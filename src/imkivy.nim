import macros
import sugar
import strutils
import std/typetraits
import std/enumutils
import std/tables

export sugar, strutils, enumutils

import imgui, imgui/[impl_opengl, impl_glfw]
import nimgl/[opengl, glfw]

export imgui, impl_opengl, impl_glfw
export opengl, glfw
export sugar

template Window*(title: string, blk: untyped) =
  ## window blk
  igBegin(title)
  blk
  igEnd()

macro Text*(args: varargs[untyped]) =
  result = quote do:
    igText(`args`)

template Checkbox*(label: string, val: var bool) =
  igCheckbox(label, val.addr)

template SameLine*() = igSameLine()

proc PushStyleColor*(idx: ImGuiCol, col: ImVec4) =
  igPushStyleColor(idx, col)
proc PopStyleColor*(count: int32) =
  igPopStyleColor(count)
template withStyleColor*(idx: ImGuiCol, col: ImVec4, blk: untyped) =
  igPushStyleColor(idx, col)
  blk
  igPopStyleColor(1)

proc PushStyle*(idx: static[ImGuiStyleVar], col: float32 | ImVec2) =
  for name, field in igGetStyle()[].fieldPairs():
    when name.toLowerAscii() == toLowerAscii($idx):
      static:
        assert field is type(col)
  igPushStyleVar(idx, col)
proc PushStyle*(idx: ImGuiStyleVar, col: ImVec2) =
  igPushStyleVar(idx, col)
proc PopStyle*(count: int32) =
  igPopStyleVar(count)
template withStyle*(idx: untyped, val: untyped, blk: untyped) =
  PushStyle(idx, val)
  blk
  PopStyle(1)

proc ImColorHSV*(h: float32, s: float32, v: float32, a: float32 = 1.0f): ImVec4 =
  var res: ImColor 
  hSVNonUDT(res.addr, h, s, v, a)
  return res.value

var
  ItemIds {.compileTime.} = 100_000
  HorizontalMode {.compileTime.} = false

macro mkUniqueId*(line: untyped): untyped =
  ItemIds.inc()
  var itemid = ItemIds.int32 
  result = quote do:
    igPushID(`itemid`)
    `line`
    igPopId()

macro mkUniqueIdRet*(line: untyped): untyped =
  ItemIds.inc()
  var itemid = ItemIds.int32 
  result = quote do:
    igPushID(`itemid`)
    var res = `line`
    igPopId()
    res

template WidgetUniqueId*(id: int, blk: untyped) =
  igPushID(id.int32)
  `blk`
  igPopId()

template PushID*(id: int) = igPushID(id.int32)
template PopID*() = igPopId()

proc findAttributes*(blk: NimNode): TableRef[string, NimNode] =
  result = newTable[string, NimNode]()
  for item in blk:
    if item.kind == nnkCall:
      var name = item[0].repr
      var code = item[1]
      result[name] = code

macro mkButton(label: string, btn, blk: untyped) =
  var onPressAct, sizeProp, dirProp, repeatProp: NimNode

  for attrName, code in blk.findAttributes().pairs():
    case attrName:
    of "onPress": onPressAct = code
    of "repeat": repeatProp = code
    of "dir": dirProp = code
    of "size":
      sizeProp =
        quote do:
          let sz = `code`
          ImVec2(x: sz[0].toFloat(), y: sz[1].toFloat())
    else:
      error("other: " & attrName)

  var arg1: NimNode =
    if btn.strVal == "igArrowButton": dirProp
    elif btn.strVal == "igButton": sizeProp
    else: nil

  var res = newStmtList()
  if arg1.isNil:
    res = quote do:
      mkUniqueId():
        if `btn`(`label`): `onPressAct`
  else:
    res = quote do:
      mkUniqueId():
        if `btn`(`label`, `arg1`): `onPressAct`
  
  result = newStmtList()
  if repeatProp.isNil:
    result.add res
  else:
    result.add quote do:
      igPushButtonRepeat(`repeatProp`)
      `res`
      igPopButtonRepeat()

template Button*(text: string) = igButton(text)
template Button*(label: string, blk: untyped) =
  mkButton(label, igButton, blk)
template ArrowButton*(label: string, blk: untyped) =
  mkButton(label, igArrowButton, blk)

template RadioButton*(label: string, idx: var int32, val: int) =
  mkUniqueId():
    igRadioButton(label, idx.addr, val)

template Tooltip*(blk: untyped) =
  igBeginTooltip()
  blk
  igEndTooltip()

template Separator*() = igSeparator()
template LabelText*(label, text: string) =
  igLabelText(label.cstring, text.cstring)

proc Combo*(label: string, itemCurrent: var int32, items: openArray[string]): bool {.discardable.} =
  var vals: seq[cstring] = newSeqOfCap[cstring](items.len())
  for item in items:
    vals.add item.cstring
  mkUniqueIdRet: igCombo(label.cstring, itemCurrent.addr, vals[0].addr, items.len().int32)

proc Input*(label: string, text: var string, size: static[int] = -1): bool {.discardable.} =
  var ln: uint
  when size > 0:
    ln = size.uint
  else:
    ln = text.len().uint
  text.setLen(ln)
  mkUniqueIdRet: igInputText(label.cstring, text.cstring, ln)

proc Input*(label: string, val: var array[2, int32], flags = 0.ImGuiInputTextFlags): bool {.discardable.} =
  mkUniqueIdRet: igInputInt2(label.cstring, val, flags)
proc Input*(label: string, val: var array[3, int32], flags = 0.ImGuiInputTextFlags): bool {.discardable.} =
  mkUniqueIdRet: igInputInt3(label.cstring, val, flags)
proc Input*(label: string, val: var array[4, int32], flags = 0.ImGuiInputTextFlags): bool {.discardable.} =
  mkUniqueIdRet: igInputInt4(label.cstring, val, flags)
proc Input*(label: string, val: var int32, step = 1'i32, step_fast = 100'i32, flags = 0.ImGuiInputTextFlags): bool {.discardable.} =
  mkUniqueIdRet: igInputInt(label.cstring, val.addr, step, step_fast, flags)

proc Input*(label: string, val: var array[2, float32], format = "%.3f", flags = 0.ImGuiInputTextFlags): bool {.discardable.} =
  mkUniqueIdRet: igInputFloat2(label.cstring, val, format, flags)
proc Input*(label: string, val: var array[3, float32], format = "%.3f", flags = 0.ImGuiInputTextFlags): bool {.discardable.} =
  mkUniqueIdRet: igInputFloat3(label.cstring, val, format, flags)
proc Input*(label: string, val: var array[4, float32], format = "%.3f", flags = 0.ImGuiInputTextFlags): bool {.discardable.} =
  mkUniqueIdRet: igInputFloat4(label.cstring, val, format, flags)
proc Input*(label: string, val: var float32, step = 1.0'f32, step_fast = 10.0'f32, format = "%.3f", flags = 0.ImGuiInputTextFlags): bool {.discardable.} =
  mkUniqueIdRet: igInputFloat(label.cstring, val.addr, step, step_fast, format, flags)

proc DragInput*(label: string, val: var float32, vspeed = 0.1'f32, rng = 0'f32..0'f32 , format = "%.3f", flags = 0.ImGuiSliderFlags): bool {.discardable.} =
  mkUniqueIdRet: igDragFloat(label.cstring, val.addr, vspeed, rng.a, rng.b, format, flags)
proc DragInput*(label: string, val: var int32, vspeed = 1.0'f32, rng = 0'i32..0'i32, format = "%.3f", flags = 0.ImGuiSliderFlags): bool {.discardable.} =
  mkUniqueIdRet: igDragInt(label.cstring, val.addr, vspeed, rng.a, rng.b, format, flags)

type
  Dirs* = enum Horiz, Vert

  Orient* = object
    case dir*: Dirs
    of Horiz:
      discard
    of Vert:
      size*: ImVec2

macro Slider*(label: untyped, val: untyped; blk: untyped) =
  proc mkParam(a: string, b: NimNode): NimNode = nnkExprEqExpr.newTree(ident(a), b)
  var ncall = nnkCall.newTree(ident "SliderInput")
  ncall.add(mkParam("label", label))
  ncall.add(mkParam("val", val))
  for attrName, code in blk.findAttributes().pairs():
    echo "ATTR: ", attrName
    case attrName:
    of "format": ncall.add mkParam("format", code)
    of "rng": ncall.add mkParam("rng", code)
    of "orientation": ncall.add mkParam("orient", code)
  result = ncall

proc SliderInput*[T: enum](label: string, val: var T;
                           rng = 0'i32..0'i32;
                           orient: Orient = Orient(dir: Horiz),
                          ): bool {.discardable.} =
  mkUniqueId:
    case orient.dir:
    of Horiz:
      result = igSliderInt(label.cstring, cast[ptr int32](val.addr), 0, T.enumLen()-1, $val)
    of Vert:
      result = igVSliderInt(label.cstring, orient.size, cast[ptr int32](val.addr), 0, T.enumLen()-1, $val)

proc SliderInput*(label: string, val: var int32,
                  rng = 0'i32..0'i32;
                  format = "%.3f",
                  orient: Orient = Orient(dir: Horiz),
                  flags = 0.ImGuiSliderFlags): bool {.discardable.} =
  mkUniqueId:
    case orient.dir:
    of Horiz:
      result = igSliderInt(label.cstring, val.addr, rng.a, rng.b, format, flags)
    of Vert:
      result = igVSliderInt(label.cstring, orient.size, val.addr, rng.a, rng.b, format, flags)

proc SliderInput*(label: string, val: var float32,
                  rng = 0'f32..0'f32;
                  format = "%.3f",
                  orient: Orient = Orient(dir: Horiz),
                  log = false,
                  flags = 0.ImGuiSliderFlags): bool {.discardable.} =
  mkUniqueId:
    case orient.dir:
    of Horiz:
      result = igSliderFloat(label.cstring, val.addr, rng.a, rng.b, format, flags)
    of Vert:
      result = igVSliderFloat(label.cstring, orient.size, val.addr, rng.a, rng.b, format, flags)

proc getter(data: pointer, idx: int32, outText: ptr cstring): bool {.cdecl.} =
  var items = cast[ptr UncheckedArray[string]](data)
  outText[] = items[][idx].cstring
  result = true
proc ListBox*(label: string, current_item: var int32, items: openArray[string], height_in_items = -1'i32): bool {.discardable.} =
  mkUniqueIdRet:
    igListBox(label.cstring, current_item.addr, getter, items.addr.pointer, items.len().int32, height_in_items)

var FLT_MAX {.importc: "__FLT_MAX__", header: "<float.h>".}: float32

proc PlotDataLines*(
            label: string,
            data: openArray[float32],
            offset: int32 = 0,
            overlay_text: string = "",
            scale_min: float32 = FLT_MAX,
            scale_max: float32 = FLT_MAX,
            graph_size: ImVec2 = ImVec2(x: 0, y: 0)
          ) =
  igPlotLines(
    label.cstring, data[0].unsafeAddr(), data.len().int32,
    offset, overlay_text, scale_min, scale_max, graph_size,
    stride = sizeof(float32).int32)
proc PlotDataLines*[T](
            label: string,
            dataProc: proc (data: ptr T, idx: int32): float32 {.cdecl.},
            data: T,
            count: int32,
            offset: int32 = 0,
            overlay_text: string = "",
            scale_min: float32 = FLT_MAX,
            scale_max: float32 = FLT_MAX,
            graph_size: ImVec2 = ImVec2(x: 0, y: 0)
          ) =
  igPlotLines(
    label.cstring,
    dataProc,
    data.unsafeAddr(),
    count,
    offset, overlay_text,
    scale_min, scale_max, graph_size,
    stride = sizeof(float32).int32)

proc PlotDataHistogram*(
            label: string,
            data: openArray[float32],
            overlay_text: string = "",
            scale_min: float32 = FLT_MAX,
            scale_max: float32 = FLT_MAX,
            graph_size: ImVec2 = ImVec2(x: 0, y: 0)
          ) =
  igPlotHistogram(
    label.cstring, data[0].unsafeAddr(), data.len().int32,
    0'i32, overlay_text, scale_min, scale_max, graph_size,
    stride = sizeof(float32).int32)
proc PlotDataHistogram*[T](
            label: string,
            dataProc: proc (data: ptr T, idx: int32): float32 {.cdecl.},
            data: T,
            count: int32,
            offset: int32 = 0,
            overlay_text: string = "",
            scale_min: float32 = FLT_MAX,
            scale_max: float32 = FLT_MAX,
            graph_size: ImVec2 = ImVec2(x: 0, y: 0)
          ) =
  igPlotHistogram(
    label.cstring,
    dataProc,
    data.unsafeAddr(),
    count,
    offset, overlay_text,
    scale_min, scale_max, graph_size,
    stride = sizeof(float32).int32)


macro ShowWhen*(val: bool, blk: untyped) =
  if HorizontalMode:
    result = quote do:
      if `val`:
        igSameLine()
        `blk`
  else:
    result = quote do:
      if `val`: `blk`

macro ShowOnItemIsHovered*(blk: untyped) =
  result = quote do:
    if igIsItemHovered():
      `blk`

template SetToolTip*(args: varargs[untyped]) =
  unpackVarargs(igSetTooltip, args)


macro RadioButtons*(variable: int32, horiz: static[bool] = true, values: untyped) =
  var res = newStmtList()
  for idx, val in values.pairs():
    let
      x = val[0]
      y = val[1]
    res.add quote do:
      mkUniqueId():
        igRadioButton(`x`.cstring, `variable`.addr, `y`)
    if horiz and idx + 1 < values.len():
      res.add quote do:
        igSameLine()
  result = newBlockStmt(res)
  # echo "radiobuttons: ", result.repr

macro StopHorizontal*() =
  HorizontalMode = false

macro Horizontal*(blk: untyped) =
  HorizontalMode = true
  result = newStmtList()
  for idx, child in blk.pairs():
    result.add child
    if idx + 1 < blk.len():
      if  blk[idx+1][0].repr().startsWith("Show"):
        continue
      result.add quote do:
        igSameLine()
  result.add quote do:
    StopHorizontal()
  echo "Horizontal: repr: ", result.repr

macro widget*(class: untyped, blk: untyped) =
  var objectFields: NimNode
  var body = newStmtList()
  for code in blk:
    # echo "widget:code: ", code.treeRepr
    if code.kind == nnkCall:
      var name = code[0]
      case name.repr:
      of "object":
        objectFields = code[1]
        # echo "widget:code:defs: ", objectFields.treeRepr
        continue
    body.add code

  var objName = newIdentNode class.repr & "Data"
  var objectDef = quote do:
    type `objName`* = ref object
      id: int
  
  var elems = newSeq[NimNode]()
  for field in objectFields:
    var name = field[0]
    var kind = field[1][0]
    elems.add nnkIdentDefs.newTree(
      name,
      kind,
      newEmptyNode()
    )
  # Change up the `RecList` child
  objectDef[0][^1][0][^1].add(elems)

  var self = newIdentNode "self"
  result = newStmtList()
  result.add objectDef
  result.add quote do:
    proc `class`*(`self`: var `objName`) =
      `body`
  # echo "result:\n", result.treeRepr

template CollapsingHeader*(label: string, blk: untyped): untyped =
  if igCollapsingHeader(label, 0.ImGuiTreeNodeFlags):
    blk
template CollapsingHeader*(label: string, flags: ImGuiTreeNodeFlags, blk: untyped): untyped =
  if igCollapsingHeader(label, flags):
    blk

type
  PrimaryColors* = enum
    Red,
    Yellow,
    Green,
    Teal,
    Blue,
    Magenta

template withColor*(color: PrimaryColors, blk: untyped): untyped =
  let tf = color.ord().toFloat()
  PushStyleColor(FrameBg, ImColorHSV(tf / 7.0, 0.5, 0.5))
  PushStyleColor(FrameBgHovered, ImColorHSV(tf / 7.0f, 0.6f, 0.5f))
  PushStyleColor(FrameBgActive, ImColorHSV(tf / 7.0f, 0.7f, 0.5f))
  PushStyleColor(SliderGrab, ImColorHSV(tf / 7.0f, 0.9f, 0.9f))

  PushStyleColor(ImGuiCol.Button, ImColorHSV(tf / 7.0f, 0.6f, 0.6f))
  PushStyleColor(ImGuiCol.ButtonHovered, ImColorHSV(tf / 7.0f, 0.7f, 0.7f))
  PushStyleColor(ImGuiCol.ButtonActive, ImColorHSV(tf / 7.0f, 0.8f, 0.8f))
  blk
  PopStyleColor(7)