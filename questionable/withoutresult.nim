import ./without

template without*(condition, errorname, body) =
  ## Used to place guards that ensure that a Result contains a value.
  ## Exposes error when Result does not contain a value.

  when not declaredInScope(internalWithoutError):
    var internalWithoutError {.inject.}: ref CatchableError
  else:
    internalWithoutError = nil

  without condition:
    template errorname: ref CatchableError = internalWithoutError
    if isNil(errorname):
      errorname = newException(ValueError, "Option is set to `none`")
    body
