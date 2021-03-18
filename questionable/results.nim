import std/macros
import ./resultsbase
import ./options
import ./operators

include ./errorban

export resultsbase

type ResultFailure* = object of CatchableError

template `?!`*(T: typed): type Result[T, ref CatchableError] =
  Result[T, ref CatchableError]

proc success*[T](value: T): ?!T =
  ok(?!T, value)

proc failure*(T: type, error: ref CatchableError): ?!T =
  err(?!T, error)

proc failure*(T: type, message: string): ?!T =
  T.failure newException(ResultFailure, message)

template `->?`*[T,U](value: ?!T, expression: U): ?!U =
  if value.isErr:
    U.failure(value.error)
  else:
    expression.success

template `->?`*[T,U,V](values: (?!T, ?!U), expression: V): ?!V =
  if values[0].isErr:
    V.failure(values[0].error)
  elif values[1].isErr:
    V.failure(values[1].error)
  else:
    expression.success

template `|?`*[T](value: ?!T, fallback: T): T =
  value.valueOr(fallback)

template `=?`*[T](name: untyped{nkIdent}, expression: ?!T): bool =
  let value = expression
  template name: T {.used.} = value.unsafeGet()
  value.isOk

macro `=?`*[T](variable: untyped{nkVarTy}, expression: ?!T): bool =
  let name = variable[0]
  quote do:
    let value = `expression`
    var `name` : typeof(value.unsafeGet())
    if value.isOk:
      `name` = value.unsafeGet()
    value.isOk

proc option*[T,E](value: Result[T,E]): ?T =
  if value.isOk:
    value.unsafeGet.some
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
