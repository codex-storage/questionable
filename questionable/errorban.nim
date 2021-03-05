## Include this file to indicate that your module does not raise Errors.
## Disables compiler hints about unused declarations in Nim < 1.4.0

when (NimMajor, NimMinor, NimPatch) >= (1, 4, 0):
  {.push raises:[].}
else:
  {.push raises: [Defect].}
  {.hint[XDeclaredButNotUsed]: off.}
