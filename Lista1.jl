using JuMP

Q_0 = 100
c_0 = 1.00
I   = 15.00
T_c = 3
Q_bar = 200
r = 0.05
π_0 = 3
T_u = 40

function c(Q)
    return 0.01*Q*Q
end
function valorPresente(Q)
    VP = sum((π_0 * Q_bar - I * Q - c_0 * Q_bar)/(1+r)^t for t=1:T_c) + sum((π_0 * Q_bar + π * Q - c(Q) - c_0 * Q_bar)/(1+r)^t for t=4:(T_c+T_u))
    return VP
end

println(valorPresente(200))
