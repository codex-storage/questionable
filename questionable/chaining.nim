import std/macros

template `?.`*(option: typed, identifier: untyped{nkIdent}): untyped =
  option ->? option.unsafeGet.identifier

macro `?.`*(option: typed, infix: untyped{nkInfix}): untyped =
  let left = infix[1]
  infix[1] = quote do: `option`?.`left`
  infix

macro `?.`*(option: typed, bracket: untyped{nkBracketExpr}): untyped =
  let left = bracket[0]
  bracket[0] = quote do: `option`?.`left`
  bracket

macro `?.`*(option: typed, dot: untyped{nkDotExpr}): untyped =
  let left = dot[0]
  dot[0] = quote do: `option`?.`left`
  dot

macro `?.`*(option: typed, call: untyped{nkCall}): untyped =
  let procedure = call[0]
  if call.len > 1:
    if procedure.kind == nnkDotExpr:
      let (inner, outer) = (procedure[0], procedure[1])
      call[0] = outer
      call.insert(1, quote do: `option`?.`inner`)
      call
    else:
      call.insert(1, quote do: `option`.unsafeGet)
      quote do: `option` ->? `call`
  else:
      quote do: `option`?.`procedure`
