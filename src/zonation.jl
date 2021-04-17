using Revise
using LinearAlgebra


function zonation_diffusion(Ea,R,D0,U238,U235,Th232,L,nrad,tT...;r=nothing)
    delr = L/(nrad-1)
    if isnothing(r)
        r = collect(0.0:delr:L)
    end
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
    RHS = copy(d) # 0 -> rad
    tpassed = 0.0

    for ind in eachindex(T)        
        
        U238cur = U238_0*(exp(-COAST.lambda_38*tpassed))
        U235cur = U235_0*(exp(-COAST.lambda_35*tpassed))
        dt = times[ind]-times[ind+1]
        D = D0*exp(-Ea/(COAST.Rjoules*T[ind]))    
        UN1[1,1] = 1.0
        UN1[1,2] = 1.0
        RHS[1] = 0.0
        for j in 2:nrad
            beta = 2*(r[j]-r[j-1])^2/(D*dt)
            UN1[j,j+1] = 1.0
            UN1[j,j-1] = 1.0
            UN1[j,j] = -2.0-beta
            RHS[j] = (2.0-beta)*C[j,ind] - C[j-1,ind] - C[j+1,ind] - U238cur*COAST.lambda_38*L*beta*dt - U235cur*COAST.lambda_35*L*beta*dt
        end
        # beta = 2*(r[end]-r[end-1])^2/(D*dt)
        # UN1[nrad+1,nrad+1] = -2.0-beta
        UN1[nrad+1,nrad+1] = 1.0
        RHS[nrad+1] = C[end,ind]#(2.0-beta)*C[end,ind] - C[end-1,ind] - U238cur*COAST.lambda_38*L*beta*dt - U235cur*COAST.lambda_35*L*beta*dt
        S = UN1\RHS
        C[:,ind+1] = S
        tpassed += dt
    end
    outval = U238./(C./L)
    return (outval[1:end-1,end-1],r)
end

function misfit_zonation_diffusion(Ea,D0,U238,U235,Th232,L,nrad,pbtT...)
    tTcopy = collect(pbtT)
    U38Pb06test = tTcopy[1:nrad]
    tT = tTcopy[nrad+1:end]
    U38Pb06 = zonation_diffusion(Ea,D0,U238,U235,Th232,L,nrad,tT...)
    sq_sum_misfit = sum((U38Pb06test-U38Pb06)^2)
    return sq_sum_misfit
end



# tT = vcat(t,T)
# L = 1e-4
# diffn = zonation_diffusion(Ea,D0,40.0,0.0,0.0,L,30,tT...)


