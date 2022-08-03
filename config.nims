--styleCheck:usages
if (NimMajor, NimMinor) < (1, 6):
  --styleCheck:hint
else:
  --styleCheck:error

# begin Nimble config (version 1)
when fileExists("nimble.paths"):
  include "nimble.paths"
# end Nimble config
