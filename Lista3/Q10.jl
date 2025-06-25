# ============================================================================ #
# ======================       Markowitz Problem       ======================= #
# ============================================================================ #

using JuMP, CSV, DataFrames, Statistics,LinearAlgebra, Gurobi
using Plots
using HiGHS

function Q10a(a)
    R = Matrix(a[:, 1:3])
    μ = mean(R, dims=1)
    Σ = cov(R)
    println(μ)

    w = fill(1/3, 3)
    retorno_esperado = dot(w,μ)
    variancia_carteira = w' * Σ * w

    println("Valor Esperado da Carteira: ", retorno_esperado[])
    println("Variância da Carteira: ", variancia_carteira[])
end

function Q10b(a)
    R = Matrix(a[:, 1:3])
    μ = vec(mean(R, dims=1))       
    Σ = cov(R)                     

    model = Model(HiGHS.Optimizer)

    @variable(model, x[1:3])                    
    @constraint(model, sum(x) == 1)                  
    @constraint(model, dot(μ, x) >= 0.14)            
    @objective(model, Min, x' * Σ * x)

    set_silent(model)
    optimize!(model)

    status = termination_status(model)
    if status == MOI.OPTIMAL
        println("Carteira ótima (pesos): ", value.(x))
        println("Variância mínima: ", objective_value(model))
        println("Retorno esperado da carteira: ", dot(μ, value.(x)))
    else
        println("O problema não tem solução ótima. Status: ", status)
    end
    
end

function Q10c(a)
    R = Matrix(a[:, 1:3])
    
    μ = vec(mean(R, dims=1))
    Σ = cov(R)

    retornos_desejados = range(0.0, stop=0.25, length=100)

    desvios = Float64[]
    retornos = Float64[]

    for Rmin in retornos_desejados
        model = Model(HiGHS.Optimizer)

        @variable(model, x[1:3])
        @constraint(model, sum(x) == 1)
        @constraint(model, dot(μ, x) >= Rmin)
        @objective(model, Min, x' * Σ * x)
        set_silent(model)
        optimize!(model)

        if termination_status(model) == MOI.OPTIMAL
            xopt = value.(x)
            push!(desvios, sqrt(dot(xopt, Σ * xopt)))  
            push!(retornos, dot(μ, xopt))              
        end
    end

    idx_min = argmin(desvios)

    desvios_inferior = desvios[1:idx_min]
    retornos_inferior = retornos[1:idx_min]

    desvios_superior = desvios[idx_min:end]
    retornos_superior = retornos[idx_min:end]

    p = plot(desvios, retornos, lc=:gray, label="Todas as carteiras", legend=:topright)
    plot!(desvios_superior, retornos_superior, seriestype=:scatter, marker=:circle, 
        mc=:green, label="Fronteira Eficiente", ms=4)
    scatter!([desvios[idx_min]], [retornos[idx_min]], markershape=:circle, 
        mc=:red, label="Menor Risco", ms=8)

    xlabel!("Risco (Desvio-Padrão)")
    ylabel!("Retorno Esperado")
    title!("Fronteira Eficiente")
    
    savefig("./Lista3/images/Q10c.png")
    return p
end

function Q10d(a)
    R = Matrix(a[:, 1:3])
    
    μ = vec(mean(R, dims=1))
    Σ = cov(R)

    retornos_desejados = range(-0.05, stop=0.35, length=300)

    desvios = Float64[]
    retornos = Float64[]

    for Rmin in retornos_desejados
        model = Model(HiGHS.Optimizer)

        @variable(model, x[1:3])
        @constraint(model, sum(x) == 1)
        @constraint(model, dot(μ, x) >= Rmin)
        @objective(model, Min, x' * Σ * x)

        set_silent(model)
        optimize!(model)

        if termination_status(model) == MOI.OPTIMAL
            xopt = value.(x)
            push!(desvios, sqrt(dot(xopt, Σ * xopt)))  # desvio padrão
            push!(retornos, dot(μ, xopt))              # retorno esperado
        end
    end


    idx_min = argmin(desvios)

    desvios_inferior = desvios[1:idx_min]
    retornos_inferior = retornos[1:idx_min]

    desvios_superior = desvios[idx_min:end]
    retornos_superior = retornos[idx_min:end]

    w_carteira = [0.2, 0.2, 0.6]
    retorno_carteira = dot(μ, w_carteira)
    desvio_carteira = sqrt(w_carteira' * Σ * w_carteira)

    println("Retorno da carteira fornecida: ", retorno_carteira)
    println("Desvio-padrão da carteira fornecida: ", desvio_carteira)

    plot(desvios, retornos, lc=:gray, label="Todas as carteiras", legend=:topright)
    plot!(desvios_superior, retornos_superior, seriestype=:scatter, marker=:circle, 
        mc=:green, label="Fronteira Eficiente", ms=4)
    scatter!([desvios[idx_min]], [retornos[idx_min]], markershape=:circle, 
        mc=:red, label="Menor Risco", ms=8)

    scatter!([desvio_carteira], [retorno_carteira], markershape=:circle, 
        mc=:blue, ms=10, label="Carteira Fornecida")

    xlabel!("Risco (Desvio-Padrão)")
    ylabel!("Retorno Esperado")
    title!("Fronteira Eficiente com Carteira Fornecida")

    savefig("./Lista3/images/Q10d.png")
end

function Q10e(a)
    R = Matrix(a[:, 1:3])
    μ = vec(mean(R, dims=1))      
    Σ = cov(R)                     

    model = Model(HiGHS.Optimizer)

    @variable(model, x[1:3])                    
    @constraint(model, sum(x) == 1)                  
    @constraint(model, dot(μ, x) >= 0.14)
    @constraint(model,  x[3] >= 0.4)          
    @objective(model, Min, x' * Σ * x)

    set_silent(model)
    optimize!(model)

    status = termination_status(model)
    if status == MOI.OPTIMAL
        println("Carteira ótima (pesos): ", value.(x))
        println("Variância mínima: ", objective_value(model))
        println("Retorno esperado da carteira: ", dot(μ, value.(x)))
    else
        println("O problema não tem solução ótima. Status: ", status)
    end
    
end

function Q10f(a)
    R = Matrix(a[:, 1:3])
    w = [0.2, 0.2, 0.6]

    retornos_carteira = R * w

    num_cenarios = length(retornos_carteira)
    cenarios_inferiores = sum(retornos_carteira .< 0.14)

    prob = cenarios_inferiores / num_cenarios

    println("Probabilidade do retorno da carteira ser inferior a 14%: ", prob)
end

function Q10g(a)
    R = Matrix(a[:, 1:3])
    μ = vec(mean(R, dims=1))       
    Σ = cov(R)                     

    model = Model(HiGHS.Optimizer)

    @variable(model, x[1:3] >= 0)                    
    @constraint(model, sum(x) == 1)                  
    @constraint(model, dot(μ, x) >= 0.2)            
    @objective(model, Min, x' * Σ * x)

    set_silent(model)
    optimize!(model)

    status = termination_status(model)
    if status == MOI.OPTIMAL
        println("Carteira ótima (pesos): ", value.(x))
        println("Variância mínima: ", objective_value(model))
        println("Retorno esperado da carteira: ", dot(μ, value.(x)))
    else
        println("O problema não tem solução ótima. Status: ", status)
    end
    
end

function Q10h(a)
    R = Matrix(a[:, 1:3])
    
    μ = vec(mean(R, dims=1))
    Σ = cov(R)
    rf = 0.14  

    model = Model(HiGHS.Optimizer)

    @variable(model, x[1:3])  
    @variable(model, x_f)     

    @constraint(model, sum(x) + x_f == 1)  
    @constraint(model, dot(μ, x) + rf * x_f >= 0.14)  

    @objective(model, Min, x' * Σ * x)  
    set_silent(model)
    optimize!(model)

    status = termination_status(model)
    if status == MOI.OPTIMAL
        println("Carteira ótima (ativos arriscados): ", value.(x))
        println("Proporção no ativo livre de risco: ", value(x_f))
        println("Variância mínima da carteira: ", objective_value(model))
        println("Retorno esperado da carteira: ", dot(μ, value.(x)) + rf * value(x_f))
    else
        println("O problema não tem solução ótima. Status: ", status)
    end
end

function Q10j(a)
    R = Matrix(a[:, 1:3])

    μ = vec(mean(R, dims=1))
    Σ = cov(R)
    rf = 0.04  

    model = Model(Gurobi.Optimizer)

    @variable(model, x[1:3])  
    @constraint(model, sum(x) == 1)  

    @constraint(model, x' * Σ * x <= 1)

    @objective(model, Max, dot(μ, x) - rf)

    set_silent(model)
    optimize!(model)

    status = termination_status(model)
    if status == MOI.OPTIMAL
        x_opt = value.(x)
        retorno = dot(μ, x_opt)
        variancia = x_opt' * Σ * x_opt
        desvio = sqrt(variancia)
        sharpe = (retorno - rf) / desvio

        println("Carteira ótima: ", x_opt)
        println("Retorno esperado: ", retorno)
        println("Variância: ", variancia)
        println("Desvio-padrão: ", desvio)
        println("Índice de Sharpe: ", sharpe)
    else
        println("Problema não resolvido. Status: ", status)
    end
    return retorno, desvio
end

function Q10k(a,p,μ_e,σ_e)
    R = Matrix(a[:, 1:3])

    μ = vec(mean(R, dims=1))
    Σ = cov(R)
    rf = 0.04

    num_pontos = 100
    retornos_alvo = range(0.0, stop=0.25, length=num_pontos)
    riscos = zeros(num_pontos)

    for (i, retorno_alvo) in enumerate(retornos_alvo)
        model = Model(HiGHS.Optimizer)
        @variable(model, x[1:3])
        @constraint(model, sum(x) == 1)
        @constraint(model, dot(μ, x) >= retorno_alvo)
        @objective(model, Min, x' * Σ * x)
        set_silent(model)
        optimize!(model)
        if termination_status(model) == MOI.OPTIMAL
            riscos[i] = sqrt(objective_value(model))
        else
            riscos[i] = NaN
        end
    end

    w_e = range(-0.5, stop=2.0, length=100)
    risco_cml = σ_e .* w_e
    retorno_cml = rf .+ w_e .* (μ_e - rf)

    plot!(p, risco_cml, retorno_cml, label="Fronteira Eficiente (CML)", linewidth=2, color=:red)
    scatter!(p, [0], [rf], label="Ativo Livre de Risco", color=:black)
    scatter!(p, [σ_e], [μ_e], label="Carteira Ótima", color=:blue)

    savefig("./Lista3/images/Q10k.png")
end

function main()
    filePath = @__DIR__;

    # ============================     Data Read    ============================== #

    Pathread    = string(filePath, "\\data\\IN_HistData.csv");
    df          = DataFrame(CSV.File(Pathread));
    a1           = df.Ativo1[:];
    a2           = df.Ativo2[:];
    a3           = df.Ativo3[:];
    a            = hcat(a1, a2, a3)

    # ============================================================================ #
    println("==============================\n")
    println("Questão 10, letra a)")
    Q10a(a)
    println("==============================\n")
    println("Questão 10, letra b)")
    Q10b(a)
    println("==============================\n")
    println("Questão 10, letra c)")
    p = Q10c(a)
    println("==============================\n")
    println("Questão 10, letra d)")
    Q10d(a)
    println("==============================\n")
    println("Questão 10, letra e)")
    Q10e(a)
    println("==============================\n")
    println("Questão 10, letra f)")
    Q10f(a)
    println("==============================\n")
    println("Questão 10, letra g)")
    Q10g(a)
    println("==============================\n")
    println("Questão 10, letra h)")
    Q10h(a)
    println("==============================\n")
    println("Questão 10, letra j)")
    μ_e,σ_e = Q10j(a)
    println("==============================\n")
    println("Questão 10, letra k)")
    Q10k(a,p,μ_e,σ_e)
end

main()