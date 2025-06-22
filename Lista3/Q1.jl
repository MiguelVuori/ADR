# ============================================================================ #
# ======================       Newsvendor Problem       ====================== #
# ============================================================================ #

using Distributions, Random
using Plots
using JuMP
using GLPK              # Solver Gratuito de Programação Linear & Inteira Mista - https://github.com/jump-dev/GLPK.jl | https://www.gnu.org/software/glpk/
using HiGHS

# ======================     Parâmetros do Problema   ======================== #
function Q1c()
    u = 150;
    q = 60;
    r = 10;
    c = 20;
    γ = 0.1;
    flag_tax = false;

    nLines = 3;
    SetLines = 1:nLines;
    p_break = [0.00 ; 1500 ; 3000];
    β2 = [1.00 ;  0.75 ; 0.50];
    β1 = [0.00 ; (β2[1] - β2[2])*p_break[2] ; ((β2[1] - β2[2])*p_break[2] + p_break[3]*(β2[2] - β2[3]))];

    if (flag_tax) plot_tax(u, q, c, β1, β2); end;

    # ============================================================================ #

    # ========================     Sampling Process     ========================== #

    nCenarios = 20;                   # Number of Scenarios
    Ω = 1:nCenarios;                    # Set of Scenarios
    p = ones(nCenarios)*(1/nCenarios);  # Equal Probability

    dmin = 50;
    dmax = 150;

    # ===================================
    #      =====> Using Julia <=====     
    # ===================================

    Random.seed!(1);
    d  = rand(Uniform(dmin, dmax), nCenarios);


    NewsVendorProb = Model(HiGHS.Optimizer);

    # ========== Variáveis de Decisão ========== #

    @variable(NewsVendorProb, x >= 0);
    @variable(NewsVendorProb, y_1[Ω] >= 0);
    @variable(NewsVendorProb, y_2[Ω] >= 0);
    @variable(NewsVendorProb, R_a[Ω]);

    # ========== Restrições ========== #

    @constraint(NewsVendorProb, Rest1, x <= u);
    @constraint(NewsVendorProb, Rest2[ω in Ω], y_1[ω] <= d[ω]);
    @constraint(NewsVendorProb, Rest3[ω in Ω], y_1[ω] + y_2[ω] <= x);
    @constraint(NewsVendorProb, Rest4[ω in Ω], R_a[ω] == q*y_1[ω] + r*y_2[ω] - c*x);
    @constraint(NewsVendorProb, Rest6[ω in Ω], y_2[ω] <= γ*x)

    # ========== Função Objetivo ========== #

    if (flag_tax)
    @objective(NewsVendorProb, Max, sum(R[ω]*p[ω] for ω in Ω));
    else
    @objective(NewsVendorProb, Max, sum(R_a[ω]*p[ω] for ω in Ω));
    end
    set_silent(NewsVendorProb)
    optimize!(NewsVendorProb);

    status      = termination_status(NewsVendorProb);

    Profit      = JuMP.objective_value(NewsVendorProb);
    xOpt        = JuMP.value.(x);
    yOpt        = JuMP.value.(y_1);
    zOpt        = JuMP.value.(y_2);

    println("==============================\n")
    println("Status: ", status);
    println("Lucro Jornaleiro: ", Profit);
    println("Quant. Jornais: ", xOpt);
    println("\n==============================")
end

