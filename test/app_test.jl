using Pkg
Pkg.activate(pwd())
using Revise
using COAST
using JuMP
using Test


ENV["JULIA_SHELL"]="/bin/bash"
@testset "COAST.jl" begin
    @test loaded_COAST()==true
end

@testset "app.jl" begin

    progress_test = [0.0]
    COAST.App.launchServer(progress_test,8040)
    
end