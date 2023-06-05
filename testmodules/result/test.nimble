version = "0.1.0"
author = "Questionable Authors"
description = "Questionable tests for pkg/result"
license = "MIT"

requires "result"

task test, "Runs the test suite":
  exec "nim c -f -r --skipParentCfg test.nim"
