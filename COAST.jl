"""
Constrained Optimization and Sensitivity for Thermochronology
R. Stoner
11/2020
"""
module COAST

using Ipopt
using JuMP
using LinearAlgebra
using PyCall
using Random

## Helium diffusion
include("he_preprocessing.jl")
include("he_vars_constraints.jl")
include("he_forward.jl")

# present
export cur_path

# preprocessing
export decompose_eu

# treating setup
export register_variables#, define_constraints

# forward
export rdaam_forward_diffusion, register_forward_JuMP


##
"""
see which path COAST sees
"""
function cur_path()
  current_path = pwd()
  print("current path COAST sees is: $current_path \n")
  return current_path
end

# end of module
end
