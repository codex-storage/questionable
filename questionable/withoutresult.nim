import ./binding
import ./without

template without*(expression, errorname, body) =
  ## Used to place guards that ensure that a Result contains a value.
  ## Exposes error when Result does not contain a value.

  var error: ref CatchableError

  # override =? operator such that it stores the error if there is one
  template `=?`(name, result): bool =
    when result is Result:
      if result.isFailure:
        error = result.error
    when result is Option:
      if result.isNone:
        error = newException(ValueError, "Option is set to `none`")
    binding.`=?`(name, result)

  without expression:
    template errorname: ref CatchableError = error
    body
