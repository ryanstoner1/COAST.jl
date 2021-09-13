# Make raw data able to be input to primary processing


"""
    function decompose_eu(eU::Float64,Th_U_ratio::Float64)

Calculate *U* and *Th* concentrations from effective uranium and *Th/U* ratio



"""
function decompose_eu(eU,Th_U_ratio)

U = eU./(1.0.+0.235*Th_U_ratio)
Th = eU./((1.0./Th_U_ratio).+0.235)

return U,Th
end

"""

find concentration in units appropriate for RDAAM

    ppm_to_atoms_per_volume(U238::Float64;density=3.2)

"""
## preprocess
function conc_to_atoms_per_volume(U,Th232;density=3.20,U38_35_ratio=137.88)

    U238_mol = U/(atomic_mass_U238+(1.0/U38_35_ratio)*atomic_mass_U235)
    U235_mol = U/(atomic_mass_U238*U38_35_ratio+atomic_mass_U235)

    #U235_mol = U235/atomic_mass_U235 # mol/g
    U235_atoms_per_g = U235_mol*Na # atoms/g
    U235_V = U235_atoms_per_g*density # atoms/cm^3

    #U238_mol = U238/atomic_mass_U238 # mol/g
    U238_atoms_per_g = U238_mol*Na # atoms/g
    U238_V = U238_atoms_per_g*density # atoms/cm^3

    Th232_mol = Th232/atomic_mass_Th232 # mol/g
    Th232_atoms_per_g = Th232_mol*Na # atoms/g
    Th232_V = Th232_atoms_per_g*density # atoms/cm^3

    return U238_V,U235_V,Th232_V,U238_mol,U235_mol,Th232_mol
end

function UTh_date_to_He_mols(U38,U35,Th,date_ma)

He_mols = 6*(Th*exp(lambda_32*1e6*sec_in_yrs*date_ma)-Th)+8*(U38*exp(lambda_38*1e6*sec_in_yrs*date_ma)-U38)+7*(U35*exp(lambda_35*1e6*sec_in_yrs*date_ma)-U35)
return He_mols
end
