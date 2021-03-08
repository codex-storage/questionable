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

template `|?`*[T](option: ?T, fallback: T): T =
  if option.isSome:
    option.unsafeGet()
  else:
    fallback

template `=?`*[T](name: untyped{nkIdent}, option: ?T): bool =
  template name: T {.used.} = option.unsafeGet()
  option.isSome

template liftUnary(_: type Option, operator: untyped) =

  template `operator`*(a: ?typed): ?typed =
    type T {.used.} = type(`operator`(a.unsafeGet))
    if x =? a:
      `operator`(x).some
    else:
      T.none

template liftBinary(_: type Option, operator: untyped) =

  template `operator`*(a: ?typed, b: ?typed): ?typed =
    type T = type(`operator`(a.unsafeGet, b.unsafeGet))
    if x =? a and y =? b:
      `operator`(x, y).some
    else:
      T.none

  template `operator`*(a: ?typed, b: typed): ?typed =
    type T = type(`operator`(a.unsafeGet, b))
    if x =? a:
      `operator`(x, b).some
    else:
      T.none

Option.liftUnary(`-`)
Option.liftUnary(`+`)
Option.liftUnary(`@`)
Option.liftBinary(`[]`)
Option.liftBinary(`*`)
Option.liftBinary(`/`)
Option.liftBinary(`div`)
Option.liftBinary(`mod`)
Option.liftBinary(`shl`)
Option.liftBinary(`shr`)
Option.liftBinary(`+`)
Option.liftBinary(`-`)
Option.liftBinary(`&`)
Option.liftBinary(`<=`)
Option.liftBinary(`<`)
Option.liftBinary(`>=`)
Option.liftBinary(`>`)
