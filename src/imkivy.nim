import macros
import sugar

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

macro mkUniqueId*(line: untyped): untyped =
  ItemIds.inc()
  var itemid = ItemIds.int32 
  result = newStmtList()
  result = quote do:
    igPushID(`itemid`)
    `line`
    igPopId()
  echo "mkUniqueId: ", result.repr

template Button*(text: string) = igButton(text)

macro Button*(label: string, blk: untyped) =
  # echo "button: blk: ", blk.treeRepr
  var onPressAct: NimNode
  var sizeProp: NimNode

  for code in blk:
    if code.kind == nnkCall:
      var name = code[0]
      case name.repr:
      of "on_press":
        onPressAct = code[1]
      of "size":
        let val = code[1]
        sizeProp = quote do:
          let sz = `val`
          ImVec2(x: sz[0].toFloat(), y: sz[1].toFloat())

  # btncnt.inc()
  # var btnid = btncnt 
  if sizeProp.isNil:
    result = quote do:
      mkUniqueId():
        if igButton(`label`):
          `onPressAct`
  else:
    result = quote do:
      mkUniqueId():
        if igButton(`label`, `sizeProp`):
          `onPressAct`

template Slider*(label: string, val: var float, min = 0.0, max = 1.0) =
  igSliderFloat(label, val.addr, min, max)

template RadioButton*(label: string, idx: var int32, val: int) =
  mkUniqueId():
    igRadioButton(label, idx.addr, val)

template ShowWhen*(val: bool, blk: untyped) =
  if val: blk else: Text("")

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
  echo "radiobuttons: ", result.repr

template RadioButton*(label: string, idx: var int32, val: int) =
  mkUniqueId():
    igRadioButton(label, idx.addr, val)

macro Horizontal*(blk: untyped) =
  result = newStmtList()
  for idx, child in blk.pairs():
    result.add child
    if idx + 1 < blk.len():
      result.add quote do:
        igSameLine()
  # result.add quote do: igNewLine()

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
    var name = field[0].repr
    var kind = field[1][0].repr
    elems.add nnkIdentDefs.newTree(
      newIdentNode(name),
      newIdentNode(kind),
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
