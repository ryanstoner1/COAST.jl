

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

function run_rdaam_dict(n_iter, TSeriesRun, tSeriesRun, data)
  L_dist = data["Letch"]
  U238 = data["U238"]
  Th232 = data["Th232"]
  Ea = data["Ea"]
  rad = data["rad"]
  D0 = data["D0"]
  rmr0 = data["rmr0"]
  alpha = data["alpha"]
  c0Value = data["c0Value"]
  c1Value = data["c1Value"]
  c2Value = data["c2Value"]
  c3Value = data["c3Value"]
  eta_q = data["etaq"]
  psi = data["psi"]
  omega = data["omega"]
  etrap = data["etrap"]


  (U238_V,U235_V,Th232_V,U238_mol,U235_mol,Th232_mol
  )= conc_to_atoms_per_volume(U238*1e-6,Th232*1e-6)
  L2 = 60
  log10D0L_a2_rdaam = log10(exp(D0)*data["rad"]^2/L2^2)
  
  he_est = COAST.rdaam_forward_diffusion(alpha,c0Value,c1Value,c2Value,c3Value,rmr0,eta_q,L_dist*1e-4,psi,omega,etrap*1e3,COAST.Rjoules,Ea*1e3,log10D0L_a2_rdaam,n_iter,
     U238_mol,U238_V,U235_mol,U235_V,Th232_mol,Th232_V,rad*1e-6,reverse(tSeriesRun)...,reverse(TSeriesRun[1:end-1])...)
  # initial guess
  t_val = [1e15]
  for i=1:10
      f0 = (8*(U238_mol*exp(t_val[1]/COAST.τ38)-U238_mol)+
      7*(U235_mol*exp(t_val[1]/COAST.τ35)-U235_mol)) - he_est
      f0_prime = 8*(U238_mol*exp(t_val[1]/COAST.τ38)/COAST.τ38)+7*(U235_mol*exp(t_val[1]/COAST.τ35)/COAST.τ35)
      t_val[1] = t_val[1] - f0/f0_prime
  end
  t_Ma = t_val[1]/(1e6*COAST.sec_in_yrs)

  return t_Ma

