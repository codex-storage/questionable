import std/options
import ./chaining
import ./operators

include ./errorban

export options
export chaining

template `?`*(T: typed): type Option[T] =
  Option[T]

template `->?`*[T,U](option: ?T, expression: U): ?U =
  if option.isSome:
    expression.some
  else:
    U.none

template `->?`*[T,U,V](options: (?T, ?U), expression: V): ?V =
  if options[0].isSome and options[1].isSome:
    expression.some
  else:
    V.none

template `=?`*[T](name: untyped{nkIdent}, option: ?T): bool =
  template name: T {.used.} = option.unsafeGet()
  option.isSome

template `|?`*[T](option: ?T, fallback: T): T =
  if option.isSome:
    option.unsafeGet()
  else:
    fallback

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