function Q1e()
    nCenarios = 1:1:1000
    receitasOtimas = []
    solucoesOtimas = []
    for cenario in nCenarios
        u = 150;
        q = 60;
        r = 10;
        c = 20;
        γ = 0.1;
        flag_tax = false;

        nLines = 3;
        SetLines = 1:nLines;
        p_break = [0.00 ; 1500 ; 3000];
        β2 = [1.00 ;  0.75 ; 0.50];
        β1 = [0.00 ; (β2[1] - β2[2])*p_break[2] ; ((β2[1] - β2[2])*p_break[2] + p_break[3]*(β2[2] - β2[3]))];

        if (flag_tax) plot_tax(u, q, c, β1, β2); end;

        # ============================================================================ #

        # ========================     Sampling Process     ========================== #

        Ω = 1:cenario;                    # Set of Scenarios
        p = ones(cenario)*(1/cenario);  # Equal Probability

        dmin = 50;
        dmax = 150;

        # ===================================
        #      =====> Using Julia <=====     
        # ===================================

        Random.seed!(1);
        d  = rand(Uniform(dmin, dmax), cenario);


        NewsVendorProb = Model(HiGHS.Optimizer);

        # ========== Variáveis de Decisão ========== #

        @variable(NewsVendorProb, x >= 0);
        @variable(NewsVendorProb, y_1[Ω] >= 0);
        @variable(NewsVendorProb, y_2[Ω] >= 0);
        @variable(NewsVendorProb, R_a[Ω]);

        # ========== Restrições ========== #

        @constraint(NewsVendorProb, Rest1, x <= u);
        @constraint(NewsVendorProb, Rest2[ω in Ω], y_1[ω] <= d[ω]);
        @constraint(NewsVendorProb, Rest3[ω in Ω], y_1[ω] + y_2[ω] <= x);
        @constraint(NewsVendorProb, Rest4[ω in Ω], R_a[ω] == q*y_1[ω] + r*y_2[ω] - c*x);
        @constraint(NewsVendorProb, Rest6[ω in Ω], y_2[ω] <= γ*x)

        # ========== Função Objetivo ========== #

        if (flag_tax)
        @objective(NewsVendorProb, Max, sum(R[ω]*p[ω] for ω in Ω));
        else
        @objective(NewsVendorProb, Max, sum(R_a[ω]*p[ω] for ω in Ω));
        end
        set_silent(NewsVendorProb)
        optimize!(NewsVendorProb);

        status      = termination_status(NewsVendorProb);

        Profit      = JuMP.objective_value(NewsVendorProb);
        xOpt        = JuMP.value.(x);
        yOpt        = JuMP.value.(y_1);
        zOpt        = JuMP.value.(y_2);

        push!(receitasOtimas,Profit)
        push!(solucoesOtimas,xOpt)
    end
    plot(nCenarios, receitasOtimas, label="Receita sob solução SAA", xlabel="Número de Cenários (N)",
     ylabel="Receita Esperada", title="Consistência do SAA")
    hline!([3406], color=:blue, label="Receita ótima real")
    savefig("./Lista3/images/Q1e1.png")
    plot(nCenarios, solucoesOtimas, label="Solução do SAA", xlabel="Número de Cenários (N)",
     ylabel="Solução", title="Consistência do SAA")
    hline!([120], color=:blue, label="Solução ótima real")
    savefig("./Lista3/images/Q1e2.png")
end

