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

  # Outside of the quote do to avoid binding symbol too early
  let unpacker = newCall("questionableUnpack", expression)

  if name.kind == nnkIdent:
    quote do:
      let (`name` {.used.}, isOk) = `unpacker`
      isOk

  else:
    let name = name[0]
    quote do:
      var (`name` {.used.}, isOk) = `unpacker`
      isOk
