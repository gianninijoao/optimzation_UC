module OptimizationUC

using JuMP
using LinearAlgebra
using HiGHS
using Plots

include("structs.jl")
include("model.jl")
include("main.jl")
include("utils.jl")
include("test_functions.jl")

end