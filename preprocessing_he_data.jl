# Make raw data able to be input to primary processing

"""
    function decompose_eu(eU::Float64,Th_U_ratio::Float64)

Calculate *U* and *Th* concentrations from effective uranium and *Th/U* ratio



"""
function decompose_eu(eU::Float64,Th_U_ratio::Float64)

U = eU./(1.0.+0.24*Th_U_ratio)
Th = eU./((1.0./Th_U_ratio).+0.24)

return U,Th
end
