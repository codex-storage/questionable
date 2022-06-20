import std/options
import std/macros

proc questionableUnpack*[T](option: Option[T]): (T, bool) =
  ## Used internally

  if option.isSome:
    return (option.unsafeGet(), true)
  # return default

macro `=?`*(name, expression): bool =
  ## The `=?` operator lets you bind the value inside an Option or Result to a
  ## new variable. It can be used inside of a conditional expression, for
  ## instance in an `if` statement.

  name.expectKind({nnkIdent, nnkVarTy})
  if name.kind == nnkIdent:
    quote do:
      mixin questionableUnpack
      let (`name` {.used.}, isOk) = questionableUnpack(`expression`)
      isOk

  else:
    let name = name[0]
    quote do:
      mixin questionableUnpack
      var (`name` {.used.}, isOk) = questionableUnpack(`expression`)
      isOk
