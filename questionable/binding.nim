import std/options
import std/macros

proc placeholder(T: type): T =
  discard

template questionableUnpack*[T](expression: Option[T]): (T, bool) =
  ## Used internally

  let option = expression
  type T = typeof(option.unsafeGet())
  let res = if option.isSome: option.unsafeGet() else: placeholder(T)
  (res, option.isSome)

macro `=?`*(name, expression): bool =
  ## The `=?` operator lets you bind the value inside an Option or Result to a
  ## new variable. It can be used inside of a conditional expression, for
  ## instance in an `if` statement.

  name.expectKind({nnkIdent, nnkVarTy})
  if name.kind == nnkIdent:
    quote do:
      mixin questionableUnpack
      let (`name`, isOk) = questionableUnpack(`expression`)
      isOk

  else:
    let name = name[0]
    quote do:
      mixin questionableUnpack
      var (`name`, isOk) = questionableUnpack(`expression`)
      isOk
