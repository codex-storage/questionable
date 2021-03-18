import std/macros

macro `?`*(expression: typed, brackets: untyped{nkBracket}): untyped =
  # chain is of shape: expression?[index]
  let index = brackets[0]
  quote do:
    type T = typeof(`expression`[`index`])
    try:
      `expression`[`index`].some
    except KeyError:
      T.none

macro `?`*(expression: typed, infix: untyped{nkInfix}): untyped =
  # chain is of shape: expression?left `operator` right
  let left = infix[1]
  infix[1] = quote do: `expression`?`left`
  infix

macro `?`*(expression: typed, bracket: untyped{nkBracketExpr}): untyped =
  # chain is of shape: expression?left[right]
  let left = bracket[0]
  bracket[0] = quote do: `expression`?`left`
  bracket

macro `?`*(expression: typed, dot: untyped{nkDotExpr}): untyped =
  # chain is of shape: expression?left.right
  let left = dot[0]
  dot[0] = quote do: `expression`?`left`
  dot

macro `?`*(expression: typed, call: untyped{nkCall}): untyped =
  let procedure = call[0]
  if procedure.kind == nnkDotExpr:
    # chain is of shape: expression?left.right(arguments)
    let (left, right) = (procedure[0], procedure[1])
    call[0] = right
    call.insert(1, quote do: `expression`?`left`)
    call
  else:
    call.expectKind(nnkBracketExpr)
    nil
