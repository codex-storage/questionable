import std/options
import ./chaining
import ./operators

include ./errorban

export options
export chaining

template `?`*(T: typed): type Option[T] =
  Option[T]

template `->?`*(option: ?typed, expression: untyped): untyped =
  type T = type expression
  if option.isSome:
    expression.some
  else:
    T.none

template `->?`*(options: (?typed, ?typed), expression: untyped): untyped =
  type T = type expression
  if options[0].isSome and options[1].isSome:
    expression.some
  else:
    T.none

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
