import ./resultsbase
import ./options
import ./operators

include ./errorban

export resultsbase

template `?!`*(T: typed): type Result[T, ref CatchableError] =
  Result[T, ref CatchableError]

proc success*[T](value: T): ?!T =
  ok(?!T, value)

proc failure*(T: type, error: ref CatchableError): ?!T =
  err(?!T, error)

template `->?`*(option: ?!typed, expression: untyped): untyped =
  type T = type expression
  if option.isErr:
    T.failure(option.error)
  else:
    expression.success

template `->?`*(options: (?!typed, ?!typed), expression: untyped): untyped =
  type T = type expression
  if options[0].isErr:
    T.failure(options[0].error)
  elif options[1].isErr:
    T.failure(options[1].error)
  else:
    expression.success

template `|?`*[T](value: ?!T, fallback: T): T =
  value.valueOr(fallback)

template `=?`*[T](name: untyped{nkIdent}, value: ?!T): bool =
  template name: T {.used.} = value.unsafeGet()
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
