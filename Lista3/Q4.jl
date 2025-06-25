using JuMP, HiGHS, Random, Distributions, CSV, DataFrames, Gurobi

function Q4c(d,p)
    # ======================== Dados do Problema ======================== #

    c1_exp = 50        
    c2_exp = 100       

    c1_var = 100       
    c2_var = 150       

    P1 = 5             
    P2 = 10            
    limite_exp2 = 30   

    # ======================== Cenários Amostrados ======================== #

    nCenarios = length(d);
    Ω = 1:nCenarios;

    dmin = 20;
    dmax = 40;

    Random.seed!(1);

    # ======================== Modelo de Otimização ======================== #

    ExpansionProb = Model(Gurobi.Optimizer);

    # ======== Variáveis de Primeiro Estágio (Expansão) ======== #
    @variable(ExpansionProb, x1 >= 0);                  
    @variable(ExpansionProb, 0 <= x2 <= limite_exp2);

    # ======== Variáveis de Segundo Estágio (Operação por cenário) ======== #
    @variable(ExpansionProb, g1[Ω] >= 0);   
    @variable(ExpansionProb, g2[Ω] >= 0);  

    # ======== Restrições por Cenário ======== #
    @constraint(ExpansionProb, Demand[ω in Ω], g1[ω] + g2[ω] == d[ω]);
    @constraint(ExpansionProb, Cap1[ω in Ω], g1[ω] <= P1 + x1);
    @constraint(ExpansionProb, Cap2[ω in Ω], g2[ω] <= P2 + x2);

    # ======== Função Objetivo: Custo Total Esperado ======== #
    @objective(ExpansionProb, Min,
        c1_exp * x1 + c2_exp * x2 + sum(p[ω] * (c1_var * g1[ω] + c2_var * g2[ω]) for ω in Ω)
    );

    set_silent(ExpansionProb);
    optimize!(ExpansionProb);

    # ======================== Resultados ======================== #
    status = termination_status(ExpansionProb)
    total_cost = objective_value(ExpansionProb)
    x1_opt = value(x1)
    x2_opt = value(x2)
    g1_opt = value.(g1)
    g2_opt = value.(g2)

    println("====================================")
    println("Status da Otimização: ", status)
    println("Custo Total Esperado: ", total_cost)
    println("Expansão ótima do gerador 1 (x1): ", x1_opt)
    println("Expansão ótima do gerador 2 (x2): ", x2_opt)
    println("====================================")
    return x1_opt, x2_opt
end

function Q4d(d, p)

    x1_opt, x2_opt = Q4c(d,p)
    # ======================== Dados do Problema ======================== #

    c1_exp = 50;     c2_exp = 100;      
    c1_var = 100;    c2_var = 150;      
    P1 = 5;          P2 = 10;           
    limite_exp2 = 30;

    # Barras (nós) e linhas (arestas)
    N = [1, 2, 3]                                   
    A = [(1,2), (1,3), (2,3)]                       
    F = Dict((1,2)=>5.0, (1,3)=>10.0, (2,3)=>35.0)

    # ======================== Cenários ======================== #

    Ω = 1:length(d);    

    # ======================== Modelo ======================== #

    model = Model(Gurobi.Optimizer)

    # ======== Variáveis de Primeiro Estágio ======== #

    # ======== Variáveis de Segundo Estágio ======== #
    @variable(model, g1[Ω] >= 0)                    
    @variable(model, g2[Ω] >= 0)                    
    @variable(model, f[Ω, A])                       

    # ======== Restrições ======== #
    for ω in Ω
        # Geração limitada pela expansão
        @constraint(model, g1[ω] <= P1 + x1_opt)
        @constraint(model, g2[ω] <= P2 + x2_opt)

        # Limite de fluxo por linha
        for (i,j) in A
            @constraint(model, -F[(i,j)] <= f[ω,(i,j)] <= F[(i,j)])
        end

        # Balanço de energia nas barras
        
        @constraint(model, g1[ω] - f[ω,(1,2)] - f[ω,(1,3)] == 0)

        
        @constraint(model, g2[ω] + f[ω,(1,2)] - f[ω,(2,3)] == 0)

        
        @constraint(model, f[ω,(1,3)] + f[ω,(2,3)] == d[ω])
    end

    # ======== Função Objetivo ======== #
    @objective(model, Min,
        c1_exp * x1_opt + c2_exp * x2_opt +
        sum(p[ω] * (c1_var * g1[ω] + c2_var * g2[ω]) for ω in Ω)
    )

    set_silent(model)
    optimize!(model)

    # ======== Resultados ======== #
    println("====================================")
    println("Status: ", termination_status(model))
