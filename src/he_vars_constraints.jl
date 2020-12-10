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

#
#
# """
# Let JuMP know about constraints
# """
# function define_constraints(set_dev,set_val,E_L,L,T0,T,c0,c1,c2,alpha,rmr0,
#   n_iter,U238,U238_V,n_iter=50)
#
# n_constraints = length(U238)
# for j in 1:n_constraints
#   if j<n_constraints
#     my_constr2 = @NLconstraint(model2, [i = j:j],(rdaam_forward_diffusion(density,n_iter,c0,
#       c1,c2,c3,alpha,rmr0,U238_V[j],0.0,U238[j],0.0,E_L,L,T0,kappa,T...
#       )-set_val[j]+set_dev[j])^2<=(set_val[j]*0.005)^2)
#
#   elseif j==n_constraints
#     my_constr2 = @NLconstraint(model2, [i = j:j],(rdaam_forward_diffusion(density,n_iter,c0,
#       c1,c2,c3,alpha,rmr0,U238_V[j],0.0,U238[j],0.0,E_L,L,T0,kappa,T...
#       )-set_val[j]+set_dev[j])==(set_val[j]*0.0))
#
#   end
#
# end
#
# return nothing
# end

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
#print("snuggleflerp \n")
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
