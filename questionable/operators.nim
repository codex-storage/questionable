template liftUnary*(T: type, operator: untyped) =

  template `operator`*(a: T): untyped =
    a ->? `operator`(a.unsafeGet())

template liftBinary*(T: type, operator: untyped) =

  template `operator`*(a: T, b: T): untyped =
    (a, b) ->? `operator`(a.unsafeGet, b.unsafeGet)

  template `operator`*(a: T, b: typed): untyped =
    a ->? `operator`(a.unsafeGet(), b)
