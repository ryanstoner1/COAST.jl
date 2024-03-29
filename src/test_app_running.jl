# test page for checking if site is live
# testing post and get requests
function route_test_page_get_post!(progress_test,html_coast_introduction)

    # allow cors headers because chrome complains about these otherwise
    Genie.config.cors_headers["Access-Control-Allow-Methods"] ="GET, POST"
    Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"

    # simple message to say hi
    route("/") do
        print("Run get script COAST \n")
        html_coast_introduction
     end
  
     # use e.g. curl to test
     route("/", method = POST) do
      print(jsonpayload())
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