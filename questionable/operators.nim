import ./private/scope

template liftUnary*(T: type, operator: untyped) =

  template `operator`*(a: T): untyped =
    scope:
      let evaluated = a
      evaluated ->? `operator`(evaluated.unsafeGet())

template liftBinary*(T: type, operator: untyped) =

  template `operator`*(a: T, b: T): untyped =
    scope:
      let evalA = a
      let evalB = b
      (evalA, evalB) ->? `operator`(evalA.unsafeGet, evalB.unsafeGet)

  template `operator`*(a: T, b: typed): untyped =
    scope:
      let evalA = a
      evalA ->? `operator`(evalA.unsafeGet(), b)
