version = "0.1.0"
author = "Questionable Authors"
description = "Questionable tests for std/option"
license = "MIT"

task test, "Runs the test suite":
  var options = "-f -r"
  when (NimMajor, NimMinor) >= (1, 4):
    options &= " --warningAsError[UnsafeDefault]:on"
    options &= " --warningAsError[ProveInit]:on"
  exec "nim c " & options & " test.nim"
