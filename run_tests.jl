import Pkg
Pkg.activate(".")
Pkg.instantiate()

include("src/Optimization_UC.jl")

Optimization_UC.main()
