

function zonation_diffusion(R,Ea,logD0_a2,U238,U235,Th232,L,rad,tT...)

    tTcopy = collect(tT)
    times = tTcopy[1:ceil(Int,length(tT)/2)] # type unstable but fastest so far
    T = tTcopy[ceil(Int,length(tT)/2)+1:end]

    U238_0 = U238*(exp(lambda_38*times[1])) # U238 is measured at present
    U235_0 = U235*(exp(lambda_35*times[1])) # U238 is measured at present
    Th232_0 = Th232*(exp(lambda_32*times[1])) # U238 is measured at present
    
    for ind in eachindex(times)
        for i in 1:rad

        end
        
    end

    return nothing
end