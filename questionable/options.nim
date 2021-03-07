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

template liftPrefix(_: type Option, operator: untyped) =

  template `operator`*(a: ?typed): ?typed =
    type T {.used.} = type(`operator`(a.unsafeGet))
    if x =? a:
      `operator`(x).some
    else:
      T.none

template liftInfix(_: type Option, operator: untyped) =

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

Option.liftPrefix(`-`)
Option.liftPrefix(`+`)
Option.liftPrefix(`@`)
Option.liftInfix(`*`)
Option.liftInfix(`/`)
Option.liftInfix(`div`)
Option.liftInfix(`mod`)
Option.liftInfix(`shl`)
Option.liftInfix(`shr`)
Option.liftInfix(`+`)
Option.liftInfix(`-`)
Option.liftInfix(`&`)
Option.liftInfix(`<=`)
Option.liftInfix(`<`)
Option.liftInfix(`>=`)
Option.liftInfix(`>`)
