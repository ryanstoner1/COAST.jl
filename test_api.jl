using Genie, Genie.Router, Genie.Requests, Genie.Renderer.Json
using HTTP
route("/jsonpayload", method = POST) do
  @show jsonpayload()
  @show rawpayload()

  json("Hello $(jsonpayload()["name"])")
  json("Hello $(jsonpayload()["hobby"])")
end

route("/") do
  "Hello! This is a website for thermochronology analysis."
end

up()
