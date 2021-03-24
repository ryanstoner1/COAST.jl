"""
Constrained Optimization and Sensitivity for Thermochronology
R. Stoner
2020

See documentation for detailed explanation of COAST
"""
module COAST

## Dependencies
using Ipopt
using JuMP
using PyCall
using Random
using LinearAlgebra
using Interpolations
using Distributions
## Helium diffusion
include("he_preprocessing.jl")
include("he_forward.jl")
include("he_vars_constraints.jl")
include("he_func_registration.jl")
include("FT_setup.jl")
include("FT_forward.jl")
# funcs for unit testing
export loaded_COAST

# preprocessing
export decompose_eu, ppm_to_atoms_per_volume, UTh_date_to_He_mols

# treating setup
export define_variables!, constraint_func, constrain_upper
export rdaam_define_constraints

# He forward model
export rdaam_forward_diffusion, jac_rdaam_forward_diffusion, initialize_JuMP_model
export register_forward_model!, register_objective_function!, set_objective_function!
export fill_u_term2

# FT forward model
export init_track_len
export FT_forward

# constants
export sec_in_yrs,τ38,τ35,τ32

## testing funcs

function loaded_COAST()
  load_success = true
  return load_success
end

end
