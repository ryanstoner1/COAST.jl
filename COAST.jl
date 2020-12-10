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
include("he_forward.jl")
include("he_vars_constraints.jl")

# funcs for unit testing
export loaded_COAST

# preprocessing
export decompose_eu, ppm_to_atoms_per_volume

# treating setup
export register_variables, constraint_func, constrain_upper
export rdaam_define_constraints

# forward model
export rdaam_forward_diffusion, initialize_JuMP_model
export register_forward_model!, register_objective_function!
export fill_u_term2

## testing funcs
"""
Export checking
"""
function loaded_COAST()
  load_success = true
  return load_success
end

end
