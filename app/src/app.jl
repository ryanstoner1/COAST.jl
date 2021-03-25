using Genie
using Genie.Router
using Genie.Requests # added
Genie.config.cors_headers["Access-Control-Allow-Methods"] ="GET,POST"
using JSON

function launchServer(port)

   Genie.config.run_as_server = true
   Genie.config.server_host = "0.0.0.0"
   Genie.config.server_port = port

   print("port set to $(port)")

   route("/") do
       "Hi there! COAST"
   end
   route("/", method = POST) do
     #@show jsonpayload()
     #@show rawpayload()
     aa = jsonpayload()["name"]
     ab = jsonpayload()["lastName"]
     return Genie.Renderer.Json.json("Mr.$(aa) $(ab) ")
     #return JSON.json("Mr.$(aa) $(ab) ")
   end
   Genie.AppServer.startup()
end

# using Genie
# using Genie.Router
# using Genie.Requests
# using Genie.Renderer.Json
# Genie.config.cors_headers["Access-Control-Allow-Methods"] ="GET,POST"
#
# function launchServer(port)
#
#     Genie.config.run_as_server = true
#     Genie.config.server_host = "0.0.0.0"
#     Genie.config.server_port = port
#
#     println("port set to $(port)")
#
#     route("/") do
#         "COAST: response from COAST"
#     end
#
# route("/", method = POST) do
#   @show jsonpayload()
#   @show rawpayload()
#   aa = jsonpayload()["name"]
#   ab = jsonpayload()["lastName"]
#
#   print("Mr.$(aa) $(ab) ")
#   json("Mr.$(aa) $(ab) ")
# end
#
#     Genie.AppServer.startup()
# end
#launchServer(8000) # run if running locally
launchServer(parse(Int, ARGS[1])) # run from dokku or heroku
