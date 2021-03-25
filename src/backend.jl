using Genie
using JSON
using Genie.Router
using Genie.Requests
using Genie.Renderer
Genie.config.cors_headers["Access-Control-Allow-Methods"] ="GET,POST"
function launchServer(port)

    Genie.config.run_as_server = true
    Genie.config.server_host = "0.0.0.0"
    Genie.config.server_port = port

    println("port set to $(port)")

    route("/") do
        "COAST: response from COAST"
    end

route("/", method = POST) do
  @show jsonpayload()
  @show rawpayload()
  aa = jsonpayload()["name"]
  ab = jsonpayload()["lastName"]

  return JSON.json("Mr.$(aa) $(ab) ")

end

    Genie.AppServer.startup()
end
launchServer(8000) # run if running locally
#launchServer(parse(Int, ARGS[1])) # run from dokku or heroku
