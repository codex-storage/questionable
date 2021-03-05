version = "0.1.0"
author = "Questionable Authors"
description = "Questionable tests for std/option"
license = "MIT"

task test, "Runs the test suite":
  exec "nim c -f -r test.nim"
