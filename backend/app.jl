using Genie
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

   Genie.config.run_as_server = true
   Genie.config.server_host = "0.0.0.0"
   Genie.config.server_port = port

  route("/model", method = POST) do
    # extract payload from front-end
    payload = jsonpayload()
    
    output_string = parse_and_run_payload(payload)

    # make output a string to send back to front-end
    return Genie.Renderer.Json.json(output_string)
     
  end

  route("/model") do
     html_coast_introduction
  end

  route_test_page_get_post(html_coast_introduction)

  Genie.AppServer.startup()
end

# function to run in COAST
function parse_and_run_payload(payload)
  function_to_COAST = payload["function_to_run"]

  if function_to_COAST == "zonation"
    inputs = payload["zonation_inputs"]
    outstring = zonation_n_times_forward(inputs)
  end

  return "Passing JSON payload to COAST successful!"
end

function zonation_n_times_forward(zonation_inputs::String)
  return "yay!"
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

