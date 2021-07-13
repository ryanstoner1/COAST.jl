

module App
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

Genie.config.cors_headers["Access-Control-Allow-Credentials"] = "true"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,HEAD,OPTIONS,POST,PUT"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "*"
Genie.config.cors_headers["Access-Control-Request-Headers"] = "*"
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"
progress_test = [0.0]
run_list = []

function launchServer(progress_test,port)
  # holds run info
  run_queue = Dict("ids"=>[],"progress_percent"=>[],"results"=>[])
  
   # configuration to make website happy
   Genie.config.run_as_server = true
   Genie.config.server_host = "0.0.0.0"
   Genie.config.server_port = port

  route("/model", method = POST) do
    # extract payload from front-end
    payload = jsonpayload()

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
  
  # update stats
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
  elseif function_to_COAST=="store_params"
    userIP = payload["userIP"]
    push!(run_list,Dict(userIP=>payload))
    outstring = "params stored"
    return outstring
  
  elseif function_to_COAST=="run_xy_flowers09"
    xData = payload["xData"]
    yData = payload["yData"]
    xSeries = payload["xSeries"]
    ySeries = payload["ySeries"]
    xSeries = xSeries.+ 273.15
    ySeries = ySeries*3.1558e7*1e6
    checkedList = payload["checkedList"]
    userIP = payload["userIP"]

    ind2run = findall(x -> haskey(x,userIP),run_list)
    payload2run = run_list[ind2run[1]][userIP]
    numberX = parse(Int64,payload2run["numberX"])
    numberZ = parse(Int64,payload2run["numberZ"])
    tTchecked = "onlydiffparams"

    if length(checkedList)==2
      x = payload2run[checkedList[1]]
      z = payload2run[checkedList[2]]
    elseif !(length(xData)>0) & (length(yData)>0) & (length(checkedList)==1)
      x = payload2run[checkedList[1]]
      z = [z["val"] for z in yData if z["check"]==true][1]
      z = Dict{String,Any}("min"=>z[1]["z"],"main"=>z[2]["z"],"max"=>z[3]["z"]) 
      tTchecked = "z&diffparam"
    elseif (length(xData)>0) & !(length(yData)>0) & length(checkedList)==1
      x = [x["val"] for x in xData if x["check"]==true][1]
      x = Dict{String,Any}("min"=>x[1]["x"],"main"=>x[2]["x"],"max"=>x[3]["x"]) 
      z = payload2run[checkedList[1]]
      tTchecked = "x&diffparam"
    elseif (length(xData)>=2) & (length(yData)==0) & (length(checkedList)==0)
      temp = [x["val"] for x in xData if x["check"]==true][1]  
      x = temp[1]
      x = Dict{String,Any}("min"=>x[1]["x"],"main"=>x[2]["x"],"max"=>x[3]["x"])  
      z = temp[2]
      z = Dict{String,Any}("min"=>z[1]["x"],"main"=>z[2]["x"],"max"=>z[3]["x"]) 
      tTchecked = "2 x"  
    elseif (length(yData)>=2) & (length(xData)==0) & (length(checkedList)==0)
      temp = [z["val"] for z in yData if z["check"]==true][1]  
      x = temp[1]
      x = Dict{String,Any}("min"=>x[1]["z"],"main"=>x[2]["z"],"max"=>x[3]["z"]) 
      z = temp[2]
      z = Dict{String,Any}("min"=>z[1]["z"],"main"=>z[2]["z"],"max"=>z[3]["z"]) 
      tTchecked = "2 z"
    elseif (length(checkedList)==0)
      x = [x["val"] for x in xData if x["check"]==true][1]
      x = Dict{String,Any}("min"=>x[1]["x"],"main"=>x[2]["x"],"max"=>x[3]["x"])  
      z = [z["val"] for z in yData if z["check"]==true][1] 
      z = Dict{String,Any}("min"=>z[1]["z"],"main"=>z[2]["z"],"max"=>z[3]["z"]) 
      tTchecked = "1 x&1 z" 
    end
    
    if typeof(x["min"])==String
      x["max"] = parse(Float64,x["max"])
      x["min"] = parse(Float64,x["min"]) 
    end

    if typeof(z["min"])==String
      z["max"] = parse(Float64,z["max"])
      z["min"] = parse(Float64,z["min"]) 
    end

    z["run"] = range(z["min"], stop=z["max"], length=round(Int64,numberZ))
    x["run"] = range(x["min"], stop=x["max"], length=round(Int64,numberX))
    lenXSeries = length(xSeries)
    lenYSeries = length(ySeries)

    n_iter = 50    

    t_Ma = zeros((round(Int64,numberX), round(Int64,numberZ)))
    for (i,xi) in enumerate(x["run"])
        for (j,zi) in enumerate(z["run"])
          if (tTchecked)=="onlydiffparams"
              payload2run[checkedList[1]]["main"] = xi
              payload2run[checkedList[2]]["main"] = zi
          elseif (tTchecked)=="z&diffparam"
              payload2run[checkedList[1]]["main"] = xi
              ySeries[yData[1]["ind"]] = zi
          elseif (tTchecked)=="x&diffparam"
              payload2run[checkedList[1]]["main"] = zi
              xSeries[xData[1]["ind"]] = xi
          elseif (tTchecked)=="2 x"
              xSeries[xData[1]["ind"]] = xi
              xSeries[xData[2]["ind"]] = xi
          elseif (tTchecked)=="2 z"
              ySeries[yData[1]["ind"]] = yi
              ySeries[yData[2]["ind"]] = zi
          elseif (tTchecked)=="1 x&1 z"              
              xSeries[xData[1]["ind"]] = xi
              ySeries[yData[1]["ind"]] = zi
        end
        xSeriesRun = Float64[]
        ySeriesRun = Float64[]
        for ind in 1:lenXSeries
          if ind<lenXSeries
            xSeriesRun = vcat(xSeriesRun,LinRange(xSeries[ind], xSeries[ind+1], 50))
            ySeriesRun = vcat(ySeriesRun,LinRange(ySeries[ind], ySeries[ind+1], 50))
          end
        end

        L_dist = typeof(payload2run["Letch"]["main"])==String ? parse(Float64, payload2run["Letch"]["main"]) : convert(Float64, payload2run["Letch"]["main"])
        U238 = typeof(payload2run["U238"]["main"])==String ? parse(Float64, payload2run["U238"]["main"]) : convert(Float64, payload2run["U238"]["main"])
        Th232 = typeof(payload2run["Th232"]["main"])==String ? parse(Float64, payload2run["Th232"]["main"]) : convert(Float64, payload2run["Th232"]["main"])
        Ea = typeof(payload2run["Ea"]["main"])==String ? parse(Float64, payload2run["Ea"]["main"]) : convert(Float64, payload2run["Ea"]["main"])
        L = typeof(payload2run["rad"]["main"])==String ? parse(Float64, payload2run["rad"]["main"]) : convert(Float64, payload2run["rad"]["main"])
        D0 = typeof(payload2run["D0"]["main"])==String ? parse(Float64, payload2run["D0"]["main"]) : convert(Float64, payload2run["D0"]["main"])
        rmr0 = typeof(payload2run["rmr0"]["main"])==String ? parse(Float64, payload2run["rmr0"]["main"]) : convert(Float64, payload2run["rmr0"]["main"])
    
        alpha = typeof(payload2run["alpha"]["main"])==String ? parse(Float64, payload2run["alpha"]["main"]) : convert(Float64, payload2run["alpha"]["main"])
        c0 = typeof(payload2run["c0Value"]["main"])==String ? parse(Float64, payload2run["c0Value"]["main"]) : convert(Float64, payload2run["c0Value"]["main"])
        c1 = typeof(payload2run["c1Value"]["main"])==String ? parse(Float64, payload2run["c1Value"]["main"]) : convert(Float64, payload2run["c1Value"]["main"])
        c2 = typeof(payload2run["c2Value"]["main"])==String ? parse(Float64, payload2run["c2Value"]["main"]) : convert(Float64, payload2run["c2Value"]["main"])
        c3 = typeof(payload2run["c3Value"]["main"])==String ? parse(Float64, payload2run["c3Value"]["main"]) : convert(Float64, payload2run["c3Value"]["main"])
        eta_q = typeof(payload2run["etaq"]["main"])==String ? parse(Float64, payload2run["etaq"]["main"]) : convert(Float64, payload2run["etaq"]["main"])
        psi = typeof(payload2run["psi"]["main"])==String ? parse(Float64, payload2run["psi"]["main"]) : convert(Float64, payload2run["psi"]["main"])
        omega = typeof(payload2run["omega"]["main"])==String ? parse(Float64, payload2run["omega"]["main"]) : convert(Float64, payload2run["omega"]["main"])
        etrap = typeof(payload2run["etrap"]["main"])==String ? parse(Float64, payload2run["etrap"]["main"]) : convert(Float64, payload2run["etrap"]["main"])

        (U238_V,U235_V,Th232_V,U238_mol,U235_mol,Th232_mol
            )= conc_to_atoms_per_volume(U238*1e-6,Th232*1e-6)
        L2 = 60
        log10D0L_a2_rdaam = log10(exp(D0)*L^2/L2^2)
          
        # print(alpha,"\n",c0,"\n",c1,"\n",c2,"\n",c3,"\n",rmr0,"\n",eta_q,"\n",L_dist*1e-4,"\n",psi,"\n",omega,"\n",(etrap*1e3),"\n",COAST.Rjoules,"\n",(Ea*1e3),"\n",log10D0L_a2_rdaam,"\n",n_iter,"\n",
        # U238_mol,"\n",U238_V,"\n",U235_mol,"\n",U235_V,"\n",Th232_mol,"\n",Th232_V,"\n",L,"\n")

        he_est = COAST.rdaam_forward_diffusion(alpha,c0,c1,c2,c3,rmr0,eta_q,L_dist*1e-4,psi,omega,etrap*1e3,COAST.Rjoules,Ea*1e3,log10D0L_a2_rdaam,n_iter,
        U238_mol,U238_V,U235_mol,U235_V,Th232_mol,Th232_V,L*1e-6,reverse(ySeriesRun)...,reverse(xSeriesRun[1:end-1])...)
        pre_he_t2 = (8*(U238_mol*exp(43.6*1e6*COAST.sec_in_yrs/COAST.τ38)-U238_mol)+
                 7*(U235_mol*exp(43.6*1e6*COAST.sec_in_yrs/COAST.τ35)-U235_mol))
        
        t_val = [1e15]
        for i=1:10
          f0 = (8*(U238_mol*exp(t_val[1]/COAST.τ38)-U238_mol)+
          7*(U235_mol*exp(t_val[1]/COAST.τ35)-U235_mol)) - he_est
          f0_prime = 8*(U238_mol*exp(t_val[1]/COAST.τ38)/COAST.τ38)+7*(U235_mol*exp(t_val[1]/COAST.τ35)/COAST.τ35)
          t_val[1] = t_val[1] - f0/f0_prime
        end
        t_Ma[i,j] = t_val[1]/(1e6*COAST.sec_in_yrs)
      end
    end

    outstring = [t_Ma, x["run"]]
    return outstring

  elseif function_to_COAST=="global_sensitivity"
    samples = payload["samples"]
    print(typeof(samples))
    print(length(samples))
    data = payload["data"]
    print
    outstring = "response GSA julia"
    return outstring

  elseif function_to_COAST=="single_grain"
    Etrap = payload["Etrap"]
    Etrap = parse(Float64,Etrap)
    alpha = payload["alpha"]
    alpha = parse(Float64, alpha)
    c0 = payload["c0"]
    c0 = parse(Float64, c0)
    c1 = payload["c1"]
    c1 = parse(Float64, c1)
    c2 = payload["c2"]
    c2 = parse(Float64, c2)
    c3 = payload["c3"]
    c3 = parse(Float64, c3)
    rmr0=payload["rmr0"]
    rmr0 = parse(Float64, rmr0)
    eta_q = payload["eta_q"]
    eta_q = parse(Float64, eta_q)
    L_dist = payload["L_dist"]
    L_dist = parse(Float64, L_dist)
    psi = payload["psi"]
    psi = parse(Float64, psi)
    omega = payload["omega"]
    omega = parse(Float64, omega)
    E_L = payload["E_L"]
    E_L = parse(Float64, E_L)
    D0L_a2 = payload["D0L_a2"]
    D0L_a2 = parse(Float64, D0L_a2)
    rad = payload["rad"]
    rad = parse(Float64, rad)
    u38 = payload["u38"]
    u38 = parse(Float64, u38)
    th32 = payload["th32"]
    th32 = parse(Float64, th32)
    raw_tT = JSON3.read(payload["tT"])

    times = [data_pt["x"]*COAST.sec_in_yrs for data_pt in raw_tT]
    
    T = [data_pt["z"]+273.15 for data_pt in raw_tT]
    

    # times = payload["times"]
    # times = convert(Vector{Float64},times)
    # T = payload["T"]
    # T = convert(Vector{Float64},T)
    if (
      isnan(rmr0) ||
      isnan(c0) ||
      isnan(c1) ||
      isnan(c2) ||
      isnan(c3) ||
      isnan(alpha) ||
      isnan(eta_q) ||
      isnan(L_dist)||
      isnan(psi) ||
      isnan(omega) ||
      isnan(Etrap)
        )
      rmr0 = 1.0
      c0 = 1.0
      c1 = 1.0
      c2 = 1.0
      c3 = 1.0
      alpha = 1.0
      eta_q = 1.0
      L_dist = 1.0  
      psi = 0.0
      omega = 0.0 
      Etrap = 0.0 
    end
    
    outstring = single_grain(rmr0,c0,c1,c2,c3,alpha,eta_q,L_dist,psi,omega,Etrap,rad,u38,th32,E_L,D0L_a2,times,T)
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

function single_grain(rmr0,c0,c1,c2,c3,alpha,eta_q,L_dist,psi,omega,Etrap,L,u38,th32,E_L,D0L_a2,times,T)
  # preprocess concentrations
  (U238_V,U235_V,Th232_V,U238_mol,U235_mol,Th232_mol) = ppm_to_atoms_per_volume(u38,th32,density=3.20)
  L2 = 60*1e-4
  n_iter = 60
  log10D0L_a2_rdaam = log10(D0L_a2*L^2/L2^2)
  mass_he_t1 = rdaam_forward_diffusion(alpha,c0,c1,c2,c3,rmr0,eta_q,L_dist,psi,omega,Etrap,COAST.Rjoules,E_L,log10D0L_a2_rdaam,n_iter,
                   U238_mol,U238_V,U235_mol,U235_V,Th232_mol,Th232_V,L,times...,T...)
  outstring = string(mass_he_t1)
  #outstring = "ran successfully"
  return outstring
end

end # end module