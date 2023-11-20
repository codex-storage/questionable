import std/macros
import std/options

proc safeGet[T](expression: seq[T] | openArray[T], index: int): Option[T] =
  if index >= expression.low and index <= expression.high:
    expression[index].some
  else:
    T.none

proc safeGet(expression: string, index: int): Option[char] =
  if index >= expression.low and index <= expression.high:
    expression[index].some
  else:
    char.none

macro `.?`*(expression: seq | string | openArray, brackets: untyped{nkBracket}): untyped =
    # chain is of shape: (seq or string or openArray).?[index]
    let index = brackets[0]
    quote do:
      block:
        safeGet(`expression`, `index`)

macro `.?`*(expression: typed, brackets: untyped{nkBracket}): untyped =
  # chain is of shape: expression.?[index]
  let index = brackets[0]
  quote do:
    block:
      type T = typeof(`expression`[`index`])
      try:
        `expression`[`index`].some
      except KeyError:
        T.none
