using COAST
using JuMP
using Test

@testset "COAST.jl" begin
    @test loaded_COAST()==true
end

@testset "he_forward.jl" begin
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
    U238 = 4*1e-6
    R = 1.9872*1e-3
    L = 60*1e-4 # m
    n_T_pts = 100
    n_iter = 60.0

    # preprocess concentrations
    (U238_V,U235_V,Th232_V,U238_mol,U235_mol,Th232_mol) = ppm_to_atoms_per_volume(U238,0.0,density=3.20)

    """
    check if RDAAM reproduces vanilla Durango
    from farley et al, 00
    """
    L1 = 90*1e-4
    logD0_a2 = log10(10^1.5/(L1^2)) # cm^2/s
    Ea = 32.9

    T = collect(LinRange(120.0,0.01,ceil(Int,n_T_pts)).+273.15)
    times = collect(LinRange(120.0,0.01,ceil(Int,n_T_pts)+1).*3.1558e7*1e6)
    mass_he_t1 = rdaam_forward_diffusion(alpha,c0,c1,c2,c3,rmr0,eta_q,L_dist,0.0,0.0,0.0,R,Ea,logD0_a2,n_iter,
                  U238_mol,U238_V,U235_mol,U235_V,Th232_mol,Th232_V,L,times...,T...)
    print("mass t1 is: $mass_he_t1 \n")
    pre_he_t1 = (8*(U238_mol*exp(60*1e6*sec_in_yrs/τ38)-U238_mol)+
                 7*(U235_mol*exp(60*1e6*sec_in_yrs/τ35)-U235_mol)) # Dodson value
    print("mass t1 predicted is: $pre_he_t1 \n")
    @test isapprox(mass_he_t1/pre_he_t1,1.0; rtol = 1e-2)

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
    L2 = 60*1e-4
    log10D0L_a2_rdaam = log10(exp(9.733)*L^2/L2^2)

    T = collect(LinRange(120.0,0.0,ceil(Int,n_T_pts)).+273.15)
    times = collect(LinRange(120.0,0.01,ceil(Int,n_T_pts)+1).*3.1558e7*1e6)
    mass_he_t2 = rdaam_forward_diffusion(alpha,c0,c1,c2,c3,0.79,eta_q,L_dist,psi,omega,Etrap,Rjoules,E_L,log10D0L_a2_rdaam,n_iter,
                   U238_mol,U238_V,U235_mol,U235_V,Th232_mol,Th232_V,L,times...,T...)
    pre_he_t2 = (8*(U238_mol*exp(43.6*1e6*sec_in_yrs/τ38)-U238_mol)+
                 7*(U235_mol*exp(43.6*1e6*sec_in_yrs/τ35)-U235_mol))# Dodson value
    # non-redistributed value
    @test isapprox(mass_he_t2/pre_he_t2,1.0; rtol = 1e-2)

    """
    wolf,98 fig. 5 - p3
    """
    T1 = collect(LinRange(60.0,60.0,ceil(Int,n_T_pts/2)).+273.15)
    T2 = collect(LinRange(15.0,15.0,floor(Int,n_T_pts/2)).+273.15)
    T = vcat(T1,T2)
    times1 = collect(LinRange(100.0,20.0,ceil(Int,n_T_pts/2)+1).*3.1558e7*1e6)
    times2 = collect(LinRange(19.9,0.01,floor(Int,n_T_pts/2)).*3.1558e7*1e6)
    times = vcat(times1,times2)
    mass_he_t3 = rdaam_forward_diffusion(alpha,c0,c1,c2,c3,0.83,eta_q,L_dist,
                                         0.0,0.0,0.0,R,Ea,logD0_a2,n_iter,
                                         U238_mol,U238_V,U235_mol,U235_V,
                                         Th232_mol,Th232_V,L,times...,T...)
    pre_he_t3 = (8*(U238_mol*exp(40*1e6*sec_in_yrs/τ38)-U238_mol)+
                 7*(U235_mol*exp(40*1e6*sec_in_yrs/τ35)-U235_mol))
    @test isapprox(mass_he_t3/pre_he_t3,1.0; atol = 2e-2) # <1 Ma error
