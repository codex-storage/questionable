import std/options
import std/macros
import ./chaining
import ./indexing
import ./operators
import ./without

include ./errorban

export options except get
export chaining
export indexing
export without

template `?`*(T: typed): type Option[T] =
  Option[T]

template `!`*[T](option: ?T): T =
  option.get

template `->?`*[T,U](option: ?T, expression: U): ?U =
  if option.isSome:
    expression.some
  else:
    U.none

template `->?`*[T,U](option: ?T, expression: ?U): ?U =
  if option.isSome:
    expression
  else:
    U.none

template `->?`*[T,U,V](options: (?T, ?U), expression: V): ?V =
  if options[0].isSome and options[1].isSome:
    expression.some
  else:
    V.none

template `->?`*[T,U,V](options: (?T, ?U), expression: ?V): ?V =
  if options[0].isSome and options[1].isSome:
    expression
  else:
    V.none

template `=?`*[T](name: untyped{nkIdent}, expression: ?T): bool =
  let option = expression
  template name: T {.used.} = option.unsafeGet()
  option.isSome

macro `=?`*[T](variable: untyped{nkVarTy}, expression: ?T): bool =
  let name = variable[0]
  quote do:
    let option = `expression`
    var `name` : typeof(option.unsafeGet())
    if option.isSome:
      `name` = option.unsafeGet()
    option.isSome

template `|?`*[T](option: ?T, fallback: T): T =
  if option.isSome:
    option.unsafeGet()
  else:
    fallback

macro `.?`*[T](option: ?T, brackets: untyped{nkBracket}): untyped =
  let index = brackets[0]
  quote do:
    type U = typeof(`option`.unsafeGet().?[`index`].unsafeGet())
    if `option`.isSome:
      `option`.unsafeGet().?[`index`]
    else:
      U.none

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
