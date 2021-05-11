
#= R. Stoner

 tests zonation scripts; one unzoned case without rad. damage
 run this file from COAST directory
 when debugging make sure you start julia in COAST directory as well

=#

using Revise
import Pkg
Pkg.activate(pwd())
using COAST
using COAST.Zoned
using CSV
using DataFrames
using Test
using JuMP
using Ipopt
using Interpolations
using Plots
# check if COAST was loaded 
@testset "COAST.jl" begin
    @test loaded_COAST()==true
end

@testset "zonation.jl" begin
    #= 
     
     Unzoned U-Pb rutile from Cherniak, 00
     no radiation damage

    =#
    # TODO: remove superfluous rad. damage params
    # A-Th/He rad. damage params; these aren't used here
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
    
    # set up time-temperature (t-T) path
    T1 = collect(LinRange(900.0,600.0,ceil(Int,n_T_pts/2)).+273.15)
    T2 = collect(LinRange(600.0,400.0,floor(Int,n_T_pts/2)).+273.15)
    T = vcat(T1,T2)
    times1 = collect(LinRange(70.0,50.0,ceil(Int,n_T_pts/2)+1).*3.1558e7*1e6)
    times2 = collect(LinRange(49.9,0.01,floor(Int,n_T_pts/2)).*3.1558e7*1e6)
    times = vcat(times1,times2)

    mass_pb_t1 = rdaam_forward_diffusion(alpha,c0,c1,c2,c3,0.83,eta_q,L_dist,
                                         0.0,0.0,0.0,R,Ea,logD0_a2,n_iter,
                                         U238_mol,U238_V,U235_mol,U235_V,
                                         Th232_mol,Th232_V,L,times...,T...)
    pre_pb_t1 = (8*(U238_mol*exp(50.7*1e6*sec_in_yrs/τ38)-U238_mol)+ # HeFTy output
                 7*(U235_mol*exp(50.7*1e6*sec_in_yrs/τ35)-U235_mol)) 
    # 50.8 - analytical output
    print("Unzoned Cherniak rutile numerical test numerical is $(mass_pb_t1)! \n")
    print("Unzoned Cherniak rutile test predicted HeFTy is $(pre_pb_t1)! \n")
    @test isapprox(mass_pb_t1/pre_pb_t1,1.0; atol = 1e-2) # <1 Ma error
    # end unzoned test

    #= 

     can test zonation function can handle array of U values?
     U-Pb rutile (Cherniak,00)
     
    =#
    # time stepping setup
    Nt = 39 
    t_end = 1.0
    dt = t_end/(Nt-1)

    # set up time-temperature (t-T) path
    t1 = collect(LinRange(70.0,50.0,ceil(Int,Nt/2)).*3.1558e7*1e6)
    t2 = collect(LinRange(49.9,0.01,floor(Int,Nt/2)).*3.1558e7*1e6)
    t = vcat(t1,t2)
    T1 = collect(LinRange(900.0,600.0,ceil(Int,Nt/2)).+273.15)
    T2 = collect(LinRange(600.0,400.0,floor(Int,Nt/2)).+273.15)
    T = vcat(T1,T2)
    Ea = 250.0*1e3
    D0 = 3.9*1e-10
    L = 1e-4
    Nx = 30
    r = LinRange(0.0,L,Nx)
    U238 = 1.0
    U238_new = U238*ones(Nx)
    Nt = length(t)

    # test function uses splatting; JuMP doesn't like arrays    
    Pb06forw = zonation_forward(Ea,COAST.Rjoules,D0,0.0,0.0,L,Nt,Nx,t...,T...,r...,U238_new...)
    Pbtot = [0.0]
    r = LinRange(0.0,L,Nx)

    # integrate/convert profile to total Pb concentration
    # check date w. HeFTy date
    for i in 2:Nx
        Pbtot[1] += pi*(r[i]^3-r[i-1]^3)*(Pb06forw[i]+Pb06forw[i-1])/2
    end
    Pbtot = Pbtot[1]/(pi*L^3)
    print("FD: total lead predicted is $(Pbtot)\n")
    Pb_heft = (1.0*(U238*exp(50.7*1e6*COAST.sec_in_yrs/COAST.τ38)-U238))
    print("HeFTy: total lead predicted is $(Pb_heft)\n")
    @test isapprox(Pbtot/Pb_heft,1.0; atol = 5e-2) # higher Nx and Nt lead to better match

    #=
     
     synthetic test of constrained optimizer (IPOPT) used by COAST
     U-Pb rutile (Cherniak,00)
     array of U values but unzoned; cooling path
     same as previous test

    =#

    # set up t-T path
    Nt = 39
    t_end = 1.0
    dt = t_end/(Nt-1)
    T1 = collect(LinRange(900.0,600.0,ceil(Int,Nt/2)).+273.15)
    T2 = collect(LinRange(600.0,400.0,floor(Int,Nt/2)).+273.15)
    T = vcat(T1,T2)
    t1 = collect(LinRange(70.0,50.0,ceil(Int,Nt/2)).*3.1558e7*1e6)
    t2 = collect(LinRange(49.9,0.01,floor(Int,Nt/2)).*3.1558e7*1e6)
    t = vcat(t1,t2)

    # Cherniak, 00 diffusion params
    # setup U and grain size
    Ea = 250.0*1e3
    D0 = 3.9*1e-10
    L = 1e-4
    Nx = 30
    r = LinRange(0.0,L,Nx)
    U238 = 1.0
    U238 = U238*ones(Nx)

    # create functions to be passed to IPOPT
    # IPOPT-friendly funcs
    jac_constraint = create_jac_constraint(Ea,COAST.Rjoules,D0,0.0,0.0,Nt,Nx,t,r,U238)
    constraint_zon = create_constraint_zon(Ea,COAST.Rjoules,D0,U238,0.0,0.0,Nt,Nx,t,r)

    # bounds temperature
    T_L = zeros(Float64,Nt)
    T_U = 2900*ones(Float64,Nt) # T_U has to be defined, set bound arbitrarily high

    # synthetic Pb values
    initPb = [0.008857378583018752, 0.008856812929792447, 0.00885511177504213, 0.008852259612534526, 0.008848230516985477, 0.008842987011603362, 0.008836478776030107, 0.008828640808589248, 0.008819390873808581, 0.008808625978040217, 0.00879621748087797, 0.008782004239101911, 0.008765782846776095, 0.008747293506359331, 0.008726199226256422, 0.008702054713998092, 0.008674259257549808, 0.008641984671522813, 0.008604064447778814, 0.008558822633270739, 0.008503808762407928, 0.008435383783207719, 0.008348058711971884, 0.008233386603361441, 0.008077941780303029, 0.007859134069521883, 0.007534875513179412, 0.007010548962254766, 0.005967321901702219, 0.0]

    # bounds Pb (i.e. constraint bounds)
    Pb_L = initPb - 0.02*initPb
    Pb_U = initPb + 0.02*initPb 

    prob = createProblem(
        Nt, # should match length T_L, T_U otherwise julia may crash
        T_L, # lower bound on temperature
        T_U, # upper bound
        Nx,
        Pb_L, # lower bound of Pb concentration; i.e. constraints 
        Pb_U,
        Nt*Nx, # number elements in constraint jacobian
        Nt*Nx,
        smooth_zon_objective, # objective function; sum smoothness (multiobjective not yet possible)
        constraint_zon,
        grad_smooth_zon_objective,
        jac_constraint,
    )
    addOption(prob, "hessian_approximation", "limited-memory") # hessian rarely (if ever) called; approximation is ok
    addOption(prob, "tol", 300.0) # smoothness not as much of an issue here
    addOption(prob,"print_level",3)
    prob.x = 1.1*T
    status=solveProblem(prob) # this can crash julia if prob set up incorrectly (see above)
    solve_successful = :Solve_Succeeded
    @test Ipopt.ApplicationReturnStatus[status]==solve_successful

    # test if previous test results match these
    Pbs = zeros(Nx) # preallocate
    constraint_zon(T,Pbs)

    @test minimum(isapprox.(Pbs[1:end-1]./Pb06forw[1:end-1],1.0;atol=1e-10))
    print("Test diffusion func matches main diffusion func! \n")

    #=

    Test with Smye, 2018 rutile dataset

    =#
    # Cherniak, 00 diffusion params
    # setup U and grain size

    # define constant params
    Ea = 250.0*1e3 # J/mol => 59.75 kcal/mol
    D0 = 3.9*1e-10 # m^2/s => 3.9e-6 cm^2/s
    U238 = 1.0
    Nt = 50

    # load data and preprocess
    ngrains = 1
    subdir = "/test"
    filename = "/smyedata.csv"
    raw_data = CSV.read(pwd()*subdir*filename,DataFrame,header=false) 
    data = Matrix(raw_data)
    ngrains = size(data,2)÷3
    # separate data by grain
    data = [data[:,3*igrain-2:(3*igrain)] for igrain in 1:ngrains]
    data = Dict((1:ngrains).=>data)
    #data[1] = data[1][1:11,:] # smye cut out data deeper in grain (plateau?)
    # convert from um->m
    for val in values(data)    
        val[:,1]/=1e6
    end

    # fill in data to center of grain
    rad = 73.0*1e-6 # maximum grain size
    Nx = zeros(Int64,ngrains) # preallocate for number of nodes in grain
    for (key, value) in data      
        dr = diff(value[1:2,1])[1]
        r_added_min = maximum(value[:,1])
        r_added = collect(r_added_min:dr:(rad+dr))
        n_added = length(r_added)
        # fill in all other values as well
        Pb06U38_grain_center=fill(value[end,2],n_added)
        sigPb06U38_grain_center=fill(value[end,3],n_added)
        data_grain_center = hcat(r_added,Pb06U38_grain_center,sigPb06U38_grain_center)
        data[key] = vcat(value,data_grain_center)
        data[key] = vcat([0.0 0.0 0.0],data[key])
        Nx[key] = size(data[key],1) 
    end

    # correct model to model end date
    end_model_Ma = 800.0
    Pb_corr_end_model = 1.0*(exp(COAST.lambda_38*COAST.sec_in_yrs*end_model_Ma*1e6))-1.0
    
    # pull out individual components from data for clarity
    U238_new = Dict{Int64,Vector{Float64}}()
    r = Dict{Int64,Vector{Float64}}()
    Pbmeas = Dict{Int64,Vector{Float64}}()
    sigmeas = Dict{Int64,Vector{Float64}}()
    for (key,value) in data
        value[2:end,2] = value[2:end,2].-Pb_corr_end_model
        push!(r,key=>value[:,1])
        push!(U238_new,key=>U238*ones(length(value[:,1]))) 
        push!(Pbmeas,key=>reverse(value[:,2]))
        push!(sigmeas,key=>reverse(value[:,3])) 
    end


     
    t1 = collect(LinRange(1100.0,1000.0,ceil(Int,Nt/2)).*3.1558e7*1e6)
    dt = -maximum(diff(t1))/(3.1558e7*1e6)
    t2 = collect(LinRange(1000.0-dt,end_model_Ma,floor(Int,Nt/2)).*3.1558e7*1e6)
    t = vcat(t1,t2)    
    T1 = collect(LinRange(830.0,870.0,ceil(Int,Nt/2)).+273.15)
    T2 = collect(LinRange(870.0,400.0,floor(Int,Nt/2)).+273.15)
    T = vcat(T1,T2)
    
    upper_bound_arr = 1100.0*ones(Nt)    
    lower_bound_arr = 673.0*ones(Nt)
    lower_bound_arr[1] = 1100.0
