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
   
    for ind in eachindex(T)
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
            R[j] = (2.0-beta)*C[j,ind] - C[j-1,ind] - C[j+1,ind] - U238_0*COAST.lambda_38*L*beta*dt
        end
        
        UN1[nrad+1,nrad+1] = 1.0
        
        R[nrad+1] = 0.0
        S = UN1\R
        C[:,ind+1] = S

    end

    return C
end


