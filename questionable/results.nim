import std/macros
import ./resultsbase
import ./options
import ./binding
import ./chaining
import ./indexing
import ./operators
import ./without

include ./errorban

export resultsbase except ok, err, isOk, isErr, get
export binding
export chaining
export indexing
export without

type ResultFailure* = object of CatchableError

template `?!`*(T: typed): type Result[T, ref CatchableError] =
  Result[T, ref CatchableError]

template `!`*[T](value: ?!T): T =
  value.get

proc success*[T](value: T): ?!T =
  ok(?!T, value)

proc success*: ?!void =
  ok(?!void)

proc failure*(T: type, error: ref CatchableError): ?!T =
  err(?!T, error)

proc failure*(T: type, message: string): ?!T =
  T.failure newException(ResultFailure, message)

template failure*(error: ref CatchableError): auto =
  err error

template failure*(message: string): auto =
  failure newException(ResultFailure, message)

proc isSuccess*[T](value: ?!T): bool =
  value.isOk

proc isFailure*[T](value: ?!T): bool =
  value.isErr

template `->?`*[T,U](value: ?!T, expression: ?!U): ?!U =
  if value.isFailure:
    U.failure(value.error)
  else:
    expression

template `->?`*[T,U](value: ?!T, expression: U): ?!U =
  value ->? expression.success

template `->?`*[T,U,V](values: (?!T, ?!U), expression: ?!V): ?!V =
  if values[0].isFailure:
    V.failure(values[0].error)
  elif values[1].isFailure:
    V.failure(values[1].error)
  else:
    expression

template `->?`*[T,U,V](values: (?!T, ?!U), expression: V): ?!V =
  values ->? expression.success

template `|?`*[T,E](value: Result[T,E], fallback: T): T =
  value.valueOr(fallback)

proc option*[T,E](value: Result[T,E]): ?T =
  if value.isOk:
    try: # workaround for erroneouos exception tracking when T is a closure
      value.unsafeGet.some
    except Exception as exception:
      raise newException(Defect, exception.msg, exception)
  else:
    T.none

Result.liftUnary(`-`)
Result.liftUnary(`+`)
Result.liftUnary(`@`)
Result.liftBinary(`[]`)
Result.liftBinary(`*`)
Result.liftBinary(`/`)
Result.liftBinary(`div`)
Result.liftBinary(`mod`)
Result.liftBinary(`shl`)
Result.liftBinary(`shr`)
Result.liftBinary(`+`)
Result.liftBinary(`-`)
Result.liftBinary(`&`)
Result.liftBinary(`<=`)
Result.liftBinary(`<`)
Result.liftBinary(`>=`)
Result.liftBinary(`>`)
