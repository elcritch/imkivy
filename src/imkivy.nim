import macros
import sugar
import strutils

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

template Slider*(label: string, val: var float, min = 0.0, max = 1.0) =
  igSliderFloat(label, val.addr, min, max)

template SameLine*() = igSameLine()
template PushStyleColor*(idx: ImGuiCol, col: ImVec4) = igPushStyleColor(idx, col)
template PopStyleColor*(count: int32) = igPopStyleColor(count)

proc ImColorHSV*(h: float32, s: float32, v: float32, a: float32 = 1.0f): ImVec4 =
  var res: ImColor 
  hSVNonUDT(res.addr, h, s, v, a)
  return res.value

var
  ItemIds {.compileTime.} = 0
  HorizontalMode {.compileTime.} = false


macro mkUniqueId*(line: untyped): untyped =
  ItemIds.inc()
  var itemid = ItemIds.int32 
  result = newStmtList()
  result = quote do:
    igPushID(`itemid`)
    `line`
    igPopId()
  echo "mkUniqueId: ", result.repr

template WidgetUniqueId*(blk: untyped) = mkUniqueId(blk)

macro mkButton(label: string, btn, blk: untyped) =
  var
    onPressAct: NimNode
    sizeProp: NimNode
    dirProp: NimNode
    repeatProp: NimNode

  for code in blk:
    if code.kind == nnkCall:
      var name = code[0]
      case name.repr:
      of "on_press":
        onPressAct = code[1]
      of "repeat":
        repeatProp = code[1]
      of "dir":
        dirProp = code[1]
      of "size":
        let val = code[1]
        sizeProp = quote do:
          let sz = `val`
          ImVec2(x: sz[0].toFloat(), y: sz[1].toFloat())

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

template Slider*(label: string, val: var float, min = 0.0, max = 1.0) =
  igSliderFloat(label, val.addr, min, max)

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

template Combo*(label: string, itemCurrent: var int32, items: openArray[string]) =
  var vals: seq[cstring] = newSeqOfCap[cstring](items.len())
  for item in items:
    vals.add item.cstring
  igCombo(label.cstring, itemCurrent.addr, vals[0].addr, items.len().int32)

template Input*(label: string, text: var string, size: int = -1) =
  var ln: uint
  when size > 0:
    ln = size.uint
  else:
    ln = text.len().uint
  text.setLen(ln)
  igInputText(label.cstring, text.cstring, ln)

template Input*(label: string, val: var array[2, int32], flags = 0.ImGuiInputTextFlags): bool =
  igInputInt2(label.cstring, val, flags)
template Input*(label: string, val: var array[3, int32], flags = 0.ImGuiInputTextFlags): bool =
  igInputInt3(label.cstring, val, flags)
template Input*(label: string, val: var array[4, int32], flags = 0.ImGuiInputTextFlags): bool =
  igInputInt4(label.cstring, val, flags)
template Input*(label: string, val: var int32, step = 1'i32, step_fast = 100'i32, flags = 0.ImGuiInputTextFlags): bool =
  igInputInt(label.cstring, val.addr, step, step_fast, flags)

template Input*(label: string, val: var array[2, float32], format = "%.3f", flags = 0.ImGuiInputTextFlags): bool =
  igInputFloat2(label.cstring, val, format, flags)
template Input*(label: string, val: var array[3, float32], format = "%.3f", flags = 0.ImGuiInputTextFlags): bool =
  igInputFloat3(label.cstring, val, format, flags)
template Input*(label: string, val: var array[4, float32], format = "%.3f", flags = 0.ImGuiInputTextFlags): bool =
  igInputFloat4(label.cstring, val, format, flags)
template Input*(label: string, val: var float32, step = 1.0'f32, step_fast = 10.0'f32, format = "%.3f", flags = 0.ImGuiInputTextFlags): bool =
  igInputFloat(label.cstring, val.addr, step, step_fast, format, flags)

template DragInput*(label: string, val: var float32, vspeed = 0.1'f32, rng = 0'f32..0'f32 , format = "%.3f", flags = 0.ImGuiSliderFlags): bool =
  igDragFloat(label.cstring, val.addr, vspeed, rng.a, rng.b, format, flags)
template DragInput*(label: string, val: var int32, vspeed = 1.0'f32, rng = 0'i32..0'i32, format = "%.3f", flags = 0.ImGuiSliderFlags): bool =
  igDragInt(label.cstring, val.addr, vspeed, rng.a, rng.b, format, flags)

var FLT_MAX {.importc: "__FLT_MAX__", header: "<float.h>".}: float32

template PlotDataLines*(
            label: string,
            data: openArray[float32],
            overlay_text: string = "",
            scale_min: float32 = FLT_MAX,
            scale_max: float32 = FLT_MAX,
            graph_size: ImVec2 = ImVec2(x: 0, y: 0)
          ) =
  igPlotLines(
    label.cstring, data[0].unsafeAddr(), data.len().int32,
    0'i32, overlay_text, scale_min, scale_max, graph_size,
    stride = sizeof(float32).int32)

template PlotDataLines*[T](
            label: string,
            dataProc: proc (data: ptr T, idx: int32): float32 {.cdecl.},
            data: T,
            count: int32,
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
    0'i32, overlay_text,
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

template SetToolTip*(label: string) =
  igSetTooltip(label.cstring)

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
