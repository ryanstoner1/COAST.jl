## wrappers for JuMP

function register_forward_model!(n_t_segs,model;
    diffusion_func=rdaam_forward_diffusion,ancillary_func=fill_u_term)
  n_T_segs = n_t_segs-1
  forward_model = Symbol(diffusion_func)
  helper_func = Symbol(ancillary_func)
  register(model,forward_model,22+n_T_segs+n_t_segs,diffusion_func,autodiff=true)
  register(model,helper_func,10,ancillary_func,autodiff=true)

  return true
end

function register_objective_function!(n_T_segs,model;model_constraints=mod_constraints,autodiff=true)
  model_constraints_sym = Symbol(model_constraints)
  register(model,model_constraints_sym,n_T_segs,model_constraints,autodiff=autodiff)

  return nothing
end

function set_objective_function!(model,T0,T)

@NLobjective(model,Min,mod_constraints(T0,T...))
return nothing

end
