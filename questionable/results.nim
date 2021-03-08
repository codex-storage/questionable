import ./resultsbase

include ./errorban

export resultsbase

template `?!`*(T: typed): type Result[T, ref CatchableError] =
  Result[T, ref CatchableError]

template success*[T](value: T): ?!T =
  ok(?!T, value)

template failure*(T: type, error: ref CatchableError): ?!T =
  err(?!T, error)

template `.?`*(value: ?!typed, field: untyped{nkIdent}): ?!untyped =
  type T = type value.get.field
  if value.isOk:
    ok(?!T, value.unsafeGet().field)
  else:
    err(?!T, error(value))

template `|?`*[T](value: ?!T, fallback: T): T =
  value.valueOr(fallback)

template `=?`*[T](name: untyped{nkIdent}, value: ?!T): bool =
  template name: T {.used.} = value.unsafeGet()
  value.isOk

template liftUnary(_: type Result, operator: untyped) =

  template `operator`*(a: ?!typed): ?!typed =
    type T {.used.} = type(`operator`(a.unsafeGet))
    if x =? a:
      `operator`(x).success
    else:
      T.failure(a.error)

template liftBinary(_: type Result, operator: untyped) =

  template `operator`*(a: ?!typed, b: ?!typed): ?!typed =
    type T = type(`operator`(a.unsafeGet, b.unsafeGet))
    if x =? a and y =? b:
      `operator`(x, y).success
    elif a.isErr:
      T.failure(a.error)
    else:
      T.failure(b.error)

  template `operator`*(a: ?!typed, b: typed): ?!typed =
    type T = type(`operator`(a.unsafeGet, b))
    if x =? a:
      `operator`(x, b).success
    else:
      T.failure(a.error)

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
