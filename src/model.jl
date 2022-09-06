function run_solver(L2B::Matrix{Int64}, grid::GridInput, options::GridOptions)
    @info("Starting to create optimization model!")

    n_scen = grid.geradores + grid.linhas

    model = Model(HiGHS.Optimizer) 

    #----------------------------------- Variáveis --------------------------------------

    @variables(model, begin
        # Geração
        g[1:grid.geradores, 1:grid.T] >= 0              # Variável g com G geradores e valor para cada hora
        # Fluxo
        f[1:grid.linhas, 1:grid.T]                      # Variável f com L fluxos nas linhas
        # Fase
        θ[1:grid.geradores, 1:grid.T]                   # Variável theta com L defasagens para cada barr
        # Déficit
        deficit[1:grid.geradores, 1:grid.T] >= 0
        # Curtailment
        curtailment[1:grid.geradores, 1:grid.T] >= 0
    end)

    if options.use_uc
        @variables(model, begin
            u[1:grid.geradores, 1:grid.T], Bin              # Variável u, BINÁRIA, para determinar os geradores que estão ligados/desligados e valor para cada hora
            0 <= v[1:grid.geradores, 1:grid.T] <= 1         # Variável v, com G indicações se o gerador está sendo ligado e valor para cada hora
            0 <= w[1:grid.geradores, 1:grid.T] <= 1         # Variável w, com G indicações se o gerador está sendo desligado e valor para cada hora
        end)
    end

    if options.use_reserve
        @variables(model, begin
            reserve_up[1:grid.geradores, 1:grid.T] >= 0     # Variável de reserva de subida com G geradores e valor para cada hora
            reserve_down[1:grid.geradores, 1:grid.T] >= 0   # Variável de reserva de subida com G geradores e valor para cada hora
        end)
    end

    if options.use_contingency
        @variables(model, begin
            θ2[1:grid.geradores, 1:grid.T, 1:n_scen]
            f2[1:grid.linhas, 1:grid.T, 1:n_scen]
            g2[1:grid.geradores, 1:grid.T, 1:n_scen] >= 0
            # Déficit
            deficit2[1:grid.geradores, 1:grid.T, 1:n_scen] >= 0
            deficit_max[1:grid.geradores, 1:grid.T] >= 0
            # Curtailment
            curtailment2[1:grid.geradores, 1:grid.T, 1:n_scen] >= 0
            curtailment_max[1:grid.geradores, 1:grid.T] >= 0
        end)
    end

    #----------------------------------- Restrições --------------------------------------

    @constraints(model, begin 
        # ---------- Primeiro estágio ----------
        # Fluxo
        [i = 1:grid.linhas, t = 1:grid.T], f[i,t] <= grid.fluxo_max[i]                                           # Fluxo de cada gerador deve estar entre -fluxo máximo e fluxo máximo
        [i = 1:grid.linhas, t = 1:grid.T], f[i,t] >= -grid.fluxo_max[i]
        # Fase
        [t = 1:grid.T], θ[1,t] == 0
        # KVL
        [i = 1:grid.linhas, t = 1:grid.T], sum(-permutedims(L2B)[i, :] .* θ[:,t]) == f[i,t] * grid.Γ[i]          # A diferença de fase entre 2 linhas é igual ao fluxo entre elas
        # KCL
        [i = 1:grid.geradores, t = 1:grid.T], g[i, t] + sum(L2B[i, :] .* f[:, t]) + deficit[i,t] - curtailment[i,t] == grid.d[i,t]
    end)
    
    if options.use_uc
        @constraints(model, begin
                [i = 1:grid.geradores], v[i,1] - w[i,1] == u[i,1] - u[i,grid.T]                                          # Implicitamente faz u[0] = u[T]
                [i = 1:grid.geradores, t = 2:grid.T], v[i,t] - w[i,t] == u[i,t] - u[i,t-1]                               # Determinando se o gerador está sendo ligado ou desligado
                [i = 1:grid.geradores, t = 1:grid.T], v[i,t] <= u[i,t]
                [i = 1:grid.geradores, t = 1:grid.T], w[i,t] <= 1 - u[i,t]
            end)

        if options.use_reserve
            @constraints(model, begin
                [i = 1:grid.geradores, t = 1:grid.T], g[i,t] - reserve_down[i,t] >= grid.geracao_min[i] * u[i,t]         # Potência de cada gerador deve estar entre o mínimo e o máximo
                [i = 1:grid.geradores, t = 1:grid.T], g[i,t] + reserve_up[i,t] <= grid.geracao_max[i] * u[i,t]
            end)
        else
            @constraints(model, begin
                [i = 1:grid.geradores, t = 1:grid.T], g[i,t] >= grid.geracao_min[i] * u[i,t]         # Potência de cada gerador deve estar entre o mínimo e o máximo
                [i = 1:grid.geradores, t = 1:grid.T], g[i,t] <= grid.geracao_max[i] * u[i,t]
            end)
        end
    else
        if !options.use_reserve
            @constraints(model, begin
                [i = 1:grid.geradores, t = 1:grid.T], g[i,t] >= grid.geracao_min[i]         # Potência de cada gerador deve estar entre o mínimo e o máximo
                [i = 1:grid.geradores, t = 1:grid.T], g[i,t] <= grid.geracao_max[i]
            end)
        else
            @constraints(model, begin
                [i = 1:grid.geradores, t = 1:grid.T], g[i,t] - reserve_down[i,t] >= grid.geracao_min[i]         # Potência de cada gerador deve estar entre o mínimo e o máximo
                [i = 1:grid.geradores, t = 1:grid.T], g[i,t] + reserve_up[i,t] <= grid.geracao_max[i]
            end)
        end
    end

    if options.use_ramps
        @constraints(model, begin
            [i = 1:grid.geradores, t = 2:grid.T], g[i,t] - g[i,t-1] <= grid.ramp_up[i] * u[i,t-1] + grid.ramp_startup[i] * v[i,t]
            [i = 1:grid.geradores, t = 2:grid.T], g[i,t-1] - g[i,t] <= grid.ramp_down[i] * u[i,t] + grid.ramp_shutdown[i] * w[i,t]
        end)
    end

    if options.use_reserve
        @constraints(model, begin
            [i = 1:grid.geradores, t = 1:grid.T], reserve_up[i,t] <= grid.reserve_up_lim[i]
            [i = 1:grid.geradores, t = 1:grid.T], reserve_down[i,t] <= grid.reserve_down_lim[i]
        end)
    end

    if options.use_ramps && options.use_reserve
        @constraints(model, begin
            [i = 1:grid.geradores, t = 2:grid.T], g[i,t] + reserve_up[i,t] <= g[i,t-1] - reserve_down[i,t-1] + grid.ramp_up[i]
            [i = 1:grid.geradores, t = 2:grid.T], g[i,t] - reserve_down[i,t] >= g[i,t-1] + reserve_up[i,t-1] - grid.ramp_down[i]
        end)
    end

    if options.use_contingency
        @constraints(model, begin
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
    end

    #----------------------------------- Definição da função objetivo do modelo --------------------------------------
    cost_vec = []

    # Custo de geração
    gen_cost = @expression(model, sum(grid.c[i] * g[i,t] for i = 1:grid.geradores, t = 1:grid.T))
    push!(cost_vec, gen_cost)

    # Custo de déficit
    deficit_cost  = @expression(model, sum(grid.deficit_cost[i] * deficit[i,t] + grid.curtailment_cost[i] * curtailment[i,t] for i = 1:grid.geradores, t = 1:grid.T))
    push!(cost_vec, deficit_cost)

    # Custo de commitment
    if options.use_uc
        comt_cost = @expression(model, sum(grid.c_su[i] * v[i,t] + grid.c_sd[i] * w[i,t] for i = 1:grid.geradores, t = 1:grid.T))
        push!(cost_vec, comt_cost)
    end

    # Custo de reserva
    if options.use_reserve
        reserve_cost = @expression(model, sum(grid.c_r_up[i] * reserve_up[i,t] + grid.c_r_down[i] * reserve_down[i,t] for i = 1:grid.geradores, t = 1:grid.T))
        push!(cost_vec, reserve_cost)
    end
    
    # Custo de déficit pós-contingência
    if options.use_contingency
        deficit2_cost = @expression(model, sum(grid.deficit2_cost[i] * deficit_max[i,t] + grid.curtailment2_cost[i] * curtailment_max[i,t] for i = 1:grid.geradores, t = 1:grid.T))
        push!(cost_vec, deficit2_cost)
    end

    @objective(model, Min, sum(cost_vec))

    # Solve
    optimize!(model)
    @info("Problem solved!")

    #----------------------------------- Pega outputs --------------------------------------

    g_out = value.(g)
    f_out = value.(f)
    θ_out = value.(θ)
    deficit_out = value.(deficit)
    # curtailment_out = value.(curtailment)

    if options.use_uc
        u_out = round.(value.(u))
        v_out = value.(v)
        w_out = value.(w)
    else
        u_out = zeros(Int64, grid.geradores, grid.T)
        v_out = zeros(grid.geradores, grid.T)
        w_out = zeros(grid.geradores, grid.T)
    end

    if options.use_reserve
        reserve_up_out = value.(reserve_up)
        reserve_down_out = value.(reserve_down)
    else
        reserve_up_out = zeros(grid.geradores, grid.T)
        reserve_down_out = zeros(grid.geradores, grid.T)
    end

    if options.use_contingency
        θ2_out = value.(θ2)
        f2_out = value.(f2)
        g2_out = value.(g2)
        deficit2_out = value.(deficit2)
        deficit_max_out = value.(deficit_max)
        curtailment2_out = value.(curtailment2)
        curtailment_max_out = value.(curtailment_max)
    else
        θ2_out = zeros(grid.geradores, grid.T, n_scen)
        f2_out = zeros(grid.linhas, grid.T, n_scen)
        g2_out = zeros(grid.geradores, grid.T, n_scen)
        deficit2_out = zeros(grid.geradores, grid.T, n_scen)
        deficit_max_out = zeros(grid.geradores, grid.T)
        curtailment2_out = zeros(grid.geradores, grid.T, n_scen)
        curtailment_max_out = zeros(grid.geradores, grid.T)
    end

    @show g_out
    @show u_out
    # @show f_out
    # @show θ_out
    @show v_out
    @show w_out
    # @show reserve_up_out
    # @show reserve_down_out
    # @show deficit_out
    # @show g2_out
    # @show f2_out
    # @show θ2_out
    # @show deficit2_out

    return objective_value(model), GridOutput(g_out, u_out, f_out, θ_out, v_out, w_out, reserve_up_out, reserve_down_out, deficit_out, g2_out, f2_out, θ2_out, deficit2_out)
end