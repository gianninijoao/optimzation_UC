function get_data_original()
    # Horizonte
    T              = 24
    demanda        = zeros(3, T)
    demanda[3,:]   .+= 100

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
    ramp_up              = [100.0, 100.0, 40.0]              # Rampa máxima de subida
    ramp_down            = [100.0, 100.0, 40.0]              # Rampa máxima de escida
    ramp_startup         = [100.0, 100.0, 40.0]              # Rampa máxima ao ligar
    ramp_shutdown        = [100.0, 100.0, 40.0]              # Rampa máxima ao desligar
    custo_startup        = [0.0, 0.0, 0.0]                   # Custo de ligar
    custo_shutdown       = [0.0, 0.0, 0.0]                   # Custo de desligar

    # Linhas
    L             = 3
    Γ             = [1.0, 1.0, 1.0]                # Susceptância em cada linha
    fluxo_max     = [80.0, 20.0, 60.0]             # Fluxo máximo de cada linha
    L2B           = [-1 -1 0;                      # Relação entre linhas e barras (colunas representam linhas do sistema)
                    0 1 -1;
                    1 0 1] 

    # Contingente N-1
    # [scenario, element]
    gen_contingency         = vcat(ones(G, G) - I, ones(L, G))
    line_contingency        = vcat(ones(G, L), ones(L, L) - I)
    reserve_up_cost         = custo ./ 2
    reserve_down_cost       = custo ./ 2
    reserve_up_lim          = geracao_max ./ 2
    reserve_down_lim        = geracao_max ./ 2

    # Options
    use_uc = false
    use_ramps = false
    use_reserve = false
    use_contingency = false

    # Struct
    input = GridInput(custo, custo_startup, custo_shutdown, custo_deficit, custo_deficit2, custo_curtailment, custo_curtailment2, demanda, Γ, fluxo_max, geracao_min, geracao_max, ramp_up, ramp_down, ramp_startup, ramp_shutdown, gen_contingency, line_contingency, reserve_up_cost, reserve_down_cost, reserve_up_lim, reserve_down_lim, G, L, T)
    options = GridOptions(use_uc, use_ramps, use_reserve, use_contingency)
    return L2B, input, options

end

function get_data_rampa_off()
    # Horizonte
    T              = 24
    demanda        = zeros(3, T)
    demanda[3,:]   .+= 80
    demanda[3, 2:end] .+= 40

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
    ramp_up              = [100.0, 10.0, 40.0]              # Rampa máxima de subida
    ramp_down            = [100.0, 100.0, 40.0]              # Rampa máxima de escida
    ramp_startup         = [100.0, 10.0, 40.0]              # Rampa máxima ao ligar
    ramp_shutdown        = [100.0, 100.0, 40.0]              # Rampa máxima ao desligar
    custo_startup        = [0.0, 0.0, 0.0]                   # Custo de ligar
    custo_shutdown       = [0.0, 0.0, 0.0]                   # Custo de desligar

    # Linhas
    L             = 3
    Γ             = [1.0, 1.0, 1.0]                # Susceptância em cada linha
    fluxo_max     = [80.0, 20.0, 60.0]             # Fluxo máximo de cada linha
    L2B           = [-1 -1 0;                      # Relação entre linhas e barras (colunas representam linhas do sistema)
                    0 1 -1;
                    1 0 1] 

    # Contingente N-1
    # [scenario, element]
    gen_contingency         = vcat(ones(G, G) - I, ones(L, G))
    line_contingency        = vcat(ones(G, L), ones(L, L) - I)
    reserve_up_cost         = custo ./ 2
    reserve_down_cost       = custo ./ 2
    reserve_up_lim          = geracao_max ./ 2
    reserve_down_lim        = geracao_max ./ 2

    # Options
    use_uc = false
    use_ramps = false
    use_reserve = false
    use_contingency = false

    # Struct
    input = GridInput(custo, custo_startup, custo_shutdown, custo_deficit, custo_deficit2, custo_curtailment, custo_curtailment2, demanda, Γ, fluxo_max, geracao_min, geracao_max, ramp_up, ramp_down, ramp_startup, ramp_shutdown, gen_contingency, line_contingency, reserve_up_cost, reserve_down_cost, reserve_up_lim, reserve_down_lim, G, L, T)
    options = GridOptions(use_uc, use_ramps, use_reserve, use_contingency)
    return L2B, input, options

end

