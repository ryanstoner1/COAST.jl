"""
JuMP interaction
"""


"""
Pass JuMP model setup to Ipopt - a nonlinear solver

See Ipopt documentation
"""
function initialize_JuMP_model(linear_solver,print_level=5,tol=1e-3,max_iter=1000,
  acceptable_constr_viol_tol=0.001)


model = Model(() -> Ipopt.Optimizer(print_level=print_level,tol=tol,max_iter=max_iter,
  acceptable_constr_viol_tol=acceptable_constr_viol_tol,linear_solver=linear_solver))
return model

end
"""

Let JuMP know about variables

"""
function register_variables(n_t_segs,n_data_pts,model,lower_bound=273.0,upper_bound=410.0,T0=385.0,autodiff=true)
  T = @variable(model, [i=1:n_t_segs],base_name="T",lower_bound=lower_bound,
    upper_bound=map(constrain_upper,upper_bound,i,n_t_segs),
    start=map(constraint_func,i,upper_bound,lower_bound,0.9,0.1))
  @variable(model, T0==385.0)
  @NLparameter(model, set_dev[i = 1:n_data_pts] == 0.0 * i)
return T,T0,set_dev
end

"""
Let JuMP know about constraints
"""
function rdaam_define_constraints(model,set_dev,set_val,L,T0,T,U238,U238_V;
   n_iter=50,E_L=122.3*1e3,c0=0.39528,c1=0.01073,c2=-65.12969,c3=-7.91715,
   alpha=0.04672,rmr0=0.79,D0_L2=16865.0,E_trap=34*1e3,omega_rho=1e-22,
   psi_rho=1e-13,L_dist=8.1*1e-4,eta_q=0.91)

kappa = 1.04-rmr0
kwargs_rdaam = (E_L,c0,c1,c2,c3,alpha,rmr0,D0_L2,E_trap,omega_rho,psi_rho,
                L_dist,eta_q)

for j in eachindex(U238)
    if j<n_constraints
      my_constr = @NLconstraint(
        model, [i = j:j],(
        rdaam_forward_diffusion(density,U238_V[j],0.0,U238[j],0.0,L,
          T0,times,n_iter,kappa,kwargs_rdaam...,
        T...)-set_val[j]+set_dev[j])^2<=(set_val[j]*0.005)^2)

    elseif j==n_constraints
      my_constr = @NLconstraint(
        model, [i = j:j],(
        rdaam_forward_diffusion(density,U238_V[j],0.0,U238[j],0.0,L,
          T0,times,n_iter,kappa,kwargs_rdaam...,T...)-set_val[j]+set_dev[j])==(set_val[j]*0.0))

    end
end



return kwargs_rdaam
end

"""
```julia
constraint_func(x,upper,lower,init_scaling_young,init_scaling_old)
```
"""
function constraint_func(x,upper,lower,init_scaling_young,init_scaling_old)

randval = rand(1)[1]

if x>20
x = (upper-lower)*init_scaling_young+lower
elseif x<=20
x = (upper-lower).*init_scaling_old+lower
end

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
