import std/options
import std/macros

func isSym(node: NimNode): bool =
  node.kind in {nnkSym, nnkOpenSymChoice, nnkClosedSymChoice}

func expectSym(node: NimNode) =
  node.expectKind({nnkSym, nnkOpenSymChoice, nnkClosedSymChoice})

template `.?`*(option: typed, identifier: untyped{nkIdent}): untyped =
  ## The `.?` chaining operator is used to safely access fields and call procs
  ## on Options or Results. The expression is only evaluated when the preceding
  ## Option or Result has a value.

  # chain is of shape: option.?identifier
  when not compiles(typeof(option.unsafeGet.identifier)):
    {.error: ".? chain cannot return void".}
  option ->? option.unsafeGet.identifier

macro `.?`*(option: typed, infix: untyped{nkInfix}): untyped =
  ## The `.?` chaining operator is used to safely access fields and call procs
  ## on Options or Results. The expression is only evaluated when the preceding
  ## Option or Result has a value.

  # chain is of shape: option.?left `operator` right
  let left = infix[1]
  infix[1] = quote do: `option`.?`left`
  infix

macro `.?`*(option: typed, bracket: untyped{nkBracketExpr}): untyped =
  ## The `.?` chaining operator is used to safely access fields and call procs
  ## on Options or Results. The expression is only evaluated when the preceding
  ## Option or Result has a value.

  # chain is of shape: option.?left[right]
  let left = bracket[0]
  bracket[0] = quote do: `option`.?`left`
  bracket

macro `.?`*(option: typed, dot: untyped{nkDotExpr}): untyped =
  ## The `.?` chaining operator is used to safely access fields and call procs
  ## on Options or Results. The expression is only evaluated when the preceding
  ## Option or Result has a value.

  # chain is of shape: option.?left.right
  let left = dot[0]
  dot[0] = quote do: `option`.?`left`
  dot

macro `.?`*(option: typed, call: untyped{nkCall}): untyped =
  ## The `.?` chaining operator is used to safely access fields and call procs
  ## on Options or Results. The expression is only evaluated when the preceding
  ## Option or Result has a value.

  let procedure = call[0]
  if call.len == 1:
    # chain is of shape: option.?procedure()
    quote do: `option`.?`procedure`
  elif procedure.kind == nnkDotExpr:
    # chain is of shape: option.?left.right(arguments)
    let (left, right) = (procedure[0], procedure[1])
    call[0] = right
    call.insert(1, quote do: `option`.?`left`)
    call
  elif procedure.isSym and $procedure == "[]":
    # chain is of shape: option.?left[right] after semantic analysis
    let left = call[1]
    call[1] = quote do: `option`.?`left`
    call
  else:
    # chain is of shape: option.?procedure(arguments)
    call.insert(1, quote do: `option`.unsafeGet)
    quote do: `option` ->? `call`

macro `.?`*(option: typed, symbol: untyped): untyped =
  ## The `.?` chaining operator is used to safely access fields and call procs
  ## on Options or Results. The expression is only evaluated when the preceding
  ## Option or Result has a value.

  symbol.expectSym()
  let expression = ident($symbol)
  quote do: `option`.?`expression`
