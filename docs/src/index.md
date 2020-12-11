# COAST (Constrained Optimization And Sensitivity for Thermochronology)

Example workflow from Ault et al., (2009)
```julia

## grain-specific data
# define size, uranium content, helium content
L = 60e-6
n_data_pts = 3
density_ap = 3.20

U238 = LinRange(50e-6,70e-6,n_data_pts)
U238_V = ppm_to_atoms_per_volume.(U238,density=density_ap)
He_conc =  (1.6529243206117415e-7, 1.9848298668415973e-7,2.3176326334908023e-7)

## solver-specific data, time steps
# iterations
n_iter = 20.0
# time segments
n_t_segs = 31
n_T_segs = n_t_segs-1
times = LinRange(5.0e6*sec_in_yrs,0.01e6*sec_in_yrs,n_t_segs)
times = Tuple(times) # important!
## setup model
model2 = initialize_JuMP_model("mumps",print_level=5)

## define variables and register functions to use
(T,T0,set_dev) = define_variables!(n_T_segs,n_data_pts,model2)
register_forward_model!(n_t_segs,model2)

## define constraints, set objective functions

register_objective_function!(n_T_segs,model2)
rdaam_define_constraints(model2,density_ap,set_dev,He_conc,L,times,T0,T,U238[1:2],U238_V[1:2])
set_objective_function!(model2,T0,T)
```