end

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
    has_IP = 0
    for (ind, dict_val) in enumerate(run_list)
        if haskey(dict_val,userIP)==1
          has_IP = 1
          run_list[ind][userIP] = payload
        end
    end

    if has_IP==0
      push!(run_list,Dict(userIP=>payload))
    end
          

    
    outstring = "params stored"
    return outstring
  
  ####
  # LOCAL SENSITIVITY/ X-Y-(Z) plot
  # NO ZONATION
  elseif function_to_COAST=="xy"
    # grab data
    tVaried = payload["tData"] # data points that user chooses to vary tT
    TVaried = payload["TData"]
    checkedList = payload["checkedList"]  
    diffusion_model = payload["model"]

    # convert to correct units
    sec_in_Ma = 3.1558e13
    c_to_kelvin = 273.15
    tSeries = payload["tSeries"]  # all base tT data points wout variation of tT
    TSeries = payload["TSeries"]
    tSeries = tSeries*sec_in_Ma
    TSeries = TSeries.+c_to_kelvin

    # deal with concurrent users by storing their data separately and accessing here
    userIP = payload["userIP"]
    ind2run = findall(x -> haskey(x,userIP),run_list)
    data = run_list[ind2run[1]][userIP]
    data=JSON3dict_to_dict(data) # necessary

    # get number datapoints X-Y-(Z)
    numberX = parse(Int64,data["numberX"])
    if isempty(data["numberZ"])
      numberZ = 1      
    else 
      numberZ = parse(Int64,data["numberZ"])
    end
    
    # CHECK if time or temperature are varied or constant
    names_out = [] # to return to user for plotting
    t_var = [] # time array to (potentially) fill
    T_var = [] # temperature array to (potentially) fill
    t_ind = [] # time point index array to (potentially) fill
    T_ind = [] # temperature point index array to (potentially) fill

    # get any time variation that's been checked by user
    try
      t_var = [t["val"] for t in tVaried if t["check"]==true]
      t_ind = [t["ind"] for t in tVaried if t["check"]==true]
      t_var = [Dict("min"=>t_point[1]["x"]*sec_in_Ma,"main"=>t_point[2]["x"]*sec_in_Ma,"max"=>t_point[3]["x"]*sec_in_Ma)
         for t_point in t_var]
    catch e
      println("no time variation defined!")
    end

    # get any temperature variation that's been checked by user
    try
      T_var = [T["val"] for T in TVaried if T["check"]==true]
      T_ind = [T["ind"] for T in TVaried if T["check"]==true]
      
      T_var = [Dict("min"=>T_point[1]["y"]+c_to_kelvin,"main"=>T_point[2]["y"]+c_to_kelvin,"max"=>T_point[3]["y"]+c_to_kelvin)
         for T_point in T_var]     
    catch e
      print("no temperature variation defined!")
    end
    print(t_var)
    print(T_var)
    # check TYPE of X-Y-(Z) data (t/T/diffusion parameter)
    if length(checkedList)==2
      tTchecked = "onlydiffparams"
      names_out = checkedList
      x = data[checkedList[1]]      
      z = data[checkedList[2]]         

    elseif (isempty(t_var)) & !(isempty(T_var)) & (length(checkedList)==1)
      tTchecked = "diffparam&T"
      names_out = [checkedList[1],string("temperature at point ",T_ind[1]+1," (°C)")]
      x = data[checkedList[1]]
      z = T_var[1] 

    elseif !(isempty(t_var)) & (isempty(T_var)) & length(checkedList)==1
      tTchecked = "t&diffparam"
      names_out = [string("time at point ",t_ind[1]+1," (Ma)"),checkedList[1]]
      x = t_var[1]
      z = data[checkedList[1]]
    
    elseif (length(t_var)>=2) & (isempty(T_var)) & (length(checkedList)==0)
      tTchecked = "2 t" 
      names_out = [string("time at point ",t_ind[1]+1," (Ma)"),string("time at point ",t_ind[2]+1," (Ma)")]   
      x = t_var[1]
      z = t_var[2]
       
    elseif (length(T_var)>=2) & (length(t_var)==0) & (length(checkedList)==0)
      tTchecked = "2 T"
      names_out = [string("temperature at point ",T_ind[1]+1," (Ma)"),string("temperature at point ",T_ind[2]+1," (Ma)")] 
      x = T_var[1]
      z = T_var[2]
      
    elseif (length(checkedList)==0) & !(isempty(t_var)) & !(isempty(T_var))
      tTchecked = "1 t&1 T"
      names_out = [string("time at point ",t_ind[1]+1," (Ma)"),string("temperature at point ",T_ind[1]+1," (°C)")]
      x = t_var[1]
      z = T_var[1]
      
    # cases where only X-Y plotted (not Z)
    elseif (length(checkedList)==1) & isempty(t_var) & isempty(T_var)
      tTchecked = "1diffparam"
      names_out = checkedList
      x = data[checkedList[1]]
      z = Dict{String,Any}("run"=>["val"])
      
    elseif (length(checkedList)==0) & (length(t_var)==1) & isempty(T_var)
      tTchecked = "1t"
      names_out = [string("time at point ",t_ind[1]+1," (Ma)")]
      x = t_var[1]
      z = Dict{String,Any}("run"=>["val"])
      
    elseif (length(checkedList)==0) & (length(T_var)==1) & isempty(t_var)
      tTchecked = "1T"
      names_out = [string("temperature at point ",T_ind[1]+1," (°C)")]
      x = T_var[1]
      z = Dict{String,Any}("run"=>["val"])
    end
    # END OF t/T/diff'n param CHECKING
    
    # convert from JSON3 to standard Dict
    x = Dict{String,Any}("min"=>x["min"],"main"=>x["main"],"max"=>x["max"]) 
    if haskey(z,"min")
      z = Dict{String,Any}("min"=>z["min"],"main"=>z["main"],"max"=>z["max"])
    end

    # convert types in case not converted on javascript side - harder to enforce there
    if typeof(x["min"])==String
      x["max"] = parse(Float64,x["max"])
      x["min"] = parse(Float64,x["min"]) 
    end

    if haskey(z,"min")
      if (typeof(z["min"])==String) 
        z["max"] = parse(Float64,z["max"])
        z["min"] = parse(Float64,z["min"]) 
      end
    end

    # INITIALIZE PLOTTING LOOP VALS
    x["run"] = range(x["min"], stop=x["max"], length=round(Int64,numberX))
    if (haskey(z,"min"))
      z["run"] = range(z["min"], stop=z["max"], length=round(Int64,numberZ))
    end

    lentSeries = length(tSeries)
    n_iter = 50 # for diffusion solver   
    n_time_seg_subsegs = 20 
    t_Ma = zeros((round(Int64,numberX), round(Int64,numberZ)))


    for (i,xi) in enumerate(x["run"])
        for (j,zi) in enumerate(z["run"])
          print(tTchecked)
          if (tTchecked)=="onlydiffparams"
              data[checkedList[1]]["main"] = string(xi)
              data[checkedList[2]]["main"] = string(zi)
          elseif (tTchecked)=="diffparam&T"
            data[checkedList[1]]["main"] = xi
            TSeries[TVaried[1]["ind"]+1] = zi # convert to kelvin; correct for Javascript indexing
          elseif (tTchecked)=="t&diffparam"
            tSeries[tVaried[1]["ind"]+1] = xi
            data[checkedList[1]]["main"] = zi
          elseif (tTchecked)=="2 t"
              tSeries[tVaried[1]["ind"]+1] = xi
              tSeries[tVaried[2]["ind"]+1] = zi
          elseif (tTchecked)=="2 T"
            print("Tseries is: $TSeries\n")
            Tindex2 = T_ind
            print("T_ind is: $Tindex2\n")
              TSeries[T_ind[1]+1] = xi
              TSeries[T_ind[2]+1] = zi
          elseif (tTchecked)=="1 t&1 T"              
              tSeries[tVaried[1]["ind"]+1] = xi
              TSeries[TVaried[1]["ind"]+1] = zi
          elseif (tTchecked)=="1diffparam"
              data[checkedList[1]]["main"] = xi
          elseif (tTchecked)=="1t"
              tSeries[tVaried[1]["ind"]+1] = xi
          elseif (tTchecked)=="1T"
              TSeries[TVaried[1]["ind"]+1] = xi
        end

        # javascript arrays are not necessarily sorted
        idSort = sortperm(tSeries)
        tSeries = tSeries[idSort]
        TSeries = TSeries[idSort]

        # subsample t-T path
        tSeriesRun = Float64[]
        TSeriesRun = Float64[]
        for ind in 1:lentSeries       
          if ind<lentSeries
            if isempty(tSeriesRun)
              tSeriesRun = vcat(tSeriesRun,LinRange(tSeries[ind], tSeries[ind+1], n_time_seg_subsegs))
              TSeriesRun = vcat(TSeriesRun,LinRange(TSeries[ind], TSeries[ind+1], n_time_seg_subsegs))
            else
              tSectionNew = LinRange(tSeries[ind], tSeries[ind+1], n_time_seg_subsegs)
              TSectionNew = LinRange(TSeries[ind], TSeries[ind+1], n_time_seg_subsegs)
              tSeriesRun = vcat(tSeriesRun,tSectionNew[2:end])
              TSeriesRun = vcat(TSeriesRun,TSectionNew[2:end])              
            end
          end
        end
        
        print("t is: $tSeries \n")
        print("T is: $TSeries for i = $i j= $j \n")
        
        # general params conversion
        L_dist = typeof(data["Letch"]["main"])==String ? parse(Float64, data["Letch"]["main"]) : convert(Float64, data["Letch"]["main"])
        U238 = typeof(data["U238"]["main"])==String ? parse(Float64, data["U238"]["main"]) : convert(Float64, data["U238"]["main"])
        Th232 = typeof(data["Th232"]["main"])==String ? parse(Float64, data["Th232"]["main"]) : convert(Float64, data["Th232"]["main"])
        Ea = typeof(data["Ea"]["main"])==String ? parse(Float64, data["Ea"]["main"]) : convert(Float64, data["Ea"]["main"])
        L = typeof(data["rad"]["main"])==String ? parse(Float64, data["rad"]["main"]) : convert(Float64, data["rad"]["main"])
        D0 = typeof(data["D0"]["main"])==String ? parse(Float64, data["D0"]["main"]) : convert(Float64, data["D0"]["main"])
        print("U238 concentration is: $U238 \n")
        print("Th232 concentration is: $Th232 \n")
        L2 = 60 # microns
        log10D0L_a2_rdaam = log10(exp(D0)*L^2/L2^2)

        # handle specific diffusion model param conversion
        if (diffusion_model=="flowers09")
          (U238_V,U235_V,Th232_V,U238_mol,U235_mol,Th232_mol
          )= conc_to_atoms_per_volume(U238*1e-6,Th232*1e-6)      
          rmr0 = typeof(data["rmr0"]["main"])==String ? parse(Float64, data["rmr0"]["main"]) : convert(Float64, data["rmr0"]["main"])
          alpha = typeof(data["alpha"]["main"])==String ? parse(Float64, data["alpha"]["main"]) : convert(Float64, data["alpha"]["main"])
          c0 = typeof(data["c0Value"]["main"])==String ? parse(Float64, data["c0Value"]["main"]) : convert(Float64, data["c0Value"]["main"])
          c1 = typeof(data["c1Value"]["main"])==String ? parse(Float64, data["c1Value"]["main"]) : convert(Float64, data["c1Value"]["main"])
          c2 = typeof(data["c2Value"]["main"])==String ? parse(Float64, data["c2Value"]["main"]) : convert(Float64, data["c2Value"]["main"])
          c3 = typeof(data["c3Value"]["main"])==String ? parse(Float64, data["c3Value"]["main"]) : convert(Float64, data["c3Value"]["main"])
          eta_q = typeof(data["etaq"]["main"])==String ? parse(Float64, data["etaq"]["main"]) : convert(Float64, data["etaq"]["main"])
          psi = typeof(data["psi"]["main"])==String ? parse(Float64, data["psi"]["main"]) : convert(Float64, data["psi"]["main"])
          omega = typeof(data["omega"]["main"])==String ? parse(Float64, data["omega"]["main"]) : convert(Float64, data["omega"]["main"])
          etrap = typeof(data["etrap"]["main"])==String ? parse(Float64, data["etrap"]["main"]) : convert(Float64, data["etrap"]["main"])
          
        # solve diffusion
          he_est = COAST.rdaam_forward_diffusion(alpha,c0,c1,c2,c3,rmr0,eta_q,L_dist*1e-4,psi,omega,etrap*1e3,COAST.Rjoules,Ea*1e3,log10D0L_a2_rdaam,n_iter,
          U238_mol,U238_V,U235_mol,U235_V,Th232_mol,Th232_V,L*1e-6,reverse(tSeriesRun)...,reverse(TSeriesRun[1:end-1])...)
        end
        # find date via newton iterations
        t_val = he_conc_to_date(U238_mol,U235_mol,Th232_mol,he_est)
        t_Ma[i,j] = t_val/(1e6*COAST.sec_in_yrs)
      end
    end

    print(names_out)
    # convert time values so results won't be in seconds
    if occursin("time",names_out[1])
      x["run"] /= sec_in_Ma
    end
    if (haskey(z,"min"))
      if occursin("time",names_out[2])
        z["run"] /= sec_in_Ma
      end
    end

    if occursin("temp",names_out[1])
      x["run"] = x["run"].-c_to_kelvin
    end
    if (haskey(z,"min"))
      if occursin("temp",names_out[2])
        z["run"] = z["run"].-c_to_kelvin
      end
    end

    # return depending on whether X-Y or X-Y-Z plot
    if (haskey(z,"min"))
      outstring = [t_Ma, x["run"], z["run"], names_out]
    else
      outstring = [t_Ma, x["run"], names_out]
    end
    return outstring


  ####
  # GLOBAL SENSITIVITY
  # NO ZONATION
  elseif function_to_COAST=="global_sensitivity"
    samples = payload["samples"]
    n_vars2vary = length(samples)
    data = payload["data"]
    diffusion_model = payload["model"]

    # convert data from weird JSON3 dictionary format to standard dict
    data=JSON3dict_to_dict(data)

    n_run = typeof(data["numberX"])==String ? parse(Int64, data["numberX"]) : convert(Int64, data["numberX"])
    tSeries = data["tSeries"]
    TSeries = data["TSeries"]
    print("TSeries is: $TSeries\n")
    print("tSeries is: $tSeries\n")
    tSeries = tSeries*3.1558e7*1e6
    TSeries = TSeries.+ 273.15
    lentSeries = length(tSeries)

    data_to_run = Dict{String, Float64}()

    data_to_run["U238"] = typeof(data["U238"]["main"])==String ? parse(Float64, data["U238"]["main"]) : convert(Float64, data["U238"]["main"])
    data_to_run["Th232"] = typeof(data["Th232"]["main"])==String ? parse(Float64, data["Th232"]["main"]) : convert(Float64, data["Th232"]["main"])
    data_to_run["Ea"] = typeof(data["Ea"]["main"])==String ? parse(Float64, data["Ea"]["main"]) : convert(Float64, data["Ea"]["main"])
    data_to_run["rad"] = typeof(data["rad"]["main"])==String ? parse(Float64, data["rad"]["main"]) : convert(Float64, data["rad"]["main"])
    data_to_run["D0"] = typeof(data["D0"]["main"])==String ? parse(Float64, data["D0"]["main"]) : convert(Float64, data["D0"]["main"])
    
    # diffusion model-specific conversion
    if (diffusion_model=="flowers09")
      data_to_run["Letch"] = typeof(data["Letch"]["main"])==String ? parse(Float64, data["Letch"]["main"]) : convert(Float64, data["Letch"]["main"])
      data_to_run["rmr0"] = typeof(data["rmr0"]["main"])==String ? parse(Float64, data["rmr0"]["main"]) : convert(Float64, data["rmr0"]["main"])
      data_to_run["alpha"] = typeof(data["alpha"]["main"])==String ? parse(Float64, data["alpha"]["main"]) : convert(Float64, data["alpha"]["main"])
      data_to_run["c0Value"] = typeof(data["c0Value"]["main"])==String ? parse(Float64, data["c0Value"]["main"]) : convert(Float64, data["c0Value"]["main"])
      data_to_run["c1Value"] = typeof(data["c1Value"]["main"])==String ? parse(Float64, data["c1Value"]["main"]) : convert(Float64, data["c1Value"]["main"])
      data_to_run["c2Value"] = typeof(data["c2Value"]["main"])==String ? parse(Float64, data["c2Value"]["main"]) : convert(Float64, data["c2Value"]["main"])
      data_to_run["c3Value"] = typeof(data["c3Value"]["main"])==String ? parse(Float64, data["c3Value"]["main"]) : convert(Float64, data["c3Value"]["main"])
      data_to_run["etaq"] = typeof(data["etaq"]["main"])==String ? parse(Float64, data["etaq"]["main"]) : convert(Float64, data["etaq"]["main"])
      data_to_run["psi"] = typeof(data["psi"]["main"])==String ? parse(Float64, data["psi"]["main"]) : convert(Float64, data["psi"]["main"])
      data_to_run["omega"] = typeof(data["omega"]["main"])==String ? parse(Float64, data["omega"]["main"]) : convert(Float64, data["omega"]["main"])
      data_to_run["etrap"] = typeof(data["etrap"]["main"])==String ? parse(Float64, data["etrap"]["main"]) : convert(Float64, data["etrap"]["main"])
    end

    n_time_seg_subsegs = 20
    n_iter = 50 # for diffusion model
    date_Ma = zeros(Float64,n_run)
    for i=1:n_run
      for j=1:n_vars2vary
        key = payload["key_list"][j]     
        if occursin("tData", key)
          tData_ind = parse(Int64,key[6])+1
          tSeries[tData_ind] = samples[j][i]*3.1558e13 # correct from javascript indexing
        elseif occursin("TData", key)
          TData_ind = parse(Int64,key[6])+1 # jscript is zero indexed
          TSeries[TData_ind] = samples[j][i].+273.15
        else
          data[key]["main"] = samples[j][i]
        end
      end
      # javascript arrays are not necessarily sorted
      print("pre-sorted t is: $tSeries \n")
      print("pre-sorted T is: $TSeries for i = $i\n")

      idSort = sortperm(tSeries)
      tSeries = tSeries[idSort]
      TSeries = TSeries[idSort]

      tSeriesRun = Float64[]
      TSeriesRun = Float64[]
      
      for ind in 1:lentSeries
        if ind<lentSeries
          if isempty(tSeriesRun)
            tSeriesRun = vcat(tSeriesRun,LinRange(tSeries[ind], tSeries[ind+1], n_time_seg_subsegs))
            TSeriesRun = vcat(TSeriesRun,LinRange(TSeries[ind], TSeries[ind+1], n_time_seg_subsegs))
          else
            tSectionNew = LinRange(tSeries[ind], tSeries[ind+1], n_time_seg_subsegs)
            TSectionNew = LinRange(TSeries[ind], TSeries[ind+1], n_time_seg_subsegs)
            tSeriesRun = vcat(tSeriesRun,tSectionNew[2:end])
            TSeriesRun = vcat(TSeriesRun,TSectionNew[2:end])              
          end
        end
      end

      print("t is: $tSeries \n")
      print("T is: $TSeries for i = $i\n")

      # conversion
      U238 = typeof(data["U238"]["main"])==String ? parse(Float64, data["U238"]["main"]) : convert(Float64, data["U238"]["main"])
      Th232 = typeof(data["Th232"]["main"])==String ? parse(Float64, data["Th232"]["main"]) : convert(Float64, data["Th232"]["main"])
      Ea = typeof(data["Ea"]["main"])==String ? parse(Float64, data["Ea"]["main"]) : convert(Float64, data["Ea"]["main"])
      L = typeof(data["rad"]["main"])==String ? parse(Float64, data["rad"]["main"]) : convert(Float64, data["rad"]["main"])
      D0 = typeof(data["D0"]["main"])==String ? parse(Float64, data["D0"]["main"]) : convert(Float64, data["D0"]["main"])
      
      L2 = 60

      print("U238 concentration is: $U238 \n")
      print("Th232 concentration is: $Th232 \n")
      log10D0L_a2_rdaam = log10(exp(D0)*L^2/L2^2)
      
      # diffusion model-specific conversion
      if (diffusion_model=="flowers09")
        (U238_V,U235_V,Th232_V,U238_mol,U235_mol,Th232_mol
        )= conc_to_atoms_per_volume(U238*1e-6,Th232*1e-6)
        L_dist = typeof(data["Letch"]["main"])==String ? parse(Float64, data["Letch"]["main"]) : convert(Float64, data["Letch"]["main"])
        rmr0 = typeof(data["rmr0"]["main"])==String ? parse(Float64, data["rmr0"]["main"]) : convert(Float64, data["rmr0"]["main"])
        alpha = typeof(data["alpha"]["main"])==String ? parse(Float64, data["alpha"]["main"]) : convert(Float64, data["alpha"]["main"])
        c0 = typeof(data["c0Value"]["main"])==String ? parse(Float64, data["c0Value"]["main"]) : convert(Float64, data["c0Value"]["main"])
        c1 = typeof(data["c1Value"]["main"])==String ? parse(Float64, data["c1Value"]["main"]) : convert(Float64, data["c1Value"]["main"])
        c2 = typeof(data["c2Value"]["main"])==String ? parse(Float64, data["c2Value"]["main"]) : convert(Float64, data["c2Value"]["main"])
        c3 = typeof(data["c3Value"]["main"])==String ? parse(Float64, data["c3Value"]["main"]) : convert(Float64, data["c3Value"]["main"])
        eta_q = typeof(data["etaq"]["main"])==String ? parse(Float64, data["etaq"]["main"]) : convert(Float64, data["etaq"]["main"])
        psi = typeof(data["psi"]["main"])==String ? parse(Float64, data["psi"]["main"]) : convert(Float64, data["psi"]["main"])
        omega = typeof(data["omega"]["main"])==String ? parse(Float64, data["omega"]["main"]) : convert(Float64, data["omega"]["main"])
        etrap = typeof(data["etrap"]["main"])==String ? parse(Float64, data["etrap"]["main"]) : convert(Float64, data["etrap"]["main"])
          
        he_est = COAST.rdaam_forward_diffusion(alpha,c0,c1,c2,c3,rmr0,eta_q,L_dist*1e-4,psi,omega,etrap*1e3,COAST.Rjoules,Ea*1e3,log10D0L_a2_rdaam,n_iter,
        U238_mol,U238_V,U235_mol,U235_V,Th232_mol,Th232_V,L*1e-6,reverse(tSeriesRun)...,reverse(TSeriesRun[1:end-1])...)
      end
      t_val = he_conc_to_date(U238_mol,U235_mol,Th232_mol,he_est)
      date_Ma[i] = t_val/(1e6*COAST.sec_in_yrs)

    end
    print(date_Ma)
    return date_Ma

  # single load run
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

