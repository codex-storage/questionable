import std/options
import std/macros
import ./private/binderror

when (NimMajor, NimMinor) < (1, 1):
  type SomePointer = ref | ptr | pointer
elif (NimMajor, NimMinor) == (2, 0): # Broken in 2.0.0, fixed in 2.1.1.
  type SomePointer = ref | ptr | pointer | proc
else:
  type SomePointer = ref | ptr | pointer | proc | iterator {.closure.}

template toOption[T](option: Option[T]): Option[T] =
  option

template toOption[T: SomePointer](value: T): Option[T] =
  value.option

proc placeholder(T: type): T =
  discard

template bindLet(name, expression): untyped =
  let evaluated = expression
  let option = evaluated.toOption
  type T = typeof(option.unsafeGet())
  let name {.used.} = if option.isSome:
    option.unsafeGet()
  else:
    bindFailed(evaluated)
    placeholder(T)
  option.isSome

template bindVar(name, expression): untyped =
  let evaluated = expression
  let option = evaluated.toOption
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
  let opt = genSym(nskLet, "option")
  let evaluated = genSym(nskLet, "evaluated")
  let T = genSym(nskType, "T")

  let value = quote do:
    if `opt`.isSome:
      `opt`.unsafeGet()
    else:
      bindFailed(`evaluated`)
      placeholder(`T`)

  let letsection = newUnpackTupleNode(names, value)

  quote do:
    let `evaluated` = `expression`
    let `opt` = `evaluated`.toOption
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
