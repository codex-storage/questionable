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

template `[]`*(value: ?!typed, index: typed): ?!typed =
  type T = type value.get[index]
  if value.isOk:
    ok(?!T, value.unsafeGet()[index])
  else:
    err(?!T, error(value))

template `|?`*[T](value: ?!T, fallback: T): T =
  value.valueOr(fallback)

template `=?`*[T](name: untyped{nkIdent}, value: ?!T): bool =
  template name: T {.used.} = value.unsafeGet()
  value.isOk
