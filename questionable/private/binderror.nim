import std/options

var captureEnabled {.global, compileTime.}: bool
var errorVariable: ptr ref CatchableError

template captureBindError*(error: var ref CatchableError, expression): auto =
  let previousErrorVariable = errorVariable
  errorVariable = addr error

  static: captureEnabled = true
  let evaluated = expression
  static: captureEnabled = false

  errorVariable = previousErrorVariable

  evaluated

func error[T](option: Option[T]): ref CatchableError =
  newException(ValueError, "Option is set to `none`")

template bindFailed*(expression) =
  when captureEnabled:
    mixin error
    errorVariable[] = expression.error