function Q1f()
    function cvar(alpha::Float64, probs::Vector{Float64}, revenues::Vector{Float64})
        @assert length(probs) == length(revenues) 
        @assert isapprox(sum(probs), 1.0; atol=1e-6) 

        # Ordena as receitas de menor para maior (menores = piores resultados)
        sorted_indices = sortperm(revenues)
        sorted_revenues = revenues[sorted_indices]
        sorted_probs = probs[sorted_indices]

        # Acumula as probabilidades até cobrir (1 - alpha)
        cumulative = 0.0
        cvar_value = 0.0

        for i in 1:length(sorted_revenues)
            if cumulative + sorted_probs[i] <= 1 - alpha
                cvar_value += sorted_revenues[i] * sorted_probs[i]
                cumulative += sorted_probs[i]
            else
                excess = (1 - alpha) - cumulative
                cvar_value += sorted_revenues[i] * excess
                break
            end
        end

        return cvar_value / (1 - alpha)
    end

    u = 150;
    q = 60;
    r = 10;
    c = 20;
    γ = 0.1;
    x = 120;
    flag_tax = false;

    nLines = 3;
    SetLines = 1:nLines;
    p_break = [0.00 ; 1500 ; 3000];
    β2 = [1.00 ;  0.75 ; 0.50];
    β1 = [0.00 ; (β2[1] - β2[2])*p_break[2] ; ((β2[1] - β2[2])*p_break[2] + p_break[3]*(β2[2] - β2[3]))];

    if (flag_tax) plot_tax(u, q, c, β1, β2); end;

    # ============================================================================ #

    # ========================     Sampling Process     ========================== #

    nCenarios = 100000;                   # Number of Scenarios
    Ω = 1:nCenarios;                    # Set of Scenarios
    p = ones(nCenarios)*(1/nCenarios);  # Equal Probability

    dmin = 50;
    dmax = 150;

    # ===================================
    #      =====> Using Julia <=====     
    # ===================================

    Random.seed!(1);
    ds  = rand(Uniform(dmin, dmax), nCenarios);
    receitasOtimas = Float64[]
    for d in ds
        NewsVendorProb = Model(HiGHS.Optimizer);

        # ========== Variáveis de Decisão ========== #

        @variable(NewsVendorProb, y_1 >= 0);
        @variable(NewsVendorProb, y_2 >= 0);
        @variable(NewsVendorProb, R_a);

        # ========== Restrições ========== #

        @constraint(NewsVendorProb, Rest1, x <= u);
        @constraint(NewsVendorProb, Rest2, y_1 <= d);
        @constraint(NewsVendorProb, Rest3, y_1 + y_2 <= x);
        @constraint(NewsVendorProb, Rest4, R_a == q*y_1 + r*y_2 - c*x);
        @constraint(NewsVendorProb, Rest6, y_2 <= γ*x)

        # ========== Função Objetivo ========== #


        @objective(NewsVendorProb, Max, R_a);

        set_silent(NewsVendorProb)
        optimize!(NewsVendorProb);

        status      = termination_status(NewsVendorProb);

        Profit      = JuMP.objective_value(NewsVendorProb);
        yOpt        = JuMP.value.(y_1);
        zOpt        = JuMP.value.(y_2);

        push!(receitasOtimas,Profit)
    end

    α = 0.95
    valor_cvar = cvar(α, p, receitasOtimas)
    println("CVaR_$(α) da receita: ", valor_cvar)   
end

function Q1g()
    u = 150;
    q = 60;
    r = 10;
    c = 20;
    γ = 0.1;
    α = 0.95;
    R_hat = -2000;

    nLines = 3;
    SetLines = 1:nLines;
    p_break = [0.00 ; 1500 ; 3000];
    β2 = [1.00 ;  0.75 ; 0.50];
    β1 = [0.00 ; (β2[1] - β2[2])*p_break[2] ; ((β2[1] - β2[2])*p_break[2] + p_break[3]*(β2[2] - β2[3]))];

    # ============================================================================ #

    # ========================     Sampling Process     ========================== #

    nCenarios = 10000;                   # Number of Scenarios
    Ω = 1:nCenarios;                    # Set of Scenarios
    p = ones(nCenarios)*(1/nCenarios);  # Equal Probability

    dmin = 50;
    dmax = 150;

    # ===================================
    #      =====> Using Julia <=====     
    # ===================================

    Random.seed!(1);
    d  = rand(Uniform(dmin, dmax), nCenarios);


    NewsVendorProb = Model(HiGHS.Optimizer);

    # ========== Variáveis de Decisão ========== #

    @variable(NewsVendorProb, x >= 0);
    @variable(NewsVendorProb, y_1[Ω] >= 0);
    @variable(NewsVendorProb, y_2[Ω] >= 0);
    @variable(NewsVendorProb, R_a[Ω]);
    

    @variable(NewsVendorProb, z);
    @variable(NewsVendorProb, δ[Ω] >= 0);

    # ========== Restrições ========== #

    @constraint(NewsVendorProb, Rest1, x <= u);
    @constraint(NewsVendorProb, Rest2[ω in Ω], y_1[ω] <= d[ω]);
    @constraint(NewsVendorProb, Rest3[ω in Ω], y_1[ω] + y_2[ω] <= x);
    @constraint(NewsVendorProb, Rest4[ω in Ω], R_a[ω] == q*y_1[ω] + r*y_2[ω] - c*x);
    @constraint(NewsVendorProb, Rest6[ω in Ω], y_2[ω] <= γ*x)


    @constraint(NewsVendorProb, Rest7, z - sum(p[ω]*δ[ω] for ω in Ω)/(1 - α) >= -R_hat)
    @constraint(NewsVendorProb, Rest8[ω in Ω], δ[ω] >= z - R_a[ω])

    # ========== Função Objetivo ========== #

    @objective(NewsVendorProb, Max, sum(R_a[ω]*p[ω] for ω in Ω));

    set_silent(NewsVendorProb)
    optimize!(NewsVendorProb);

    status      = termination_status(NewsVendorProb);

    Profit      = JuMP.objective_value(NewsVendorProb);
    xOpt        = JuMP.value.(x);
    yOpt        = JuMP.value.(y_1);
    zOpt        = JuMP.value.(y_2);

    println("==============================\n")
    println("Status: ", status);
    println("Lucro Jornaleiro: ", Profit);
    println("Quant. Jornais: ", xOpt);
    println("\n==============================")
