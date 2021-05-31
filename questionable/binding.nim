import std/options
import std/macros

proc option[T](option: Option[T]): Option[T] =
  option

template bindLet(name, expression): bool =
  let option = expression.option
  const default = typeof(option.unsafeGet()).default
  let name = if option.isSome: option.unsafeGet() else: default
  option.isSome

template bindVar(name, expression): bool =
  let option = expression.option
  var name : typeof(option.unsafeGet())
  if option.isSome:
    name = option.unsafeGet()
  option.isSome

macro `=?`*(name, expression): bool =
  name.expectKind({nnkIdent, nnkVarTy})
  if name.kind == nnkIdent:
    quote do: bindLet(`name`, `expression`)
  else:
    let name = name[0]
    quote do: bindVar(`name`, `expression`)
