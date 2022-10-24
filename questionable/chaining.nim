import std/options
import std/macros
import std/strformat
import ./private/scope

func isSym(node: NimNode): bool =
  node.kind in {nnkSym, nnkOpenSymChoice, nnkClosedSymChoice}

func expectSym(node: NimNode) =
  node.expectKind({nnkSym, nnkOpenSymChoice, nnkClosedSymChoice})

macro expectReturnType(identifier: untyped, expression: untyped): untyped =
  let message =
    fmt"'{identifier}' doesn't have a return type, it can't be in a .? chain"
  quote do:
    when compiles(`expression`) and not compiles(typeof `expression`):
      {.error: `message`.}

template chain(option: typed, identifier: untyped{nkIdent}): untyped =
  # chain is of shape: option.?identifier
  expectReturnType(identifier, option.unsafeGet.identifier)
  option ->? option.unsafeGet.identifier

macro chain(option: typed, infix: untyped{nkInfix}): untyped =
  # chain is of shape: option.?left `operator` right
  let left = infix[1]
  infix[1] = quote do: `option`.?`left`
  infix

macro chain(option: typed, bracket: untyped{nkBracketExpr}): untyped =
  # chain is of shape: option.?left[right]
  let left = bracket[0]
  bracket[0] = quote do: `option`.?`left`
  bracket

macro chain(option: typed, dot: untyped{nkDotExpr}): untyped =
  # chain is of shape: option.?left.right
  let left = dot[0]
  dot[0] = quote do: `option`.?`left`
  dot

macro chain(option: typed, call: untyped{nkCall}): untyped =
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
    quote do:
      expectReturnType(`procedure`, `call`)
      `option` ->? `call`

macro chain(option: typed, symbol: untyped): untyped =
  symbol.expectSym()
  let expression = ident($symbol)
  quote do: `option`.?`expression`

template `.?`*(left: typed, right: untyped): untyped =
  ## The `.?` chaining operator is used to safely access fields and call procs
  ## on Options or Results. The expression is only evaluated when the preceding
  ## Option or Result has a value.
  scope:
    let evaluated = left
    chain(evaluated, right)
