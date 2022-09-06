mutable struct GridInput
    # Custos
    c::Vector{Float64}
    c_su::Vector{Float64}
    c_sd::Vector{Float64}
    # Custos de Deficit
    deficit_cost::Vector{Float64}
    deficit2_cost::Vector{Float64}
    curtailment_cost::Vector{Float64}
    curtailment2_cost::Vector{Float64}
    # Demanda
    d::Array{Float64,2}
    # Linhas
    Γ::Vector{Float64}
    # Limites de variáveis
    fluxo_max::Vector{Float64}
    geracao_min::Vector{Float64}
    geracao_max::Vector{Float64}
    # Rampa
    ramp_up::Vector{Float64}
    ramp_down::Vector{Float64}
    ramp_startup::Vector{Float64}
    ramp_shutdown::Vector{Float64}
    # Contingências
    g_cont::Array{Float64,2}
    l_cont::Array{Float64,2}
    c_r_up::Vector{Float64}
    c_r_down::Vector{Float64}
    reserve_up_lim::Vector{Float64}
    reserve_down_lim::Vector{Float64}
    # Conjuntos
    geradores::Int64
    linhas::Int64
    T::Int64
end

mutable struct GridOptions
    use_uc::Bool
    use_ramps::Bool
    use_reserve::Bool
    use_contingency::Bool
end

mutable struct GridOutput
    # Primeiro estágio
    g::Array{Float64,2}
    u::Array{Int64,2}
    f::Array{Float64,2}
    θ::Array{Float64,2}
    v::Array{Float64,2}
    w::Array{Float64,2}
    r_up::Array{Float64,2}
    r_down::Array{Float64,2}
    deficit::Array{Float64,2}
    # Segundo estágio
    g2::Array{Float64,3}
    f2::Array{Float64,3}
    θ2::Array{Float64,3}
    deficit2::Array{Float64,3}
end