
using Revise
using COAST

n_iter = 100

# general params

U238 = 50.0*1e-6
Th232 = 0.0*1e-6

# damage params
c0=6.24534
c1=-0.11977
c2=-314.937
c3=-14.2868
alpha=-0.05721

# functional form, amorphous fraction, mean distance to track parameters
Ea=165.0 # kJ/mol
D0=193188 # cm2/s
D0N17=0.0034 # cm2/s
EaN17=71.0 # kJ/mol
R=COAST.Rjoules/1000 # kJ/mol
Ba=5.48e-19 #g amorphized per alpha event
interconnection=3 
SV=1.669 #nm^-1 track surface to volume ratio
lint_lattice=45920.0 #nm, extrapolated to a zircon with 1e14 alphas/g

# preprocess concentrations
(U238_V,U235_V,Th232_V,U238_mol,U235_mol,Th232_mol) = conc_to_atoms_per_volume(U238,Th232,density=3.2,U38_35_ratio=137.818)

L = 60e-6
n_T_pts = 221
T2 = collect(LinRange(140.0,40.0,floor(Int,n_T_pts)).+273.15)
T = collect(LinRange(40.0,140.0,ceil(Int,n_T_pts)).+273.15)
T = vcat(T2,T)
times = collect(LinRange(160.0,120.1,ceil(Int,n_T_pts)+1).*3.15576e7*1e6)
times2 = collect(LinRange(120.0,0.0,ceil(Int,n_T_pts)).*3.15576e7*1e6)
times = vcat(times,times2)

he_est = zrdaam_forward_diffusion(n_iter,c0,c1,c2,c3,alpha,Ba,interconnection,SV,lint_lattice,D0,Ea,R,D0N17,EaN17,U238_mol,U235_mol,Th232_mol,L,
  times...,T...)

pre_he = (8*(U238_mol*exp(66.0*1e6*sec_in_yrs/τ38)-U238_mol)+ # HeFTy output
  7*(U235_mol*exp(43.4*1e6*sec_in_yrs/τ35)-U235_mol)+ # HeFTy output
  6*(Th232_mol*exp(43.4*1e6*sec_in_yrs/τ32)-Th232_mol)) # HeFTy output

print("Zirc is: $he_est\n")
print("predicted is: $pre_he\n")



# apatite test
alpha = 0.04672
c0 = 0.39528
c1 = 0.01073
c2 = -65.12969
c3 =  -7.91715
rmr0 = 0.79
eta_q = 0.91
L_dist = 8.1*1e-4 # cm (!)

# general params
U238 = 50.0*1e-6
Th232 = 0.0*1e-6
R = 1.9872*1e-3
n_T_pts = 121
n_iter = 100.0

# preprocess concentrations
(U238_V,U235_V,Th232_V,U238_mol,U235_mol,Th232_mol) = conc_to_atoms_per_volume(U238,Th232,density=3.2,U38_35_ratio=137.818)

"""
check if RDAAM reproduces vanilla Durango
from Farley et al, 00
"""
L1 = 90*1e-4
logD0_a2 = log10(10^1.5/(L1^2)) # cm^2/s
Ea = 32.9

T = collect(LinRange(120.0,0.01,ceil(Int,n_T_pts)).+273.15)
times = collect(LinRange(120.0,0.01,ceil(Int,n_T_pts)+1).*3.1558e7*1e6)

"""
calculate erho
rdaam params in diffn
test fig 2, 2009 RDAAM
"""
Rjoules = 8.314
psi = 1e-13
omega = 1e-22
Etrap = 34*1e3 # J/mol
E_L = 122.3*1e3 # J/mol
L = 60*1e-4
L2 = 60*1e-4
log10D0L_a2_rdaam = log10(exp(9.733)*L^2/L2^2)
T = collect(LinRange(120.0,0.0,ceil(Int,n_T_pts)).+273.15)
times = collect(LinRange(120.0,0.0,ceil(Int,n_T_pts)+1).*3.1558e7*1e6)
mass_he_t2 = rdaam_forward_diffusion(alpha,c0,c1,c2,c3,0.79,eta_q,L_dist,psi,omega,Etrap,Rjoules,E_L,log10D0L_a2_rdaam,n_iter,
               U238_mol,U238_V,U235_mol,U235_V,Th232_mol,Th232_V,L,times...,T...)
pre_time2 = 55.2*1e6
pre_he_t2 = (8*(U238_mol*exp(pre_time2*sec_in_yrs/τ38)-U238_mol)+
             7*(U235_mol*exp(pre_time2*sec_in_yrs/τ35)-U235_mol)+
             6*(Th232_mol*exp(pre_time2*sec_in_yrs/τ32)-Th232_mol))
#print("Ap is: $mass_he_t2\n")
#print("$pre_he_t2\n")
