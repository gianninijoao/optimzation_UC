function main(L2B::Matrix{Fl}, grid_input::Gi) where {Fl, Gi}
    cost, grid_output = run_solver(L2B, grid_input; use_uc = true, use_ramps = true, use_reserve = true, use_contingency = true, use_deficit = true)

    plot_results(grid_output)
    write_results(grid_input, grid_output)

    println("Cenários de contingência: ")

    println("Resultados (hora 1):")
    println("Theta: $(grid_output.θ[:,1])")
    println("Fluxo: $(grid_output.f[:,1])")
    println("Geração: $(grid_output.g[:,1])")

    nothing

end