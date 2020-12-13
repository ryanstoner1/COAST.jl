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

"""

find concentration in units appropriate for RDAAM

    ppm_to_atoms_per_volume(U238::Float64;density=3.2)

"""
function ppm_to_atoms_per_volume(U238,Th232;density=3.20)
    U238_mol = U238/atomic_mass_U238 # mol/g
    U238_atoms_per_g = U238_mol*Na # atoms/g
    U238_V = U238_atoms_per_g*density # atoms/m^3

    Th232_mol = Th232/atomic_mass_Th232 # mol/g
    Th232_atoms_per_g = Th232_mol*Na # atoms/g
    Th232_V = Th232_atoms_per_g*density # atoms/m^3

    return U238_V,Th232_V
end
