version = "0.7.0"
author = "Questionable Authors"
description = "Elegant optional types"
license = "MIT"

task test, "Runs the test suite":
  for module in ["options", "result", "stew"]:
    withDir "testmodules/" & module:
      exec "nimble install -d -y"
      exec "nimble test -y"
