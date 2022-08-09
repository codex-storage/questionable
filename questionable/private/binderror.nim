import std/options

var captures {.global, compileTime.}: int
var errorVariable: ptr ref CatchableError

template captureBindError*(error: var ref CatchableError, expression): auto =
  let previousErrorVariable = errorVariable
  errorVariable = addr error

  static: inc captures
  let evaluated = expression
  static: dec captures

  errorVariable = previousErrorVariable

  evaluated

func error[T](option: Option[T]): ref CatchableError =
  newException(ValueError, "Option is set to `none`")

template bindFailed*(expression) =
  when captures > 0:
    mixin error
    errorVariable[] = expression.error