# TYPE CONVERSION HELPER FUNCS
function JSON3dict_to_dict(data)
  data_new = Dict()
  for (key, value) in data
    if (typeof(value)==JSON3.Object{Base.CodeUnits{UInt8, String}, SubArray{UInt64, 1, Vector{UInt64}, Tuple{UnitRange{Int64}}, true}})
      value_new = Dict{String,Any}()
      for (nest_key, nest_value) in value
        value_new[string(nest_key)] = nest_value
      end
      value = deepcopy(value_new)
    end
    data_new[string(key)] = value
  end
  data = deepcopy(data_new)
  return data
end

# convert concentration to date using Newton iters 
function he_conc_to_date(U238_mol,U235_mol,Th232_mol,he_est)
  t_val = [1e15] # initial value
  for i=1:20 # tested this val (10 usually sufficient)
    f0 = (8*(U238_mol*exp(t_val[1]/COAST.τ38)-U238_mol)+
    7*(U235_mol*exp(t_val[1]/COAST.τ35)-U235_mol)+
    6*(Th232_mol*exp(t_val[1]/COAST.τ32)-Th232_mol)) - he_est
    f0_prime = 8*(U238_mol*exp(t_val[1]/COAST.τ38)/COAST.τ38)+7*(U235_mol*exp(t_val[1]/COAST.τ35)/COAST.τ35)+6*(Th232_mol*exp(t_val[1]/COAST.τ32)/COAST.τ32)
    t_val[1] = t_val[1] - f0/f0_prime
  end
  return t_val[1]
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