template tryImport(module) = import module

when compiles tryimport pkg/result:
  import pkg/result/../results
else:
  import pkg/stew/results

export results
