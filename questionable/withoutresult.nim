import std/macros
import ./without
import ./private/binderror

macro without*(condition, errorname, body): untyped =
  ## Used to place guards that ensure that a Result contains a value.
  ## Exposes error when Result does not contain a value.

  let errorIdent = ident $errorname

  quote do:
    var error: ref CatchableError

    without captureBindError(error, `condition`):
      template `errorIdent`: ref CatchableError = error
      `body`
