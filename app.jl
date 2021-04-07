using JuMP
using COAST
using JSON3
using Genie
using Ipopt
using Genie.Router
using Genie.Requests
using Genie.Renderer.Html

# string to say hello to users
html_coast_introduction = """
    \n <p>COAST is a program for thermochronology sensitivity analysis and
     modeling.</p> \n <p>More information can be found on the official
    <a href="https://github.com/ryanstoner1/COAST.jl/">Github page.</a></p> 
"""

# allow cors headers because chrome complains about these otherwise
Genie.config.cors_headers["Access-Control-Allow-Methods"] ="GET,POST"

function launchServer(port)
   # configuration to make website happy
   Genie.config.run_as_server = true
   Genie.config.server_host = "0.0.0.0"
   Genie.config.server_port = port

  route("/model", method = POST) do
    # extract payload from front-end
    payload = jsonpayload()
    #print(payload)
    # run appropriate function(s)    
    output_string = parse_and_run_payload(payload)

    # make output a string to send back to front-end
    return Genie.Renderer.Json.json(output_string)    
  end

  # simple summary for website visits/GET requests
  route("/model") do
     html_coast_introduction
  end

  # create other page for testing purposes
  route_test_page_get_post(html_coast_introduction)

  Genie.AppServer.startup()
end

# function to run in COAST
function parse_and_run_payload(payload)
  function_to_COAST = payload["function_to_run"]

  if function_to_COAST == "zonation"
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
    distance = payload["distance"]
    outstring = zonation_n_times_forward(distance,L,n_t,Ea,D0,U38_Pb06,sigU38_Pb06,dr,tmax,tmin)
    return outstring
  end

  return "Passing JSON payload to COAST successful!"
end

function zonation_n_times_forward(distance,L,n_t,Ea,D0,U38_Pb06,sigU38_Pb06,dr,tmax,tmin)
  print("running_zonation_n_times_forward \n")
  tmax = parse(Float64,tmax)
  tmin = parse(Float64,tmin)
  nt  = parse(Int64,n_t)
  Ea = parse(Float64,Ea)
  D0 = parse(Float64,D0)
  dr = parse(Float64,dr)
  L = parse(Float64,L)
  distance = JSON3.read(distance, Vector{Float64})./1e6
  U38_Pb06 = 1.0./JSON3.read(U38_Pb06, Vector{Vector{Float64}})
  sigU38_Pb06 = 1.0./JSON3.read(sigU38_Pb06, Vector{Vector{Float64}})
  U238 = 30.0
  U235 = 0.0
  Th232 = 0.0
  nrad = round(Int,L/(dr))
  print(nrad,"\n")
  print(length(distance),"\n")
  print("$L \n")
  print("$U38_Pb06 \n")
  t= collect(LinRange(tmax*COAST.sec_in_yrs,tmin*COAST.sec_in_yrs,nt))
  nT = nt - 1
  T= collect(LinRange(700.0,700.0,nT))
  upper_bound_arr = (1200.0+273.0)*ones(nT)
  model = Model(Ipopt.Optimizer)
  JuMP.set_optimizer_attributes(model,"print_level"=>5,"tol"=>1e2,"linear_solver"=>"mumps","print_timing_statistics"=>"no")
  (Tset,set_dev) = define_variables!(nT,1,model,T,upper_bound=upper_bound_arr)
  register(model,Symbol(zonation_diffusion),7+nT+nt,zonation_diffusion,autodiff=true)
  register_objective_function!(nT,model)
  
  nradplus = round(Int,75.0*1e-6/dr)
  U38_Pb06 = vcat(U38_Pb06[end].*ones(nradplus-nrad),U38_Pb06)
  print("$U38_Pb06 \n")
  scaling = 1e7
  # for jj = 1:nrad
  #   constr1=@NLconstraint(model,[i = 1:1],(zonation_diffusion(Ea,D0,U238,0.0,0.0,L,nrad,t...,T...)-He_conc[i]*scaling)^2<=(0.01*He_conc[i]*scaling)^2)
  # end
    #set_objective_function!(model,Tset)
  
  ratio = zonation_diffusion(Ea,D0,U238,U235,Th232,L,nrad,tT...)
  return (n_t,Ea,ratio)
end


# test page for checking if site is live
# testing post and get requests
function route_test_page_get_post(html_coast_introduction)

    # simple message to say hi
    route("/") do
      html_coast_introduction
   end

   # use e.g. curl to test
   route("/", method = POST) do
     aa = jsonpayload()["name"]
     return Genie.Renderer.Json.json("Tested input: $(aa) ")
   end
end


launchServer(8000) # run if running locally
#launchServer(parse(Int, ARGS[1])) # run from dokku or heroku