end

function Q1h()
    u = 150;
    q = 60;
    r = 10;
    c = 20;
    γ = 0.1;
    α = 0.95;
    λ = 0.5;

    # ============================================================================ #

    # ========================     Sampling Process     ========================== #

    nCenarios = 10000;                   # Number of Scenarios
    Ω = 1:nCenarios;                    # Set of Scenarios
    p = ones(nCenarios)*(1/nCenarios);  # Equal Probability

    dmin = 50;
    dmax = 150;

    # ===================================
    #      =====> Using Julia <=====     
    # ===================================

    Random.seed!(1);
    d  = rand(Uniform(dmin, dmax), nCenarios);


    NewsVendorProb = Model(HiGHS.Optimizer);

    # ========== Variáveis de Decisão ========== #

    @variable(NewsVendorProb, x >= 0);
    @variable(NewsVendorProb, y_1[Ω] >= 0);
    @variable(NewsVendorProb, y_2[Ω] >= 0);
    @variable(NewsVendorProb, R_a[Ω]);
    @variable(NewsVendorProb, CVaR);
    

    @variable(NewsVendorProb, z);
    @variable(NewsVendorProb, δ[Ω] >= 0);

    # ========== Restrições ========== #

    @constraint(NewsVendorProb, Rest1, x <= u);
    @constraint(NewsVendorProb, Rest2[ω in Ω], y_1[ω] <= d[ω]);
    @constraint(NewsVendorProb, Rest3[ω in Ω], y_1[ω] + y_2[ω] <= x);
    @constraint(NewsVendorProb, Rest4[ω in Ω], R_a[ω] == q*y_1[ω] + r*y_2[ω] - c*x);
    @constraint(NewsVendorProb, Rest6[ω in Ω], y_2[ω] <= γ*x)


    @constraint(NewsVendorProb, Rest7, -CVaR == z - sum(p[ω]*δ[ω] for ω in Ω)/(1 - α))
    @constraint(NewsVendorProb, Rest8[ω in Ω], δ[ω] >= z - R_a[ω])

    # ========== Função Objetivo ========== #

    @objective(NewsVendorProb, Max, (1-λ)*sum(R_a[ω]*p[ω] for ω in Ω) - λ*(CVaR));

    set_silent(NewsVendorProb)
    optimize!(NewsVendorProb);

    status      = termination_status(NewsVendorProb);

    Profit      = JuMP.objective_value(NewsVendorProb);
    xOpt        = JuMP.value.(x);
    yOpt        = JuMP.value.(y_1);
    zOpt        = JuMP.value.(y_2);

    println("==============================\n")
    println("Status: ", status);
    println("Lucro Jornaleiro: ", Profit);
    println("Quant. Jornais: ", xOpt);
    println("\n==============================")
end

