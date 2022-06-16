import std/options
import std/macros

proc option[T](option: Option[T]): Option[T] =
  option

proc placeholder(T: type): T =
  discard

template unpack*(expression: Option): untyped =
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
      mixin unpack
      let (`name`, isOk) = unpack(`expression`)
      isOk

  else:
    let name = name[0]
    quote do:
      mixin unpack
      var (`name`, isOk) = unpack(`expression`)
      isOk
