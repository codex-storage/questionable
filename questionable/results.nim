import std/macros
import ./resultsbase
import ./options
import ./operators

include ./errorban

export resultsbase except ok, err, isOk, isErr

type ResultFailure* = object of CatchableError

template `?!`*(T: typed): type Result[T, ref CatchableError] =
  Result[T, ref CatchableError]

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

template `->?`*[T,U](value: ?!T, expression: U): ?!U =
  if value.isFailure:
    U.failure(value.error)
  else:
    expression.success

template `->?`*[T,U,V](values: (?!T, ?!U), expression: V): ?!V =
  if values[0].isFailure:
    V.failure(values[0].error)
  elif values[1].isFailure:
    V.failure(values[1].error)
  else:
    expression.success

template `|?`*[T,E](value: Result[T,E], fallback: T): T =
  value.valueOr(fallback)

macro `=?`*[T,E](name: untyped{nkIdent}, expression: Result[T,E]): bool =
  let unsafeGet = bindSym"unsafeGet"
  let isOk = bindSym"isOk"
  quote do:
    let value = `expression`
    template `name`: T {.used.} = value.`unsafeGet`()
    `isOk`(value)

macro `=?`*[T,E](variable: untyped{nkVarTy}, expression: Result[T,E]): bool =
  let name = variable[0]
  let unsafeGet = bindSym"unsafeGet"
  let isOk = bindSym"isOk"
  quote do:
    let value = `expression`
    var `name` : typeof(value.`unsafeGet`())
    if `isOk`(value):
      `name` = value.`unsafeGet`()
    `isOk`(value)

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
