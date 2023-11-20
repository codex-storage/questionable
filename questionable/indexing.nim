import std/macros

macro `.?`*(expression: seq | string, brackets: untyped{nkBracket}): untyped =
  # chain is of shape: (seq or string).?[index]
  let index = brackets[0]
  quote do:
    block:
      type T = typeof(`expression`[`index`])
      let evaluated = `expression`
      if `index` >= evaluated.low and `index` <= evaluated.high:
        evaluated[`index`].some
      else:
        T.none

macro `.?`*(expression: openArray, brackets: untyped{nkBracket}): untyped =
  # chain is of shape: openArray.?[index]
  let index = brackets[0]
  quote do:
    block:
      type T = typeof(`expression`[`index`])
      proc safeGet(arr: openArray[T], i: int): ?T {.gensym.} =
        if i >= arr.low and i <= arr.high:
          arr[i].some
        else:
          T.none
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
