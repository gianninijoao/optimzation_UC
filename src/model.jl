function run_solver(L2B::Matrix{Int64}, grid::GridInput; uc::Bool = true, ramps::Bool = true, reserve::Bool = true, contingency::Bool = true, deficit::Bool = true)
    @info("Starting to create optimization model!")

    n_scen = grid.geradores + grid.linhas

    model = Model(HiGHS.Optimizer) 

    @variables(model, begin
        # Geração
        g[1:grid.geradores, 1:grid.T] >= 0              # Variável g com G geradores e valor para cada hora
        g2[1:grid.geradores, 1:grid.T, 1:n_scen] >= 0   # Segundo estágio
        # Commitment
        if uc
            u[1:grid.geradores, 1:grid.T], Bin              # Variável u, BINÁRIA, para determinar os geradores que estão ligados/desligados e valor para cada hora
            0 <= v[1:grid.geradores, 1:grid.T] <= 1         # Variável v, com G indicações se o gerador está sendo ligado e valor para cada hora
            0 <= w[1:grid.geradores, 1:grid.T] <= 1         # Variável w, com G indicações se o gerador está sendo desligado e valor para cada hora
        end
        # Fluxo
        f[1:grid.linhas, 1:grid.T]                      # Variável f com L fluxos nas linhas
        f2[1:grid.linhas, 1:grid.T, 1:n_scen]           # Segundo estágio
        # Fase
        θ[1:grid.geradores, 1:grid.T]                   # Variável theta com L defasagens para cada barra
        θ2[1:grid.geradores, 1:grid.T, 1:n_scen]        # Segundo estágio
        if reserve
            # Reserva
            reserve_up[1:grid.geradores, 1:grid.T] >= 0     # Variável de reserva de subida com G geradores e valor para cada hora
            reserve_down[1:grid.geradores, 1:grid.T] >= 0   # Variável de reserva de subida com G geradores e valor para cada hora
        end
        if deficit
            # Déficit
            deficit[1:grid.geradores, 1:grid.T] >= 0
            deficit2[1:grid.geradores, 1:grid.T, 1:n_scen] >= 0
            deficit_max[1:grid.geradores, 1:grid.T] >= 0
            # Curtailment
            curtailment[1:grid.geradores, 1:grid.T] >= 0
            curtailment2[1:grid.geradores, 1:grid.T, 1:n_scen] >= 0
            curtailment_max[1:grid.geradores, 1:grid.T] >= 0
        end
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
        if reserve
            # Reserva
            [i = 1:grid.geradores, t = 1:grid.T], reserve_up[i,t] <= grid.ramp_up[i]
            [i = 1:grid.geradores, t = 1:grid.T], reserve_down[i,t] <= grid.ramp_down[i]
        end
        if uc
            # Restrições de commitment
            [i = 1:grid.geradores], v[i,1] - w[i,1] == u[i,1] - u[i,grid.T]                                          # Implicitamente faz u[0] = u[T]
            [i = 1:grid.geradores, t = 2:grid.T], v[i,t] - w[i,t] == u[i,t] - u[i,t-1]                               # Determinando se o gerador está sendo ligado ou desligado
        end
        if ramps
            # Restrições de rampa
            [i = 1:grid.geradores, t = 2:grid.T], g[i,t] - g[i,t-1] <= grid.ramp_up[i] * u[i,t-1] + grid.ramp_startup[i] * v[i,t]
            [i = 1:grid.geradores, t = 2:grid.T], g[i,t-1] - g[i,t] <= grid.ramp_down[i] * u[i,t] + grid.ramp_shutdown[i] * w[i,t]
        end
        # KVL
        [i = 1:grid.linhas, t = 1:grid.T], sum(-permutedims(L2B)[i, :] .* θ[:,t]) == f[i,t] * grid.Γ[i]          # A diferença de fase entre 2 linhas é igual ao fluxo entre elas
        # KCL
        [i = 1:grid.geradores, t = 1:grid.T], g[i, t] + sum(L2B[i, :] .* f[:, t]) + deficit[i,t] - curtailment[i,t] == grid.d[i,t]
        if contingency
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
            if deficit
                # Deficit/curtailment max
                [i = 1:grid.geradores, t = 1:grid.T, s = 1:n_scen], deficit_max[i, t] >= deficit2[i,t,s]
                [i = 1:grid.geradores, t = 1:grid.T, s = 1:n_scen], curtailment_max[i, t] >= curtailment2[i,t,s]
            end
        end
    end)

    #-----------------------------------Definição da função objetivo do modelo--------------------------------------
    cost_vec = []
    gen_cost = @expression(model, sum(grid.c[i] * g[i,t] for i = 1:grid.geradores, t = 1:grid.T))
    push!(cost_vec, gen_cost)
    if uc
        comt_cost = @expression(model, sum(grid.c_su[i] * v[i,t] + grid.c_sd[i] * w[i,t] for i = 1:grid.geradores, t = 1:grid.T))
        push!(cost_vec, comt_cost)
    end
    if reserve
        reserve_cost = @expression(model, sum(grid.c_r_up[i] * reserve_up[i,t] + grid.c_r_down[i] * reserve_down[i,t] for i = 1:grid.geradores, t = 1:grid.T))
        push!(cost_vec, reserve_cost)
    end
    if deficit
        deficit_cost  = @expression(model, sum(grid.deficit_cost[i] * deficit[i,t] + grid.curtailment_cost[i] * curtailment[i,t] for i = 1:grid.geradores, t = 1:grid.T))
        deficit2_cost = @expression(model, sum(grid.deficit2_cost[i] * deficit_max[i,t] + grid.curtailment2_cost[i] * curtailment_max[i,t] for i = 1:grid.geradores, t = 1:grid.T))
        push!(cost_vec, deficit_cost)
        push!(cost_vec, deficit2_cost)
    end

    @objective(model, Min, sum(cost_vec[j] for j in 1:length(cost_vec)))

    # Solve
    optimize!(model)
    @info("Problem solved!")

    return objective_value(model), GridOutput(value.(g), value.(u), value.(f), value.(θ), value.(v), value.(w), value.(reserve_up), value.(reserve_down), value.(deficit), value.(g2), value.(f2), value.(θ2), value.(deficit2))
end