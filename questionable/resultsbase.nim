template tryImport(module) = import module

when compiles tryImport pkg/result:
  import pkg/result/../results
else:
  import pkg/stew/results

export results
