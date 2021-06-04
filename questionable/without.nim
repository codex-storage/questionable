template without*(expression, body) =
  ## Used to place guards that ensure that an Option or Result contains a value.

  let ok = expression
  if not ok:
    body
