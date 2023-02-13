import std/options
import std/macros
import ./private/binderror

proc option[T](option: Option[T]): Option[T] =
  option

proc placeholder(T: type): T =
  discard

template bindLet(name, expression): bool =
  let evaluated = expression
  let option = evaluated.option
  type T = typeof(option.unsafeGet())
  let name {.used.} = if option.isSome:
    option.unsafeGet()
  else:
    bindFailed(evaluated)
    placeholder(T)
  option.isSome

template bindVar(name, expression): bool =
  let evaluated = expression
  let option = evaluated.option
  type T = typeof(option.unsafeGet())
  var name {.used.} = if option.isSome:
    option.unsafeGet()
  else:
    bindFailed(evaluated)
    placeholder(T)
  option.isSome

proc newUnpackTupleNode(names: NimNode, value: NimNode): NimNode =
  # builds tuple unpacking statement, eg: let (a, b) = value
  let vartuple = nnkVarTuple.newTree()
  for i in 0..<names.len:
    vartuple.add names[i]
  vartuple.add newEmptyNode()
  vartuple.add value
  nnkLetSection.newTree(vartuple)

macro bindTuple(names, expression): bool =
  let opt = ident("option")
  let evaluated = ident("evaluated")
  let T = ident("T")

  let value = quote do:
    if `opt`.isSome:
      `opt`.unsafeGet()
    else:
      bindFailed(`evaluated`)
      placeholder(`T`)

  let letsection = newUnpackTupleNode(names, value)

  quote do:
    let `evaluated` = `expression`
    let `opt` = `evaluated`.option
    type `T` = typeof(`opt`.unsafeGet())
    `letsection`
    `opt`.isSome

macro `=?`*(name, expression): bool =
  ## The `=?` operator lets you bind the value inside an Option or Result to a
  ## new variable. It can be used inside of a conditional expression, for
  ## instance in an `if` statement.

  when (NimMajor, NimMinor) < (1, 6):
    name.expectKind({nnkIdent, nnkVarTy, nnkTupleConstr, nnkPar})
  else:
    name.expectKind({nnkIdent, nnkVarTy, nnkTupleConstr})

  if name.kind == nnkIdent:
    quote do: bindLet(`name`, `expression`)
  elif name.kind == nnkTupleConstr or name.kind == nnkPar:
    quote do: bindTuple(`name`, `expression`)
  else:
    let name = name[0]
    quote do: bindVar(`name`, `expression`)
