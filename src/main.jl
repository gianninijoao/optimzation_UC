function main(L2B::Matrix{Fl}, grid_input::Gi, grid_options::Go) where {Fl, Gi, Go}
    cost, grid_output = run_solver(L2B, grid_input, grid_options)

    plot_results(grid_output)
    write_results(grid_input, grid_output)

    println("Cenários de contingência: ")

    println("Resultados (hora 1):")
    println("Theta: $(grid_output.θ[:,1])")
    println("Fluxo: $(grid_output.f[:,1])")
    println("Geração: $(grid_output.g[:,1])")

    nothing

end