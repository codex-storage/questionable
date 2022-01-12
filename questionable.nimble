version = "0.10.2"
author = "Questionable Authors"
description = "Elegant optional types"
license = "MIT"

task test, "Runs the test suite":
  for module in ["options", "result", "stew"]:
    withDir "testmodules/" & module:
      delEnv "NIMBLE_DIR" # use nimbledeps dir
      exec "nimble install -d -y"
      exec "nimble test -y"
