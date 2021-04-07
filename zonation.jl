using Revise
using COAST
using LinearAlgebra


function zonation_diffusion(Ea,D0,U238,U235,Th232,L,nrad,tT...)

    tTcopy = collect(tT)
    times = tTcopy[1:ceil(Int,length(tT)/2)] # type unstable but fastest so far
    T = tTcopy[ceil(Int,length(tT)/2)+1:end]
    U238_0 = U238*(exp(COAST.lambda_38*times[1])) # U238 is measured at present
    U235_0 = U235*(exp(COAST.lambda_35*times[1])) # U238 is measured at present
    Th232_0 = Th232*(exp(COAST.lambda_32*times[1])) # U238 is measured at present
    C = zeros(nrad+1,length(times)+1) # 1 -> rad+1
    du = zeros(Float64,nrad) 
    d = zeros(nrad+1) # 0 -> rad
    dl = zeros(nrad)
    UN1 = LinearAlgebra.Tridiagonal(du,d,dl)
    R = copy(d) # 0 -> rad
    delR = L/(nrad-1) 
    tpassed = 0.0
    for ind in eachindex(T)
        Ucur = U238_0*(exp(-COAST.lambda_38*tpassed))
        D = D0*exp(-Ea/(COAST.Rjoules*T[ind]))
        dt = times[ind]-times[ind+1]
        beta = 2*delR^2/(D*dt)
        UN1[1,1] = -1.0
        UN1[1,2] = 1.0
        R[1] = 0.0
        for j in 2:nrad
            UN1[j,j+1] = 1.0
            UN1[j,j-1] = 1.0
            UN1[j,j] = -2.0-beta
            R[j] = (2.0-beta)*C[j,ind] - C[j-1,ind] - C[j+1,ind] - Ucur*COAST.lambda_38*L*beta*dt
        end
        
        UN1[nrad+1,nrad+1] = 1.0
        
        R[nrad+1] = 0.0
        S = UN1\R
        C[:,ind+1] = S
        tpassed += dt
    end
    outval = U238./(C./L)
    return outval[1:end-1,end-1]
end

function misfit_zonation_diffusion(Ea,D0,U238,U235,Th232,L,nrad,pbtT...)
    tTcopy = collect(pbtT)
    U38Pb06test = tTcopy[1:nrad]
    tT = tTcopy[nrad+1:end]
    U38Pb06 = zonation_diffusion(Ea,D0,U238,U235,Th232,L,nrad,tT...)
    sq_sum_misfit = sum((U38Pb06test-U38Pb06)^2)
    return sq_sum_misfit
end


Ea = 250.0*1e3
D0 = 3.9*1e-10
nt = 10
t= collect(LinRange(1000.0e6*COAST.sec_in_yrs,0.1e6*COAST.sec_in_yrs,nt))
T= collect(LinRange(1000.0,700.0,nt-1))

tT = vcat(t,T)
L = 1e-4
diffn = zonation_diffusion(Ea,D0,40.0,0.0,0.0,L,30,tT...)