#     lower_bound_arr[1]=1100.0
#     upper_bound_constr = reverse(data[:,2]+3*data[:,3])
#     lower_bound_constr = reverse(data[:,2]-3*data[:,3])
#     reassign_ind = 10
#     upper_bound_constr[end-reassign_ind+1:end] = reverse(data[1:reassign_ind,2]+2.0*data[1:reassign_ind,3])
#     lower_bound_constr[end-reassign_ind+1:end] = reverse(data[1:reassign_ind,2]-2.0*data[1:reassign_ind,3])
#     lower_bound_constr[lower_bound_constr.<0.0] .= 0.0

#     datasig=vcat(2*data[1:reassign_ind,3],3*data[reassign_ind+1:end,3])

#     # create functions to be passed to IPOPT
#     # IPOPT-friendly funcs
#     jac_constraint = Zoned.create_jac_constraint(Ea,COAST.Rjoules,D0,0.0,0.0,Nt,Nx,t,r,U238_new)
#     constraint_zon = Zoned.create_constraint_zon(Ea,COAST.Rjoules,D0,U238_new,0.0,0.0,Nt,Nx,t,r)

    
#     # better for underconstrained setups!
#     prob_smye = createProblem(
#         Nt, # should match length T_L, T_U otherwise julia may crash
#         lower_bound_arr, # lower bound on temperature
#         upper_bound_arr, # upper bound
#         Nx,
#         lower_bound_constr, # lower bound of Pb concentration; i.e. constraints 
#         upper_bound_constr,
#         Nt*Nx, # number elements in constraint jacobian
#         Nt*Nx,
#         Zoned.smooth_zon_objective, # objective function; sum smoothness (multiobjective not yet possible)
#         constraint_zon,
#         Zoned.grad_smooth_zon_objective,
#         jac_constraint,
#     )

