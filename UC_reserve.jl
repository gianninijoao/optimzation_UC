using JuMP, HiGHS, Plots, LinearAlgebra



function run_solver(L2B::Matrix{Int64}, grid::GridInput)
    @info("Starting to create optimization model!")

    n_scen = grid.geradores + grid.linhas

    model = Model(HiGHS.Optimizer) 

    @variables(model, begin
        # Geração
        g[1:grid.geradores, 1:grid.T] >= 0              # Variável g com G geradores e valor para cada hora
        g2[1:grid.geradores, 1:grid.T, 1:n_scen] >= 0   # Segundo estágio
        # Commitment
        u[1:grid.geradores, 1:grid.T], Bin              # Variável u, BINÁRIA, para determinar os geradores que estão ligados/desligados e valor para cada hora
        0 <= v[1:grid.geradores, 1:grid.T] <= 1         # Variável v, com G indicações se o gerador está sendo ligado e valor para cada hora
        0 <= w[1:grid.geradores, 1:grid.T] <= 1         # Variável w, com G indicações se o gerador está sendo desligado e valor para cada hora
        # Fluxo
        f[1:grid.linhas, 1:grid.T]                      # Variável f com L fluxos nas linhas
        f2[1:grid.linhas, 1:grid.T, 1:n_scen]           # Segundo estágio
        # Fase
        θ[1:grid.geradores, 1:grid.T]                   # Variável theta com L defasagens para cada barra
        θ2[1:grid.geradores, 1:grid.T, 1:n_scen]        # Segundo estágio
        # Reserva
        reserve_up[1:grid.geradores, 1:grid.T] >= 0     # Variável de reserva de subida com G geradores e valor para cada hora
        reserve_down[1:grid.geradores, 1:grid.T] >= 0   # Variável de reserva de subida com G geradores e valor para cada hora
        # Déficit
        deficit[1:grid.geradores, 1:grid.T] >= 0
        deficit2[1:grid.geradores, 1:grid.T, 1:n_scen] >= 0
        deficit_max[1:grid.geradores, 1:grid.T] >= 0
        # Curtailment
        curtailment[1:grid.geradores, 1:grid.T] >= 0
        curtailment2[1:grid.geradores, 1:grid.T, 1:n_scen] >= 0
        curtailment_max[1:grid.geradores, 1:grid.T] >= 0
    end)

    @constraints(model, begin 
        # ---------- Primeiro estágio ----------
        # Geração
        [i = 1:grid.geradores, t = 1:grid.T], g[i,t] - reserve_down[i,t] >= grid.geracao_min[i] * u[i,t]         # Potência de cada gerador deve estar entre o mínimo e o máximo
        [i = 1:grid.geradores, t = 1:grid.T], g[i,t] + reserve_up[i,t] <= grid.geracao_max[i] * u[i,t]
        # Fluxo
        [i = 1:grid.linhas, t = 1:grid.T], f[i,t] <= grid.fluxo_max[i]                                           # Fluxo de cada gerador deve estar entre -fluxo máximo e fluxo máximo
        [i = 1:grid.linhas, t = 1:grid.T], f[i,t] >= -grid.fluxo_max[i]
        # Fase
        [t = 1:grid.T], θ[1,t] == 0
        # Reserva
        [i = 1:grid.geradores, t = 1:grid.T], reserve_up[i,t] <= grid.ramp_up[i]
        [i = 1:grid.geradores, t = 1:grid.T], reserve_down[i,t] <= grid.ramp_down[i]
        # Restrições de commitment
        [i = 1:grid.geradores], v[i,1] - w[i,1] == u[i,1] - u[i,grid.T]                                          # Implicitamente faz u[0] = u[T]
        [i = 1:grid.geradores, t = 2:grid.T], v[i,t] - w[i,t] == u[i,t] - u[i,t-1]                               # Determinando se o gerador está sendo ligado ou desligado
        # Restrições de rampa
        [i = 1:grid.geradores, t = 2:grid.T], g[i,t] - g[i,t-1] <= grid.ramp_up[i] * u[i,t-1] + grid.ramp_startup[i] * v[i,t]
        [i = 1:grid.geradores, t = 2:grid.T], g[i,t-1] - g[i,t] <= grid.ramp_down[i] * u[i,t] + grid.ramp_shutdown[i] * w[i,t]
        # KVL
        [i = 1:grid.linhas, t = 1:grid.T], sum(-permutedims(L2B)[i, :] .* θ[:,t]) == f[i,t] * grid.Γ[i]          # A diferença de fase entre 2 linhas é igual ao fluxo entre elas
        # KCL
        [i = 1:grid.geradores, t = 1:grid.T], g[i, t] + sum(L2B[i, :] .* f[:, t]) + deficit[i,t] - curtailment[i,t] == grid.d[i,t]
        # ---------- Segundo estágio ----------
        # Geração
        [i = 1:grid.geradores, t = 1:grid.T, s = 1:n_scen], g2[i,t,s] >= (g[i,t] - reserve_down[i,t]) * grid.g_cont[s,i]
        [i = 1:grid.geradores, t = 1:grid.T, s = 1:n_scen], g2[i,t,s] <= (g[i,t] + reserve_up[i,t]) * grid.g_cont[s,i]
        # Fluxo
        [i = 1:grid.linhas, t = 1:grid.T, s = 1:n_scen], f2[i,t,s] <= grid.fluxo_max[i] * grid.l_cont[s,i]
        [i = 1:grid.linhas, t = 1:grid.T, s = 1:n_scen], f2[i,t,s] >= -grid.fluxo_max[i] * grid.l_cont[s,i]
        # Fase
        [t = 1:grid.T, s = 1:n_scen], θ2[1,t,s] == 0
        # KVL
        [i = 1:grid.geradores, t = 1:grid.T, s = 1:n_scen], sum(-permutedims(L2B)[i, :] .* θ2[:,t,s]) * grid.l_cont[s,i] == f2[i,t,s] * grid.Γ[i]
        # KCL
        [i = 1:grid.geradores, t = 1:grid.T, s = 1:n_scen], g2[i,t,s] + sum(L2B[i, :] .* f2[:,t,s]) + deficit2[i,t,s] - curtailment2[i,t,s] == grid.d[i,t]
        # Deficit/curtailment max
        [i = 1:grid.geradores, t = 1:grid.T, s = 1:n_scen], deficit_max[i, t] >= deficit2[i,t,s]
        [i = 1:grid.geradores, t = 1:grid.T, s = 1:n_scen], curtailment_max[i, t] >= curtailment2[i,t,s]
    end)

    #-----------------------------------Definição da função objetivo do modelo--------------------------------------
    gen_cost        = @expression(model, sum(grid.c[i] * g[i,t] for i=1:grid.geradores, t=1:grid.T))
    comt_cost       = @expression(model, sum(grid.c_su[i] * v[i,t] + grid.c_sd[i] * w[i,t] for i=1:grid.geradores, t=1:grid.T))
    reserve_cost    = @expression(model, sum(grid.c_r_up[i] * reserve_up[i,t] + grid.c_r_down[i] * reserve_down[i,t] for i=1:grid.geradores, t=1:grid.T))
    deficit_cost    = @expression(model, sum(grid.deficit_cost[i] * deficit[i,t] + grid.curtailment_cost[i] * curtailment[i,t] for i=1:grid.geradores, t=1:grid.T))
    deficit2_cost   = @expression(model, sum(grid.deficit2_cost[i] * deficit_max[i,t] + grid.curtailment2_cost[i] * curtailment_max[i,t] for i=1:grid.geradores, t=1:grid.T))
    @objective(model, Min, gen_cost + comt_cost + reserve_cost + deficit_cost + deficit2_cost)

    # Solve
    optimize!(model)
    @info("Problem solved!")

    return objective_value(model), GridOutput(value.(g), value.(u), value.(f), value.(θ), value.(v), value.(w), value.(reserve_up), value.(reserve_down), value.(deficit), value.(g2), value.(f2), value.(θ2), value.(deficit2))
