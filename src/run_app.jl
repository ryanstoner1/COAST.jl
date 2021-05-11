
using Pkg
Pkg.activate(pwd())
include("COAST.jl")
using .COAST

progress_test = [0.0]
try
    COAST.App.launchServer(progress_test,parse(Int, ARGS[1]))
catch e
    print("Not on server . . . attempting to start locally \n")
    COAST.App.launchServer(progress_test,8000)
end