#     addOption(prob_smye, "hessian_approximation", "limited-memory") # hessian rarely (if ever) called; approximation is ok
#     addOption(prob_smye, "tol", 1.0) # smoothness not as much of an issue here
#     addOption(prob_smye,"print_level",5)
#     prob_smye.x = copy(T)


#     status=solveProblem(prob_smye)    

#     # Value 2
#     # create functions to be passed to IPOPT
#     # IPOPT-friendly funcs
#     U238_new = reshape(U238_new,:,1)
#     Pbmeas = reshape(reverse(data[:,2]),:,1)
#     sigmeas = reshape(reverse(data[:,3]),:,1)
#     r = reshape(r,:,1)
    empty_dict = Dict(keys(U238_new).=>0.0.*values(U238_new))
    zon_loglike_objective = Zoned.create_zon_loglike_objective(Ea,COAST.Rjoules,D0,U238_new,empty_dict,empty_dict,Nt,Nx,t,r,Pbmeas,sigmeas,ngrains)
    grad_loglike_objective = Zoned.create_grad_loglike_objective(Ea,COAST.Rjoules,D0,U238_new,empty_dict,empty_dict,Nt,Nx,t,r,Pbmeas,sigmeas,ngrains)

    n_constr = Nt-1
    upper_bound_constr = 100*ones(n_constr)
    lower_bound_constr = 0.0*ones(n_constr)

    prob2 = createProblem(
        Nt, # should match length T_L, T_U otherwise julia may crash
        lower_bound_arr, # lower bound on temperature
        upper_bound_arr, # upper bound
        n_constr,
        lower_bound_constr, # lower bound of Pb concentration; i.e. constraints 
        upper_bound_constr,
        Nt*n_constr, # number elements in constraint jacobian
        Nt*n_constr, # number elements in constraint hessian; not needed in approximation
        zon_loglike_objective, # objective function; sum smoothness (multiobjective not yet possible)
        Zoned.decrease_constraint,
        grad_loglike_objective,
        Zoned.jac_decrease_constraint,
    )  
    addOption(prob2, "hessian_approximation", "limited-memory") # hessian rarely (if ever) called; approximation is ok
    addOption(prob2, "tol", 1e-4) # smoothness not as much of an issue here
    addOption(prob2,"print_level",5)
    prob2.x = copy(T)  
    status=solveProblem(prob2)

    constraint_zon = create_constraint_zon(Ea,COAST.Rjoules,D0,U238_new[1],0.0,0.0,Nt,Nx[1],t,r[1])
    Pbs = zeros(Nx[1]) # preallocate
    constraint_zon(prob2.x,Pbs)

    constraint_zon = create_constraint_zon(Ea,COAST.Rjoules,D0,U238_new[2],0.0,0.0,Nt,Nx[2],t,r[2])
    Pbs2 = zeros(Nx[2]) # preallocate
    constraint_zon(prob2.x,Pbs2)

    # plot results
    # plot(t/3.156e13,prob2.x.-273.15,label="fitted t-T",legend=:topleft,lw=2)
    # plot!(t/3.156e13,T.-273.15,label="starting t-T",lw=2)
    # xlabel!("time (Ma)")
    # ylabel!("temperature (°C)")
    # title!("decreasing: GB119C−42")

    # scatter(r[1][1:end]*1e6,data[1][1:end,2],ribbon=reverse(sigmeas[1][1:end]),xflip=true)
    # plot!(r[1][1:end]*1e6,reverse(Pbs[1:end]),lw=2,label="fitted values")

end