function Q1i()
    u = 150;
    q = 60;
    r = 10;
    c = 20;
    γ = 0.1;
    α = 0.95;
    Λ = 0.0:0.01:1.0;

    solucoesOtimas  = []
    ExpValues       = []
    CVaRs           = []

    # ============================================================================ #

    # ========================     Sampling Process     ========================== #

    nCenarios = 10000;                   # Number of Scenarios
    Ω = 1:nCenarios;                    # Set of Scenarios
    p = ones(nCenarios)*(1/nCenarios);  # Equal Probability

    dmin = 50;
    dmax = 150;

    # ===================================
    #      =====> Using Julia <=====     
    # ===================================

    Random.seed!(1);
    d  = rand(Uniform(dmin, dmax), nCenarios);

    for λ in Λ
        NewsVendorProb = Model(HiGHS.Optimizer);

        # ========== Variáveis de Decisão ========== #

        @variable(NewsVendorProb, x >= 0);
        @variable(NewsVendorProb, y_1[Ω] >= 0);
        @variable(NewsVendorProb, y_2[Ω] >= 0);
        @variable(NewsVendorProb, R_a[Ω]);
        @variable(NewsVendorProb, CVaR);
        

        @variable(NewsVendorProb, z);
        @variable(NewsVendorProb, δ[Ω] >= 0);

        # ========== Restrições ========== #

        @constraint(NewsVendorProb, Rest1, x <= u);
        @constraint(NewsVendorProb, Rest2[ω in Ω], y_1[ω] <= d[ω]);
        @constraint(NewsVendorProb, Rest3[ω in Ω], y_1[ω] + y_2[ω] <= x);
        @constraint(NewsVendorProb, Rest4[ω in Ω], R_a[ω] == q*y_1[ω] + r*y_2[ω] - c*x);
        @constraint(NewsVendorProb, Rest6[ω in Ω], y_2[ω] <= γ*x)


        @constraint(NewsVendorProb, Rest7, -CVaR == z - sum(p[ω]*δ[ω] for ω in Ω)/(1 - α))
        @constraint(NewsVendorProb, Rest8[ω in Ω], δ[ω] >= z - R_a[ω])

        # ========== Função Objetivo ========== #

        @objective(NewsVendorProb, Max, (1-λ)*sum(R_a[ω]*p[ω] for ω in Ω) - λ*(CVaR));

        set_silent(NewsVendorProb)
        optimize!(NewsVendorProb);

        status      = termination_status(NewsVendorProb);

        Profit      = JuMP.objective_value(NewsVendorProb);
        xOpt        = JuMP.value.(x);
        y1Opt        = JuMP.value.(y_1);
        y2Opt        = JuMP.value.(y_2);
        δOpt        = JuMP.value.(δ);
        zOpt        = JuMP.value.(z);
        
        push!(solucoesOtimas,xOpt)
        push!(ExpValues,sum(q*y1Opt[ω] + r*y2Opt[ω] - c*xOpt for ω in Ω)/nCenarios)
        push!(CVaRs,zOpt - (sum(p[ω]*δOpt[ω] for ω in Ω)/(1 - α)))
        #println("==============================\n")
        #println("Status: ", status);
        #println("Lucro Jornaleiro: ", Profit);
        #println("Quant. Jornais: ", xOpt);
        #println("\n==============================")
    end

    # Plot 1: x* vs λ
    plot(Λ, solucoesOtimas,
        xlabel="λ", ylabel="x*",
        label="x* vs λ",
        title="Solução ótima x* em função de λ",
        legend=:topright)
    savefig("./Lista3/images/Q1i1.png")

    # Plot 2: Valor Esperado vs CVaR
    plot(CVaRs, ExpValues,
        xlabel="CVaR", ylabel="Valor Esperado",
        label="E[R₁^{(1)} + R₁^{(F)}]",
        title="Expected Value em função de CVaR",
        legend=:topright)
    savefig("./Lista3/images/Q1i2.png")
end

function main()
    #println("Questão 1, letra c)")
    #Q1c()
    #println("Questão 1, letra e)")
    #Q1e()
    #println("==============================\n")
    #println("Questão 1, letra f)")
    #Q1f()
    #println("==============================\n")
    #println("Questão 1, letra g)")
    #Q1g()
    #println("==============================\n")
    #println("Questão 1, letra h)")
    #Q1h()
    println("==============================\n")
    println("Questão 1, letra i)")
    Q1i()
end

main()