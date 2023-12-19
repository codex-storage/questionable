template ignoreBareExceptWarning*(body) =
  when defined(nimHasWarnBareExcept):
    {.push warning[BareExcept]:off warning[UnreachableCode]:off.}
  body
  when defined(nimHasWarnBareExcept):
    {.pop.}
