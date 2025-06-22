using Plots, JuMP, Gurobi, HiGHS

function Q9b()
    # Parâmetros dos ativos
    μA = 0.10     # Retorno esperado do Ativo A
    μM = 0.24     # Retorno esperado do Ativo de Mercado
    σA = 0.28     # Desvio-padrão do Ativo A
    σM = 0.32     # Desvio-padrão do Ativo Mercado
    ρAM = 0.254   # Correlação entre os ativos

    # Intervalo de alocação: x ∈ [-1.0, 2.0]
    xs = -1.0:0.01:2.0

    # Calcula os pontos (σ, μ)
    μC = Float64[]
    σC = Float64[]

    for x in xs
        μ = x * μM + (1 - x) * μA
        σ² = x^2 * σM^2 + (1 - x)^2 * σA^2 + 2 * x * (1 - x) * ρAM * σA * σM
        σ = sqrt(σ²)

        push!(μC, μ)
        push!(σC, σ)
    end

    # Combinar e ordenar por risco
    carteiras = collect(zip(σC, μC))
    sort!(carteiras, by = x -> x[1])  # Ordena por risco (σ)

    # Filtra apenas pontos eficientes (retorno crescente com risco)
    σ_efficient = Float64[]
    μ_efficient = Float64[]
    max_μ = -Inf

    for (σ, μ) in carteiras
        if μ >  max_μ
            push!(σ_efficient, σ)
            push!(μ_efficient, μ)
            max_μ = μ
        end
    end

    # Plot completo
    p = plot(σC, μC,
        color=:gray, label="Todas as carteiras", lw=1, alpha=0.4,
        xlabel="Risco (Desvio-Padrão)",
        ylabel="Retorno Esperado",
        title="Fronteira Eficiente",
        legend=:topleft,
        grid=true)

    # Fronteira eficiente (parte de cima apenas)
    plot!(σ_efficient, μ_efficient,
        color=:green, lw=2, label="Fronteira Eficiente", marker=:circle)


    savefig("./Lista3/images/Q9b.png")
    return p
end

function Q9c(p)

    # Parâmetros
    σA = 0.28
    σM = 0.32
    ρAM = 0.254

    # Criação do modelo
    model = Model(Gurobi.Optimizer)

    @variable(model, -1 <= x <= 2)  # fração no Ativo Mercado

    # Variância da carteira como função de x
    @objective(model, Min, x^2 * σM^2 + (1 - x)^2 * σA^2 + 2 * x * (1 - x) * ρAM * σA * σM)

    optimize!(model)

    # Recuperar a solução ótima
    x_opt = value(x)
    σ_opt = sqrt(x_opt^2 * σM^2 + (1 - x_opt)^2 * σA^2 + 2 * x_opt * (1 - x_opt) * ρAM * σA * σM)

    # Retornos esperados
    μA = 0.10
    μM = 0.24
    μ_opt = x_opt * μM + (1 - x_opt) * μA

    println("Alocação ótima no Ativo Mercado: x = ", x_opt)
    println("Retorno Esperado da Carteira: ", μ_opt)
    println("Desvio-Padrão da Carteira: ", σ_opt)
    p = scatter!([σ_opt], [μ_opt], label="Menor Risco", color=:red, markersize=6)
    savefig("./Lista3/images/Q9c.png")
end

function Q9f()
    # Parâmetros dos ativos
    μM = 0.24     # Retorno esperado do Ativo de Mercado
    σf = 0.00     # Desvio-padrão do Ativo livre de Risco
    σM = 0.32     # Desvio-padrão do Ativo Mercado
    rf = 0.06     # Retorno fixo

    # Intervalo de alocação: x ∈ [-1.0, 2.0]
    xs = -1.0:0.01:2.0

    # Calcula os pontos (σ, μ)
    μC = Float64[]
    σC = Float64[]

    for x in xs
        μ = x * μM + (1 - x) * rf
        σ = x*σM

        push!(μC, μ)
        push!(σC, σ)
    end

    # Combinar e ordenar por risco
    carteiras = collect(zip(σC, μC))
    sort!(carteiras, by = x -> x[1])  # Ordena por risco (σ)

    # Filtra apenas pontos eficientes (retorno crescente com risco)
    σ_efficient = Float64[]
    μ_efficient = Float64[]
    max_μ = -Inf

    for (σ, μ) in carteiras
        if μ >  max_μ
            push!(σ_efficient, σ)
            push!(μ_efficient, μ)
            max_μ = μ
        end
    end

    # Plot completo
    p = plot(σC, μC,
        color=:gray, label="Todas as carteiras", lw=1, alpha=0.4,
        xlabel="Risco (Desvio-Padrão)",
        ylabel="Retorno Esperado",
        title="Fronteira Eficiente",
        legend=:topleft,
        grid=true)

    # Fronteira eficiente (parte de cima apenas)
    plot!(σ_efficient, μ_efficient,
        color=:green, lw=2, label="Fronteira Eficiente", marker=:circle)


    savefig("./Lista3/images/Q9f.png")
    return p
end

function Q9g(p)

    # Parâmetros
    σM = 0.32

    # Criação do modelo
    model = Model(Gurobi.Optimizer)

    @variable(model, -1 <= x <= 2)  # fração no Ativo Mercado

    # Variância da carteira como função de x
    @objective(model, Min, x^2*σM^2)

    optimize!(model)

    # Recuperar a solução ótima
    x_opt = value(x)
    σ_opt = sqrt(x_opt^2 * σM^2)

    # Retornos esperados
    rf = 0.06
    μM = 0.24
    μ_opt = x_opt * μM + (1 - x_opt) * rf

    println("Alocação ótima no Ativo Mercado: x = ", x_opt)
    println("Retorno Esperado da Carteira: ", μ_opt)
    println("Desvio-Padrão da Carteira: ", σ_opt)
    p = scatter!([σ_opt], [μ_opt], label="Menor Risco", color=:red, markersize=6)
    savefig("./Lista3/images/Q9g.png")
end

function main()
    #println("==============================\n")
    #println("Questão 9, letra b)")
    #p = Q9b()
    #println("==============================\n")
    #println("Questão 9, letra c)")
    #Q9c(p)
    println("==============================\n")
    println("Questão 9, letra f)")
    p = Q9f()
    println("==============================\n")
    println("Questão 9, letra g)")
    Q9g(p)
end

main()