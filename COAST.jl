"""
Constrained Optimization and Sensitivity for Thermochronology
R. Stoner
2020
"""
module COAST

## Dependencies
using Ipopt
using JuMP
using LinearAlgebra
using PyCall
using Random

## Helium diffusion
include("he_preprocessing.jl")
include("he_vars_constraints.jl")
include("he_forward.jl")

# funcs for unit testing
export loaded_COAST

# preprocessing
export decompose_eu

# treating setup
export register_variables, constraint_func, constrain_upper#, define_constraints

# forward model
export rdaam_forward_diffusion, register_forward_JuMP

## testing funcs
"""
Export checking
"""
function loaded_COAST()
  load_success = true
  return load_success
end

end