function get_data_rampa_on()
    # Horizonte
    T              = 24
    demanda        = zeros(3, T)
    demanda[3,:]   .+= 80
    demanda[3, 2:end] .+= 40

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
    ramp_up              = [100.0, 10.0, 40.0]              # Rampa máxima de subida
    ramp_down            = [100.0, 100.0, 40.0]              # Rampa máxima de escida
    ramp_startup         = [100.0, 10.0, 40.0]              # Rampa máxima ao ligar
    ramp_shutdown        = [100.0, 100.0, 40.0]              # Rampa máxima ao desligar
    custo_startup        = [0.0, 0.0, 0.0]                   # Custo de ligar
    custo_shutdown       = [0.0, 0.0, 0.0]                   # Custo de desligar

    # Linhas
    L             = 3
    Γ             = [1.0, 1.0, 1.0]                # Susceptância em cada linha
    fluxo_max     = [80.0, 20.0, 60.0]             # Fluxo máximo de cada linha
    L2B           = [-1 -1 0;                      # Relação entre linhas e barras (colunas representam linhas do sistema)
                    0 1 -1;
                    1 0 1] 

    # Contingente N-1
    # [scenario, element]
    gen_contingency         = vcat(ones(G, G) - I, ones(L, G))
    line_contingency        = vcat(ones(G, L), ones(L, L) - I)
    reserve_up_cost         = custo ./ 2
    reserve_down_cost       = custo ./ 2
    reserve_up_lim          = geracao_max ./ 2
    reserve_down_lim        = geracao_max ./ 2

    # Options
    use_uc = true
    use_ramps = true
    use_reserve = false
    use_contingency = false

    # Struct
    input = GridInput(custo, custo_startup, custo_shutdown, custo_deficit, custo_deficit2, custo_curtailment, custo_curtailment2, demanda, Γ, fluxo_max, geracao_min, geracao_max, ramp_up, ramp_down, ramp_startup, ramp_shutdown, gen_contingency, line_contingency, reserve_up_cost, reserve_down_cost, reserve_up_lim, reserve_down_lim, G, L, T)
    options = GridOptions(use_uc, use_ramps, use_reserve, use_contingency)
    return L2B, input, options

end

function get_data_reserve()
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
    ramp_up              = [100.0, 10.0, 40.0]              # Rampa máxima de subida
    ramp_down            = [100.0, 100.0, 40.0]              # Rampa máxima de escida
    ramp_startup         = [100.0, 10.0, 40.0]              # Rampa máxima ao ligar
    ramp_shutdown        = [100.0, 100.0, 40.0]              # Rampa máxima ao desligar
    custo_startup        = [0.0, 0.0, 0.0]                   # Custo de ligar
    custo_shutdown       = [0.0, 0.0, 0.0]                   # Custo de desligar

    # Linhas
    L             = 3
    Γ             = [1.0, 1.0, 1.0]                # Susceptância em cada linha
    fluxo_max     = [80.0, 20.0, 60.0]             # Fluxo máximo de cada linha
    L2B           = [-1 -1 0;                      # Relação entre linhas e barras (colunas representam linhas do sistema)
                    0 1 -1;
                    1 0 1] 

    # Contingente N-1
    # [scenario, element]
    gen_contingency         = vcat(ones(G, G) - I, ones(L, G))
    line_contingency        = vcat(ones(G, L), ones(L, L) - I)
    reserve_up_cost         = custo ./ 2
    reserve_down_cost       = custo ./ 2
    reserve_up_lim          = geracao_max ./ 2
    reserve_down_lim        = geracao_max ./ 2

    # Options
    use_uc = false
    use_ramps = false
    use_reserve = true
    use_contingency = true

    # Struct
    input = GridInput(custo, custo_startup, custo_shutdown, custo_deficit, custo_deficit2, custo_curtailment, custo_curtailment2, demanda, Γ, fluxo_max, geracao_min, geracao_max, ramp_up, ramp_down, ramp_startup, ramp_shutdown, gen_contingency, line_contingency, reserve_up_cost, reserve_down_cost, reserve_up_lim, reserve_down_lim, G, L, T)
    options = GridOptions(use_uc, use_ramps, use_reserve, use_contingency)
    return L2B, input, options

end

function get_data_reserve_and_ramp()
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
    ramp_up              = [100.0, 10.0, 40.0]              # Rampa máxima de subida
    ramp_down            = [100.0, 100.0, 40.0]              # Rampa máxima de escida
    ramp_startup         = [100.0, 10.0, 40.0]              # Rampa máxima ao ligar
    ramp_shutdown        = [100.0, 100.0, 40.0]              # Rampa máxima ao desligar
    custo_startup        = [0.0, 0.0, 0.0]                   # Custo de ligar
    custo_shutdown       = [0.0, 0.0, 0.0]                   # Custo de desligar

    # Linhas
    L             = 3
    Γ             = [1.0, 1.0, 1.0]                # Susceptância em cada linha
    fluxo_max     = [80.0, 20.0, 60.0]             # Fluxo máximo de cada linha
    L2B           = [-1 -1 0;                      # Relação entre linhas e barras (colunas representam linhas do sistema)
                    0 1 -1;
                    1 0 1] 

    # Contingente N-1
    # [scenario, element]
    gen_contingency         = vcat(ones(G, G) - I, ones(L, G))
    line_contingency        = vcat(ones(G, L), ones(L, L) - I)
    reserve_up_cost         = custo ./ 2
    reserve_down_cost       = custo ./ 2
    reserve_up_lim          = geracao_max ./ 2
    reserve_down_lim        = geracao_max ./ 2

    # Options
    use_uc = true
    use_ramps = true
    use_reserve = true
    use_contingency = true

    # Struct
    input = GridInput(custo, custo_startup, custo_shutdown, custo_deficit, custo_deficit2, custo_curtailment, custo_curtailment2, demanda, Γ, fluxo_max, geracao_min, geracao_max, ramp_up, ramp_down, ramp_startup, ramp_shutdown, gen_contingency, line_contingency, reserve_up_cost, reserve_down_cost, reserve_up_lim, reserve_down_lim, G, L, T)
    options = GridOptions(use_uc, use_ramps, use_reserve, use_contingency)
    return L2B, input, options

end