module Zoned

include("create_zonation_funcs.jl")
include("zonation_forward.jl")
include("zonation_objective.jl")

# zonation Crank-Nicolson
export smooth_zon_objective, create_constraint_zon, create_jac_constraint, grad_smooth_zon_objective # main zonation funcs
export create_zon_loglike_objective, create_grad_loglike_objective
export create_jac_constraint_monotonic_cooling, create_constraint_monotonic_cooling
export decrease_constraint, jac_decrease_constraint

# objective
export decreasing_zon_objective, grad_decreasing_zon_objective
export grad_null_objective, null_objective
export create_decreasing_objective, create_grad_decreasing_objective
export zonation_forward # zonation func for testing
export ind_dPb, ind_dPb_vec

end