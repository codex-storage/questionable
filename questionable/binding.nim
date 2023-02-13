import std/options
import std/macros
import std/sequtils
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

macro bindTuple(name, expression): bool =
  let stmtList = newStmtList()
  let opt = genSym(nskLet, "option")
  let T = genSym(nskType, "T")

  stmtList.add quote do:
    let evaluated = `expression`
    let `opt` = evaluated.option
    type `T` = typeof(`opt`.unsafeGet())

  let valueNode = quote do:
    if `opt`.isSome:
      `opt`.unsafeGet()
    else:
      bindFailed(evaluated)
      placeholder(`T`)

  # build tuple unpacking statement, eg:
  # let (a, b) = `valueNode`
  let tplNode = nnkVarTuple.newTree()
  for i in 0..<name.len:
    tplNode.add name[i]
  tplNode.add newEmptyNode()
  tplNode.add valueNode

  stmtList.add nnkStmtList.newTree(
    nnkLetSection.newTree(
      tplNode
    )
  )
  stmtList.add quote do: `opt`.isSome
  return stmtList

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
