"""
JuMP interaction
"""


"""
Pass JuMP model setup to Ipopt - a nonlinear solver

See Ipopt documentation
"""
function initialize_JuMP_model(linear_solver;print_level=5,tol=1e-3,max_iter=1000,
  constr_viol_tol=1e-3,obj_scaling_factor=1.0)


# model = Model(() -> Ipopt.Optimizer(print_level=print_level,tol=tol,max_iter=max_iter,
#   acceptable_constr_viol_tol=acceptable_constr_viol_tol,linear_solver=linear_solver))

model = Model(Ipopt.Optimizer)
JuMP.set_optimizer_attributes(model,"print_level"=>print_level,"tol"=>tol,
  "max_iter"=>max_iter,"constr_viol_tol"=>constr_viol_tol,"linear_solver"=>linear_solver,
  "obj_scaling_factor"=>obj_scaling_factor)
return model

end
"""

Let JuMP know about variables

"""
function define_variables!(n_t_segs,n_data_pts,model,start_point_frac;upper_bound=410.0,lower_bound=273.0,T0=385.0,autodiff=true)
  if isa(upper_bound,Number)
  T = @variable(model, [i=1:n_t_segs],base_name="T",lower_bound=lower_bound,
    upper_bound=map(constrain_upper,upper_bound,i,n_t_segs),
    start=map(constraint_func,i,maximum(upper_bound),maximum(lower_bound),start_point_frac[i]))
  elseif isa(upper_bound,Array)
    T = @variable(model, [i=1:n_t_segs],base_name="T",lower_bound=lower_bound[i],
      upper_bound=map(constrain_upper,upper_bound[i],i,n_t_segs),
      start=map(constraint_func,i,maximum(upper_bound),maximum(lower_bound),start_point_frac[i]))
  end

  @NLparameter(model, set_dev[i = 1:n_data_pts] == 0.0 * i)
return T,set_dev
end

"""
Let JuMP know about constraints
"""
function rdaam_define_constraints(model,density,set_dev,set_val,L,times,T,U238,U235,Th232,U238_V,U235_V,Th232_V;
   n_iter=20.0,E_L=122.3*1e3,c0=0.39528,c1=0.01073,c2=-65.12969,c3=-7.91715,
   alpha=0.04672,rmr0=0.79,logD0_a2=log10(exp(9.733)),E_trap=34*1e3,omega=1e-22,
   psi=1e-13,L_dist=8.1*1e-4,eta_q=0.91,R=Rjoules)
n_data_constraints=length(U238)
kappa = 1.04-rmr0

for j in eachindex(U238)
    if (j<n_data_constraints) || (n_data_constraints==1)
      my_constr = @NLconstraint(model, [i = j:j],(rdaam_forward_diffusion(
                  alpha,c0,c1,c2,c3,rmr0,eta_q,L_dist,psi,omega,E_trap,
                  R,E_L,logD0_a2,n_iter,U238[i],U238_V[i],U235[i],U235_V[i],
                  Th232[i],Th232_V[i],L,times...,T...
                  )-set_val[i]+set_dev[i])^2<=(set_val[i]*0.005)^2)


    elseif (j==n_data_constraints)
    my_constr2 = @NLconstraint(model, [i = j:j],(rdaam_forward_diffusion(
                   alpha,c0,c1,c2,c3,rmr0,eta_q,L_dist,psi,omega,E_trap,
                   R,E_L,logD0_a2,n_iter,U238[i],U238_V[i],U235[i],U235_V[i],Th232[i],Th232_V[i],L,
                   times...,T...)-set_val[i]+set_dev[i])==(set_val[i]*0.0))
    end
    return my_constr
end



return nothing
end

"""
```julia
constraint_func(x,upper,lower,init_scaling_young,init_scaling_old)
```
"""
function constraint_func(ii,upper,lower,scaling_frac)

#randval = rand(1)[1]
x = (upper-lower)*scaling_frac+lower

return x
end

function constrain_upper(x,i,max_i)
x_orig = copy(x)
if i==max_i
  x=273.0
else
  x=x_orig
end

return x
end
