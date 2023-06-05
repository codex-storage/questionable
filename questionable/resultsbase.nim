template tryImport(module) = import module

when compiles tryImport pkg/results:
  import pkg/results
else:
  import pkg/stew/results

export results
