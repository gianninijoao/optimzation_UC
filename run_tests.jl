import Pkg
Pkg.activate(".")
Pkg.instantiate()

include("src/OptimizationUC.jl")

OptimizationUC.main()
