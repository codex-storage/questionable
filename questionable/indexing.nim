import std/macros

macro `.?`*(expression: seq | string | openArray, brackets: untyped{nkBracket}): untyped =
  # chain is of shape: (seq or string).?[index]
  let index = brackets[0]
  quote do:
    block:
      type T = typeof(`expression`[`index`])

      when typeof(`expression`) is openArray:
        if `index` >= `expression`.low and `index` <= `expression`.high:
          `expression`[`index`].some
        else:
          T.none
      else:
        let evaluated = `expression`
        if `index` >= evaluated.low and `index` <= evaluated.high:
          evaluated[`index`].some
        else:
          T.none

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
