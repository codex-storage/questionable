template without*(expression, body) =
  let ok = expression
  if not ok:
    body
