import ./without
import ./private/binderror

template without*(condition, errorname, body): untyped =
  ## Used to place guards that ensure that a Result contains a value.
  ## Exposes error when Result does not contain a value.

  var error: ref CatchableError

  without captureBindError(error, condition):
    template errorname: ref CatchableError = error
    body
