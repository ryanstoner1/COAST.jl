

module App
using Plots
using COAST
using COAST.Zoned
using JuMP
using JSON3
using Genie
using Ipopt
using Genie.Router
using Genie.Requests
using Genie.Renderer.Html
include("test_app_running.jl")

export launchServer
# string to say hello to users
html_coast_introduction = """
    \n <p>COAST is a program for thermochronology sensitivity analysis and
     modeling.</p> \n <p>More information can be found on the official
    <a href="https://github.com/ryanstoner1/COAST.jl/">Github page.</a></p> 
"""

# allow cors headers because chrome complains about these otherwise
Genie.config.cors_headers["Access-Control-Allow-Methods"] ="GET,POST"

progress_test = [0.0]
function launchServer(progress_test,port)
  # holds run info
  run_queue = Dict("ids"=>[],"progress_percent"=>[],"results"=>[])

   # configuration to make website happy
   Genie.config.run_as_server = true
   Genie.config.server_host = "0.0.0.0"
   Genie.config.server_port = port

  route("/model", method = POST) do
    print("running model POST setup \n")
    # extract payload from front-end
    payload = jsonpayload()
    #print(payload)
    # run appropriate function(s)    
    output_string = parse_and_run_payload!(run_queue,payload)

    # make output a string to send back to front-end
    return Genie.Renderer.Json.json(output_string)    
  end

  # simple summary for website visits/GET requests
  route("/model", method = GET) do
      print("test model get script \n")
      html_coast_introduction
  end

  # return progress of individual run
  route("/progress", method = POST) do
    payload = jsonpayload()
    id = payload["id"]
    id2find = run_queue["ids"].== id
    progress = run_queue["progress_percent"][id2find]
    return "$(progress)"
  end

  # create other page for testing purposes
  route_test_page_get_post!(progress_test,html_coast_introduction)

  Genie.AppServer.startup()
end