end

function get_data()

    # Horizonte
    T              = 24
    demanda        = zeros(3, T)
    demanda[3,:]   .+= 100
    demanda[3, 2:end] .+= 20

    # Geradores
    G                    = 3
    geracao_min          = [0.0, 0.0, 0.0]                   # Geração mínima de cada gerador
    geracao_max          = [100.0, 100.0, 40.0]              # Geração máxima de cada gerador
    custo                = [100.0, 150.0, 200.0]             # Custo de cada gerador/hora

    # Deficit/curtailment
    deficit_max          = sum(demanda)
    curtailment_max      = sum(demanda)
    custo_deficit        = [2000.0, 2000.0, 2000.0]                           # Custo do déficit de demanda
    custo_deficit2       = [1000.0, 1000.0, 1000.0]                            # Custo do déficit de demanda
    custo_curtailment    = [1000.0, 1000.0, 1000.0]                            # Custo do déficit de demanda
    custo_curtailment2   = [500.0, 500.0, 500.0]                            # Custo do déficit de demanda

    # Restrições térmicas
    ramp_up              = [100.0, 100.0, deficit_max]       # Rampa máxima de subida
    ramp_down            = [100.0, 100.0, deficit_max]       # Rampa máxima de escida
    ramp_startup         = [100.0, 100.0, deficit_max]       # Rampa máxima ao ligar
    ramp_shutdown        = [100.0, 100.0, deficit_max]       # Rampa máxima ao desligar
    custo_startup        = [0.0, 0.0, 0.0]                   # Custo de ligar
    custo_shutdown       = [0.0, 0.0, 0.0]                   # Custo de desligar

    # Linhas
    L             = 3
    Γ             = [1.0, 1.0, 1.0]                # Susceptância em cada linha
    fluxo_max     = [80.0, 40.0, 60.0]             # Fluxo máximo de cada linha
    L2B           = [-1 -1 0;                      # Relação entre linhas e barras (colunas representam linhas do sistema)
                    0 1 -1;
                    1 0 1] 

    # Contingente N-1
    # [scenario, element]
    # gen_contingency         = vcat(ones(G, G) - I, ones(L, G))
    gen_contingency         = vcat(ones(G, G), ones(L, G))
    # line_contingency        = vcat(ones(G, L), ones(L, L) - I)
    line_contingency        = vcat(ones(G, L), ones(L, L))
    reserve_up_cost         = custo ./ 2
    reserve_down_cost       = custo ./ 2

    # Struct
    return L2B, GridInput(custo, custo_startup, custo_shutdown, custo_deficit, custo_deficit2, custo_curtailment, custo_curtailment2, demanda, Γ, fluxo_max, geracao_min, geracao_max, ramp_up, ramp_down, ramp_startup, ramp_shutdown, gen_contingency, line_contingency, reserve_up_cost, reserve_down_cost, G, L, T)

