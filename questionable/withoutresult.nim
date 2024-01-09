import std/macros
import ./without
import ./private/binderror

const symbolKinds = {nnkSym, nnkOpenSymChoice, nnkClosedSymChoice}
const identKinds = {nnkIdent} + symbolKinds

proc undoSymbolResolution(expression, ident: NimNode): NimNode =
  ## Finds symbols in the expression that match the `ident` and replaces them
  ## with `ident`, effectively undoing any symbol resolution that happened
  ## before.

  if expression.kind in symbolKinds and eqIdent($expression, $ident):
    return ident

  let expression = expression.copyNimTree()
  for i in 0..<expression.len:
    expression[i] = undoSymbolResolution(expression[i], ident)

  expression

macro without*(condition, errorname, body: untyped): untyped =
  ## Used to place guards that ensure that a Result contains a value.
  ## Exposes error when Result does not contain a value.

  if errorname.kind notin identKinds:
    error("expected an identifier, got " & errorname.repr, errorname)

  let errorIdent = ident $errorname

  # Nim's early symbol resolution might have picked up a symbol with the
  # same name as our error variable. We need to undo this to make sure that our
  # error variable is seen.
  let body = body.undoSymbolResolution(errorIdent)

  quote do:
    var error {.gensym.}: ref CatchableError

    without captureBindError(error, `condition`):
      template `errorIdent`: ref CatchableError = error
      `body`