end

@testset "he_vars_constraints.jl" begin
     # basic setup
     model1 = initialize_JuMP_model("mumps")
     @variable(model1, T)
     @test num_variables(model1)==1

     # add bounds
     model2 = initialize_JuMP_model("mumps")
     @variable(model2, 273.0<=T<=400.0)
     @test num_variables(model2)==1
     @test has_lower_bound(T)
     @test has_upper_bound(T)
     print("Basic JuMP tests passed!\n")
end

# basic model with custom constraints
@testset "custom constraints" begin
    # general params
    U238 = 4*1e-6
    R = 1.9872*1e-3
    L = 60*1e-4 # m
    n_T_pts = 100
    n_iter = 60.0
     model3 = initialize_JuMP_model("mumps",print_level=1)
     time_segs = 10
     (T,set_val) = define_variables!(time_segs-1,1,model3,0.1*ones(time_segs-1))
     @test num_variables(model3)==time_segs-1
     @test register_forward_model!(time_segs,model3)==true
     register_objective_function!(time_segs-1,model3)

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
     U238 = 28*1e-6
     R = 1.9872*1e-3
     L = 60*1e-4 # m
     times = collect(LinRange(120.0,0.01,time_segs).*3.1558e7*1e6)

     # preprocess concentrations
     (U238_V,U235_V,Th232_V,U238_mol,U235_mol,Th232_mol) = ppm_to_atoms_per_volume(U238,0.0,density=3.20)

     L1 = 90*1e-4
     logD0_a2 = log10(10^1.5/(L1^2)) # cm^2/s
     Ea = 32.9


     constr1=@NLconstraint(model3,[i = 1:1],rdaam_forward_diffusion(alpha,c0,c1,c2,c3,rmr0,eta_q,L_dist,0.0,0.0,0.0,R,Ea,logD0_a2,n_iter,
                   U238_mol,U238_V,U235_mol,U235_V,Th232_mol,Th232_V,L,times...,T...)==3e-9)
     @NLobjective(model3,Min,mod_constraints(T...))
     optimize!(model3)
     @test termination_status(model3) == MOI.LOCALLY_SOLVED
end

@testset "one specified constraint" begin
    model4 = initialize_JuMP_model("mumps",print_level=1)
    time_segs = 10
    (T,set_dev) = define_variables!(time_segs-1,1,model4,0.1*ones(time_segs-1))
    register_objective_function!(time_segs-1,model4)
    register_forward_model!(time_segs,model4)
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
    U238 = 28*1e-6
    R = 1.9872*1e-3
    L = 60*1e-4 # m
    times = collect(LinRange(120.0,0.01,time_segs).*3.1558e7*1e6)

    # preprocess concentrations
    (U238_V,U235_V,Th232_V,U238_mol,U235_mol,Th232_mol) = ppm_to_atoms_per_volume(U238,0.0,density=3.20)


    L1 = 90*1e-4
    logD0_a2 = log10(10^1.5/(L1^2)) # cm^2/s
    Ea = 32.9
    density = 3.2
    He_conc = [3e-9]
    rdaam_define_constraints(model4,density,set_dev,He_conc,L,times,T,U238_mol,U235_mol,Th232_mol,U238_V,U235_V,Th232_V)
    optimize!(model4)
    @test termination_status(model4) == MOI.LOCALLY_SOLVED
end