end


function Q4f(d, p)

    # ======================== Dados do Problema ======================== #

    c1_exp = 50;     c2_exp = 100;      
    c1_var = 100;    c2_var = 150;      
    P1 = 5;          P2 = 10;           
    limite_exp2 = 30;

    # Barras (nós) e linhas (arestas)
    N = [1, 2, 3]                                   
    A = [(1,2), (1,3), (2,3)]                       
    F = Dict((1,2)=>5.0, (1,3)=>10.0, (2,3)=>35.0)   

    # ======================== Cenários ======================== #

    Ω = 1:length(d);    

    # ======================== Modelo ======================== #

    model = Model(Gurobi.Optimizer)

    # ======== Variáveis de Primeiro Estágio ======== #
    @variable(model, x1 >= 0)                       
    @variable(model, 0 <= x2 <= limite_exp2)        

    # ======== Variáveis de Segundo Estágio ======== #
    @variable(model, g1[Ω] >= 0)                    
    @variable(model, g2[Ω] >= 0)                    
    @variable(model, f[Ω, A])                       

    # ======== Restrições ======== #
    for ω in Ω
        # Geração limitada pela expansão
        @constraint(model, g1[ω] <= P1 + x1)
        @constraint(model, g2[ω] <= P2 + x2)

        # Limite de fluxo por linha
        for (i,j) in A
            @constraint(model, -F[(i,j)] <= f[ω,(i,j)] <= F[(i,j)])
        end

        # Balanço de energia nas barras
        # Barra 1: geração - saída = 0
        @constraint(model, g1[ω] - f[ω,(1,2)] - f[ω,(1,3)] == 0)

        # Barra 2: geração + entrada/saída
        @constraint(model, g2[ω] + f[ω,(1,2)] - f[ω,(2,3)] == 0)

        # Barra 3: consumo = entrada líquida
        @constraint(model, f[ω,(1,3)] + f[ω,(2,3)] == d[ω])
    end

    # ======== Função Objetivo ======== #
    @objective(model, Min,
        c1_exp * x1 + c2_exp * x2 +
        sum(p[ω] * (c1_var * g1[ω] + c2_var * g2[ω]) for ω in Ω)
    )

    set_silent(model)
    optimize!(model)

    # ======== Resultados ======== #
    println("====================================")
    println("Status: ", termination_status(model))
    println("Custo Total Esperado: ", objective_value(model))
    println("Expansão ótima do gerador 1 (x1): ", value(x1))
    println("Expansão ótima do gerador 2 (x2): ", value(x2))
    println("====================================")
end

function main()

    filePath = @__DIR__;

    # ============================     Data Read    ============================== #

    Pathread    = string(filePath, "\\data\\IN_d - Q6.csv");
    df          = DataFrame(CSV.File(Pathread));
    d           = df.d[:];

    # ============================================================================ #
    p = ones(length(d))*(1/length(d));
    println("==============================\n")
    println("Questão 4, letra c)")
    Q4c(d,p)
    println("==============================\n")
    println("Questão 4, letra d)")
    Q4d(d,p)
    println("==============================\n")
    println("Questão 4, letra f)")
    Q4f(d,p)

end
main()