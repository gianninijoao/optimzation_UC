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