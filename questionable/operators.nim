template liftUnary*(T: type, operator: untyped) =

  template `operator`*(a: T): untyped =
    block:
      let evaluated = a
      evaluated ->? `operator`(evaluated.unsafeGet())

template liftBinary*(T: type, operator: untyped) =

  template `operator`*(a: T, b: T): untyped =
    block:
      let evalA = a
      let evalB = b
      (evalA, evalB) ->? `operator`(evalA.unsafeGet, evalB.unsafeGet)

  template `operator`*(a: T, b: typed): untyped =
    block:
      let evalA = a
      evalA ->? `operator`(evalA.unsafeGet(), b)