end

function plot_results(out::GridOutput)

    out_path = "Unit commitment\\outputs"
    mkpath(out_path)

    # Plot theta
    fig = plot(out.θ', label=["Barra 1" "Barra 2" "Barra 3"], title="Fase")
    savefig(fig, joinpath(out_path, "theta.png"))

    # Plot fluxo
    fig = plot(out.f', label=["Linha 1" "Linha 2" "Linha 3"], title="Fluxo")
    savefig(fig,  joinpath(out_path, "fluxo.png"))

    # Plot geração
    fig = areaplot(out.g', label=["Usina 1" "Usina 2" "Déficit"], title="Geração")
    savefig(fig,  joinpath(out_path, "ger.png"))

    # Plot reserva up
    fig = plot(out.r_up', label=["Usina 1" "Usina 2" "Déficit"], title="Reserva UP")
    savefig(fig,  joinpath(out_path, "reserve_up.png"))

    # Plot reserva down
    fig = plot(out.r_down', label=["Usina 1" "Usina 2" "Déficit"], title="Reserva DOWN")
    savefig(fig,  joinpath(out_path, "reserve_down.png"))

    nothing
   
end

function write_results(in::GridInput, out::GridOutput)

    out_path = "Unit commitment\\outputs"
    mkpath(out_path)
    S = in.geradores + in.linhas

    # Geração
    header = ["Etapa", "Cenário", "Usina 1", "Usina 2", "Déficit"]
    open(joinpath(out_path, "ger.csv"), "w") do io
        for i in 1:length(header)
            write(io, "$(header[i]), ")
        end
        write(io, "\n")
        for t in 1:in.T, s in 1:S
            write(io, "$t, $s, ")
            for i in 1:in.geradores
                write(io, "$(out.g2[i,t,s]), ")
            end
            write(io, "\n")
        end
    end

    # Fluxo
    header = ["Etapa", "Cenário", "Linha 1", "Linha 2", "Linha 3"]
    open(joinpath(out_path, "flux.csv"), "w") do io
        for i in 1:length(header)
            write(io, "$(header[i]), ")
        end
        write(io, "\n")
        for t in 1:in.T, s in 1:S
            write(io, "$t, $s, ")
            for i in 1:in.linhas
                write(io, "$(out.f2[i,t,s]), ")
            end
            write(io, "\n")
        end
    end

    nothing

end

function main()

    L2B, grid_input = get_data()

    cost, grid_output = run_solver(L2B, grid_input)

    plot_results(grid_output)
    write_results(grid_input, grid_output)

    println("Cenários de contingência: ")

    println("Resultados (hora 1):")
    println("Theta: $(grid_output.θ[:,1])")
    println("Fluxo: $(grid_output.f[:,1])")
    println("Geração: $(grid_output.g[:,1])")

    nothing

end

main()
