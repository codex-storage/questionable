import std/options

include ./errorban

export options

template `?`*(T: typed): type Option[T] =
  Option[T]

template `.?`*(option: ?typed, field: untyped{nkIdent}): ?untyped =
  type T = type option.get.field
  if option.isSome:
    option.unsafeGet().field.some
  else:
    T.none

template `[]`*(option: ?typed, index: typed): ?typed =
  type T = type option.get[index]
  if option.isSome:
    option.unsafeGet()[index].some
  else:
    T.none

template `|?`*[T](option: ?T, fallback: T): T =
  if option.isSome:
    option.unsafeGet()
  else:
    fallback

template `=?`*[T](name: untyped{nkIdent}, option: ?T): bool =
  template name: T {.used.} = option.unsafeGet()
  option.isSome

