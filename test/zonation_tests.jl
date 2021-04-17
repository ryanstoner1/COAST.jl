
using Revise
using Pkg
Pkg.activate(pwd())
using COAST
using CSV
using DataFrames
using Test

@testset "COAST.jl" begin
    @test loaded_COAST()==true
end

@testset "zonation.jl" begin
    Lmax = 77.0*1e-6
    subdir = "/test"
    filename = "/smyedata.csv"
    raw_data = CSV.read(pwd()*subdir*filename,DataFrame,header=false) 
    data = Matrix(raw_data)
    data[:,1] = data[:,1]/1e6
    r_max_approx = Lmax
    dr = diff(data[1:2,1])[1]
    r_added_min = maximum(data[:,1]) + dr
    r_added = collect(r_added_min:dr:(r_max_approx+dr)) # round up
    n_added = length(r_added)
    Pb06U38_grain_center = fill(data[end,2],n_added)
    sigPb06U38_grain_center = fill(data[end,3],n_added)
    data_grain_center = hcat(r_added,Pb06U38_grain_center,sigPb06U38_grain_center)
    data = vcat(data,data_grain_center)
    Ea = 250.0*1e3 # J/mol => 59.75 kcal/mol
    D0 = 3.9*1e-10 # m^2/s => 3.9e-6 cm^2/s
    nt = 1000
    L = 1e-4
    nrad = 513
    U38 = 1.0
    t_pt1 = 30
    t1 = collect(LinRange(70.0,50.0,ceil(Int,nt/2)+1).*3.1558e7*1e6)
    t2 = collect(LinRange(49.9,0.01,floor(Int,nt/2)).*3.1558e7*1e6)
    t = vcat(t1,t2)
    
    T1 = collect(LinRange(900.0,600.0,ceil(Int,nt/2)).+273.15)
    T2 = collect(LinRange(600.0,400.0,floor(Int,nt/2)).+273.15)
    T = vcat(T1,T2)
    #T = collect(LinRange(900.0,600.0,nt-1))
    (U38Pb06forw,r) = zonation_diffusion(Ea,COAST.Rjoules,D0,U38,0.0,0.0,L,nrad,t...,T...)
    @time zonation_diffusion(Ea,COAST.Rjoules,D0,U38,0.0,0.0,L,nrad,t...,T...);
    Pb06forw = 1.0./U38Pb06forw
    Pbtot = 0.0
    for i in 2:nrad
        Pbtot += pi*(r[i]^3-r[i-1]^3)*Pb06forw[i]
    end
    Pbtot = Pbtot/(pi*L^3)
    pre_he_t3 = (1.0*(U38*exp(51.2*1e6*COAST.sec_in_yrs/COAST.τ38)-U38))
    #print(U38Pb06forw)
    print("Cherniak zonation rutile numerical: $(Pbtot) \n")
    print("Cherniak zonation rutile analytical: $(pre_he_t3) \n")
    @test isapprox(Pbtot,pre_he_t3,rtol=1e-2)

    ## input
    # rdaam params
    # eqs, fanning curvilinear, ketcham et al 07
    alpha = 0.04672
    c0 = 0.39528
    c1 = 0.01073
    c2 = -65.12969
    c3 =  -7.91715
    rmr0 = 0.79
    eta_q = 0.91
    L_dist = 8.1*1e-4 # cm (!)
    # general params
    U238 = 1.0*1e-6
    R = 1.9872*1e-3
    L = 1.0*1e-4 # m
    n_T_pts = 1000
    n_iter = 300.0
    Ea = 59.752
    logD0_a2 = log10(3.9e-10/(L^2))
    
    # preprocess concentrations
    (U238_V,U235_V,Th232_V,U238_mol,U235_mol,Th232_mol) = ppm_to_atoms_per_volume(U238,0.0,density=3.20)
    
    T1 = collect(LinRange(900.0,600.0,ceil(Int,n_T_pts/2)).+273.15)
    T2 = collect(LinRange(600.0,400.0,floor(Int,n_T_pts/2)).+273.15)
    #print("$(U235_mol) \n")
    T = vcat(T1,T2)
    times1 = collect(LinRange(70.0,50.0,ceil(Int,n_T_pts/2)+1).*3.1558e7*1e6)
    times2 = collect(LinRange(49.9,0.01,floor(Int,n_T_pts/2)).*3.1558e7*1e6)
    times = vcat(times1,times2)
    mass_he_t3 = rdaam_forward_diffusion(alpha,c0,c1,c2,c3,0.83,eta_q,L_dist,
                                         0.0,0.0,0.0,R,Ea,logD0_a2,n_iter,
                                         U238_mol,U238_V,U235_mol,U235_V,
                                         Th232_mol,Th232_V,L,times...,T...)
    pre_he_t3 = (8*(U238_mol*exp(50.7*1e6*sec_in_yrs/τ38)-U238_mol)+ # HeFTy output
                 7*(U235_mol*exp(50.7*1e6*sec_in_yrs/τ35)-U235_mol)) # HeFTy output
    # 50.8 - usual output
    print("Cherniak rutile test numerical is $(mass_he_t3)! \n")
    print("Cherniak rutile test predicted HeFTy is $(pre_he_t3)! \n")
    @test isapprox(mass_he_t3/pre_he_t3,1.0; atol = 1e-2) # <1 Ma error vs

    # Zonation testing
    Nt = 301
    t_end = 1.0
    dt = t_end/(Nt-1)
    t1 = collect(LinRange(70.0,50.0,ceil(Int,Nt/2)+1).*3.1558e7*1e6)
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
    Pb06forw = zonation(Ea,COAST.Rjoules,D0,U238,0.0,0.0,L,Nx,t...,T...)
    Pbtot = [0.0]
    r = LinRange(0.0,L,Nx)
    for i in 2:Nx
        Pbtot[1] += pi*(r[i]^3-r[i-1]^3)*(Pb06forw[i]+Pb06forw[i-1])/2
    end
    Pbtot = Pbtot[1]/(pi*L^3)
    print("FD: total lead predicted is $(Pbtot)\n")
    Pb_heft = (1.0*(U238*exp(50.7*1e6*COAST.sec_in_yrs/COAST.τ38)-U238))
    print("HeFTy: total lead predicted is $(Pb_heft)\n")
    @test isapprox(Pbtot/Pb_heft,1.0; atol = 1e-2) # <1 Ma error vs
end




# 