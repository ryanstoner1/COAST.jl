

module App

using JuMP
using JSON3
using Genie
using Ipopt
using Genie.Router
using Genie.Requests
using Genie.Renderer.Html

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


# test page for checking if site is live
# testing post and get requests
function route_test_page_get_post!(progress_test,html_coast_introduction)



  # simple message to say hi
  route("/") do
      print("Run get script COAST \n")
      html_coast_introduction
   end

   # use e.g. curl to test
   route("/", method = POST) do
     aa = jsonpayload()["name"]
     print("testing progress script! \n")
     progress_test[1] += 1.0
     return Genie.Renderer.Json.json("Tested input: $(aa) ")
   end

   # use e.g. curl to test
   route("/testpost", method = GET) do
    
    return "<p>Registered GET. Current progress is $(progress_test)%<p>"
  end

end

end # end module

# # run if running locally
#launchServer(parse(Int, ARGS[1])) # run from dokku or heroku

# if abspath(PROGRAM_FILE) == @__FILE__
  
#   print("running app!\n")
#   progress_test = [0.0]
#   App.launchServer(progress_test,8000)
# end