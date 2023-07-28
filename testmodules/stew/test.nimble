version = "0.1.0"
author = "Questionable Authors"
description = "Questionable tests for pkg/stew"
license = "MIT"

when (NimMajor, NimMinor) >= (1, 6):
  requires "stew"

  task test, "Runs the test suite":
    exec "nim c -f -r --skipParentCfg test.nim"
else:
  task test, "Runs the test suite":
    echo "Warning: Skipping test with stew on Nim < 1.6"
