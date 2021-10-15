# Solves diffusion equation for zoned crystal using Crank-Nicolson scheme

using LinearAlgebra

Nt = 100
t_end = 1.0
dt = t_end/(Nt-1)
t1 = collect(LinRange(70.0,50.0,ceil(Int,Nt/2)).*3.1558e7*1e6)
t2 = collect(LinRange(49.9,0.01,floor(Int,Nt/2)).*3.1558e7*1e6)
t = vcat(t1,t2)

T1 = collect(LinRange(900.0,600.0,ceil(Int,Nt/2)).+273.15)
T2 = collect(LinRange(600.0,400.0,floor(Int,Nt/2)).+273.15)
T = vcat(T1,T2)
Ea = 250.0*1e3
D0 = 3.9*1e-10
#Rjoules = 8.314
L = 1e-4
Nx = 513
U238 = 1.0
# Nt,t_end
function zonation_forward(Ea,R,D0,U235,Th232,L,Nt,Nx,tTrU...)

tTcopy = collect(tTrU)
t = tTcopy[1:Nt]#[1:ceil(Int,length(tT)/2)] # type unstable but fastest so far
T = tTcopy[(Nt+1):(2*Nt)]#[ceil(Int,length(tT)/2)+1:end]
r = tTcopy[(2*Nt+1):(2*Nt+Nx)]
U238 = tTcopy[(2*Nt+Nx+1):end]
U238_0 = U238*(exp(COAST.lambda_38*t[1])) # U238 is measured at present
U235_0 = U235*(exp(COAST.lambda_35*t[1])) # U238 is measured at present
Th232_0 = Th232*(exp(COAST.lambda_32*t[1])) # U238 is measured at present
D_diffn = [0.0]

Pb = 0.0*ones(Nx)
Pb_solns = zeros(Nx,Nt) # includes time t0
Pb_solns[:,1] = Pb
Pb_rad = 0.0

rhs = zeros(Nx)
U238_cur = U238_0
for i in 1:Nt-1

    dt = t[i] - t[i+1]
    U238_cur = U238_0*(exp(-COAST.lambda_38*(t[1]-t[i]+dt/2))) # Crank-Nicolson is staggered in time, hence dt/2
    D_diffn[1] = D0*exp(-Ea/(R*T[i]))
    A = D_diffn[1]*dt/(dr^2)
    B = D_diffn[1]*dt/(2*dr)
    lhs_center = [1.0 + 3*A; fill(1.0 + A, Nx-2);1.0]
    lhs_lo = [-(A/2).+ B./r[2:Nx-1];0.0]
    lhs_hi = [-3*A; -A/2 .- B./r[2:Nx-1]]
    lhs = LinearAlgebra.Tridiagonal(lhs_lo,lhs_center,lhs_hi)    
    rhs[1] = (1.0-3*A)*Pb[1] + 3*A*Pb[2] + U238_cur[1]*COAST.lambda_38*dt
    for j in 2:(Nx-1)
        rhs[j] = (A/2 - B/r[j])*Pb[j-1] + (1.0 - A)*Pb[j] + (A/2 + B/r[j])*Pb[j+1] + U238_cur[j]*COAST.lambda_38*dt
    end
    rhs[end] = Pb_rad
    
    Pb[:] = lhs\rhs
    Pb_solns[:,i+1] = Pb
    
end

return Pb_solns[:,end]
end