# function to run in COAST
function parse_and_run_payload!(queue,payload)
  id = payload["id"]
  # if id in queue["ids"]
  #   return "Run already in progress!"
  # else
  #   push!(queue["ids"],id)
  # end
  
  push!(queue["progress_percent"],0) 
  push!(queue["results"],Dict()) 
  function_to_COAST = payload["function_to_run"]
  if function_to_COAST=="zonation"
    print("Running zonation script! \n")
    Ea = payload["Ea"]
    Ea = convert(Float64,Ea)
    D0 = payload["D0"]
    D0 = convert(Float64,D0)
    Nt = payload["Nt"]
    Nt = parse(Int64,Nt)
    t_beg = payload["t_beg"]
    t_beg = parse(Float64,t_beg)
    t_end = payload["t_end"]
    t_end = parse(Float64,t_end)
    rad = payload["radius"]
    rad = parse(Float64,rad)
    data = payload["data"]
    vec_grains = convert(Vector{Vector{Vector{Float64}}},data)
    vec_grains = [collect(reduce(hcat,grain_data)') for grain_data in vec_grains]
    outstring = zonation_sensitivity(Ea,D0,rad, vec_grains, t_beg,t_end, Nt)
    
    return outstring
  end
  if function_to_COAST == "zonation"
    print("Running zonation script! \n")
    n_t = payload["zon_n_t_segs"]
    Ea = payload["Ea"]
    D0 = payload["D0"]
    U38_Pb06 = payload["U38Pb06"] # matrix
    sigU38_Pb06 = payload["sigU38Pb06"] # matrix
    L = payload["Lmax"]
    tmax = payload["tmax"]
    tmin = payload["tmin"]
    # 
    dr = payload["dr"]
    distance = payload["distance"] # Vector
    Tbound_top = payload["Tbound_top"]
    Tbound_bot = payload["Tbound_bot"]
    outstring = zonation_n_times_forward(distance,L,n_t,Ea,D0,U38_Pb06,sigU38_Pb06,dr,
      tmax,tmin,Tbound_top,Tbound_bot)
    return outstring
  end

  return "Passing JSON payload to COAST successful!"
end

function zonation_n_times_forward(distance,L,n_t,Ea,D0,U38_Pb06,sigU38_Pb06,dr,
  tmax,tmin,Tbound_top,Tbound_bot)
  print("running_zonation_n_times_forward \n")
  tmax = parse(Float64,tmax) # in yrs
  tmin = parse(Float64,tmin) # in yrs
  n_t  = parse(Int64,n_t)
  Ea = parse(Float64,Ea)
  D0 = parse(Float64,D0)
  dr = parse(Float64,dr)
  L = parse(Float64,L)
  distance = JSON3.read(distance, Vector{Float64})./1e6
  sigU38_Pb06 = JSON3.read(sigU38_Pb06, Vector{Vector{Float64}})
  Tbound_top = JSON3.read(Tbound_top, Vector{Float64})
  Tbound_bot = JSON3.read(Tbound_bot, Vector{Float64})
  U38_Pb06 = JSON3.read(U38_Pb06, Vector{Vector{Float64}})  
  # rows are permutations of sample sets
  n_constraints = length(U38_Pb06[1])

  t = collect(LinRange(tmax*COAST.sec_in_yrs,tmin*COAST.sec_in_yrs,n_t))
  upper_bound_arr = 420.0*ones(n_t)
  upper_bound_arr[Tbound_top.>-1.0] = Tbound_top[Tbound_top.>-1.0]
  lower_bound_arr = 273.0*ones(n_t)
  lower_bound_arr[Tbound_bot.>-1.0] = Tbound_bot[Tbound_bot.>-1.0]
  model = Model(Ipopt.Optimizer)
  JuMP.set_optimizer_attributes(model,"print_level"=>2,"tol"=>1e2,"linear_solver"=>"mumps","print_timing_statistics"=>"no")
  register_objective_function!(n_t,model)
  @NLparameter(model, pa[i=1:n_constraints] == U38_Pb06[1][i])
  start_points = 0.5.*ones(Float64,n_t)
  (T,set_dev) = define_variables!(n_t,n_constraints,model,start_points,upper_bound=upper_bound_arr,lower_bound=lower_bound_arr)
  register_forward_model_zonation!(n_t,model)

  
  return lower_bound_arr
end

function zonation_sensitivity(Ea,D0,rad,vec_grains,t_beg,t_end,Nt)

  ngrains = length(vec_grains)
  data = Dict((1:ngrains).=>vec_grains)
  U238 = 1.0

  # convert to meters
  for val in values(data)    
    val[:,1]/=1e6
  end
  rad /= 1e6
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
  end_model_Ma = t_end
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

  t = collect(LinRange(t_beg,end_model_Ma,Nt).*3.1558e7*1e6)
  dt = -maximum(diff(t))/(3.1558e7*1e6)
  T = collect(LinRange(800.0,673.0,Nt).+273.15)
  
  
  upper_bound_arr = 1100.0*ones(Nt)    
  lower_bound_arr = 673.0*ones(Nt)
  lower_bound_arr[1] = 1100.0

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
  print(r)
  status=solveProblem(prob2)
  
  constraint_zon = create_constraint_zon(Ea,COAST.Rjoules,D0,U238_new[1],0.0,0.0,Nt,Nx[1],t,r[1])
  Pbs = zeros(Nx[1]) # preallocate
  constraint_zon(prob2.x,Pbs)

  constraint_zon = create_constraint_zon(Ea,COAST.Rjoules,D0,U238_new[2],0.0,0.0,Nt,Nx[2],t,r[2])
  Pbs2 = zeros(Nx[2]) # preallocate
  constraint_zon(prob2.x,Pbs2)
  if status==0
    out = prob2.x
  else
    out = "COAST could not find optimal solution!"
  end

  return out
end

end # end module

# # run if running locally
#launchServer(parse(Int, ARGS[1])) # run from dokku or heroku

# if abspath(PROGRAM_FILE) == @__FILE__
  
#   print("running app!\n")
#   progress_test = [0.0]
#   App.launchServer(progress_test,8000)
# end