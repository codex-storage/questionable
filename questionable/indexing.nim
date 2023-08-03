import std/macros

macro `.?`*(expression: seq | string, brackets: untyped{nkBracket}): untyped =
  # chain is of shape: (seq or string).?[index]
  let index = brackets[0]
  quote do:
    block:
      type T = typeof(`expression`[`index`])
      let evaluated = `expression`
      if `index` < evaluated.len:
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
