using Random

# Função para salvar CSV com header
function salvar_csv(file_path, matrix, header::Vector{String})
    open(file_path, "w") do io
        println(io, join(header, ","))  # Escreve o header
        for i in 1:size(matrix, 1)
            println(io, join(matrix[i, :], ","))
        end
    end
end

function gerar_dados_shipment_csv(N::Int; dz=5, dy=12, dx=3, seed=42, path="./Projeto Final/data/")
    if !isdir(path)
        mkpath(path)
    end

    Random.seed!(seed)

    p1 = 1.0
    p2 = 10.0

    c = rand(1.0:0.1:5.0, dz, dy)
    X = rand(N, dx)
    A = randn(dy, dx)

    Y = zeros(N, dy)
    for i in 1:N
        ε = randn(dy) .* 5.0
        Y[i, :] = max.(A * X[i, :] .+ 50 .+ ε, 0.0)
    end

    # Criar headers automáticos
    header_X = ["X$j" for j in 1:dx]
    header_Y = ["Y$j" for j in 1:dy]
    header_C = ["Loc$j" for j in 1:dy]
    header_A = ["X$j" for j in 1:dx]

    # Salvar arquivos CSV com header
    salvar_csv(path * "X.csv", X, header_X)
    salvar_csv(path * "Y.csv", Y, header_Y)
    salvar_csv(path * "C.csv", c, header_C)
    salvar_csv(path * "A.csv", A, header_A)

    # Salvar parâmetros
    open(path * "params.txt", "w") do io
        write(io, "p1 = $p1\n")
        write(io, "p2 = $p2\n")
    end

    # Criar descrição
    open(path * "descricao.txt", "w") do io
        write(io, """
DESCRIÇÃO DOS DADOS GERADOS

Arquivos:
- X.csv: Variáveis auxiliares (tamanho: $(N) x $(dx))
  Colunas: $(join(header_X, ", "))

- Y.csv: Demandas nos pontos de consumo (tamanho: $(N) x $(dy))
  Colunas: $(join(header_Y, ", "))

- C.csv: Custos de transporte do depósito para os locais de demanda (tamanho: $(dz) x $(dy))
  Colunas: $(join(header_C, ", "))

- A.csv: Matriz de influência das variáveis auxiliares sobre a demanda (tamanho: $(dy) x $(dx))
  Colunas: $(join(header_A, ", "))

- params.txt: Contém os parâmetros p1 e p2:
    - p1: Custo de produção antecipada
    - p2: Custo de produção de última hora

Observação:
A demanda Y é gerada como uma combinação linear das variáveis X com ruído gaussiano, garantindo valores não negativos.

""")
    end

    println("Arquivos CSV e descrição gerados em: $path")

    return (p1=p1, p2=p2, c=c, X=X, Y=Y, dz=dz, dy=dy, dx=dx, A=A)
end


dados = gerar_dados_shipment_csv(100)