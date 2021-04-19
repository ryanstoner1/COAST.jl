
using Pkg
Pkg.activate(pwd())
include("COAST.jl")
using .COAST

progress_test = [0.0]
COAST.App.launchServer(progress_test,parse(Int, ARGS[1]))

