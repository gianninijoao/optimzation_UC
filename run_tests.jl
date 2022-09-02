import Pkg
Pkg.activate(".")
Pkg.instantiate()

include("src/OptimizationUC.jl")

L2B, grid_input = OptimizationUC.get_data()

OptimizationUC.main(L2B, grid_input)