@testset "FT_helper_funcs" begin
     # Ketcham 07, 5_5M, Dpar case
    (l0m_K07_5_5Dpar,l0cm_K07_5_5Dpar)= init_track_len(calc_type="Dpar",
                                                Dpar=1.65,Ketcham07_5_5m=true)
    @test isapprox(l0m_K07_5_5Dpar,16.1,rtol=1e-3)
    @test isapprox(l0cm_K07_5_5Dpar,16.3,rtol=1e-3)

    (l0m_K07_5_5rmr0,l0cm_K07_5_5rmr0)= init_track_len(calc_type="rmr0",
                                                rmr0=1.65,Ketcham07_5_5m=true)
    @test isapprox(l0m_K07_5_5rmr0,16.14,rtol=1e-3)
    @test isapprox(l0cm_K07_5_5rmr0,16.35,rtol=1e-3)

    (l0m_K07_5_5cl_a,l0cm_K07_5_5cl_a)= init_track_len(calc_type="Cl_apfu",
                                                Cl=1.65,Ketcham07_5_5m=true)
    @test isapprox(l0m_K07_5_5cl_a,17.80,rtol=1e-3)
    @test isapprox(l0cm_K07_5_5cl_a,18.33,rtol=1e-3)

    (l0m_K07_5_5a_vol,l0cm_K07_5_5a_vol)= init_track_len(calc_type="a_len",
                                                a_vol=10.65,Ketcham07_5_5m=true)
    @test isapprox(l0m_K07_5_5a_vol,23.18,rtol=1e-3)
    @test isapprox(l0cm_K07_5_5a_vol,24.53,rtol=1e-3)

    # Donelick99 case
   (l0m_D99Dpar,l0cm_D99Dpar)= init_track_len(calc_type="Dpar",
                                               Dpar=1.65,Ketcham07_5_5m=false,
                                               Donelick99=true)
   @test isapprox(l0m_D99Dpar,16.1,rtol=1e-3)
   @test isapprox(l0cm_D99Dpar,16.3,rtol=1e-3)

   (l0m_D99rmr0,l0cm_D99rmr0)= init_track_len(calc_type="rmr0",
                                               rmr0=1.65,Donelick99=true)
   @test isapprox(l0m_D99rmr0,16.14,rtol=1e-3)
   @test isapprox(l0cm_D99rmr0,16.35,rtol=1e-3)

   (l0m_D99cl_a,l0cm_D99cl_a)= init_track_len(calc_type="Cl_apfu",
                                               Cl=1.65,Donelick99=true)
   @test isapprox(l0m_D99cl_a,17.80,rtol=1e-3)
   @test isapprox(l0cm_D99cl_a,18.33,rtol=1e-3)

   # Ketcham 07, 5_0M, Dpar case
  (l0m_K07_5_0Dpar,l0cm_K07_5_0Dpar)= init_track_len(calc_type="Dpar",
                                              Dpar=1.65,Ketcham07_5_5m=false,
                                              Ketcham07_5_0m=true)
  @test isapprox(l0m_K07_5_0Dpar,15.82,rtol=1e-3)
  @test isapprox(l0cm_K07_5_0Dpar,16.06,rtol=1e-3)

  (l0m_K07_5_0rmr0,l0cm_K07_5_0rmr0)= init_track_len(calc_type="rmr0",
                                              rmr0=1.65,Ketcham07_5_0m=true)
  @test isapprox(l0m_K07_5_0rmr0,15.94,rtol=1e-3)
  @test isapprox(l0cm_K07_5_0rmr0,16.19,rtol=1e-3)

  (l0m_K07_5_0cl_a,l0cm_K07_5_0cl_a)= init_track_len(calc_type="Cl_apfu",
                                              Cl=1.65,Ketcham07_5_0m=true)
  @test isapprox(l0m_K07_5_0cl_a,16.82,rtol=1e-3)
  @test isapprox(l0cm_K07_5_0cl_a,17.18,rtol=1e-3)

  (l0m_K07_5_0a_vol,l0cm_K07_5_0a_vol)= init_track_len(calc_type="a_len",
                                              a_vol=10.65,Ketcham07_5_0m=true)
  @test isapprox(l0m_K07_5_0a_vol,24.85,rtol=1e-3)
  @test isapprox(l0cm_K07_5_0a_vol,25.22,rtol=1e-3)

  # test custom functionality
  (l0m_cust,l0cm_cust)= init_track_len(custom=true,custom_param=1.65,
  custom_intercept=3.0,custom_slope=0.5,custom_c_intercept=2.0,
                                       custom_c_slope=1.0)
   @test isapprox(l0m_cust,(1.65*0.5+3.0),rtol=1e-3)
   @test isapprox(l0cm_cust,(1.65*1.0+2.0),rtol=1e-3)
end
