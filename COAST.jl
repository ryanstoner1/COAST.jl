module COAST

using Ipopt
using JuMP
using LinearAlgebra
using PyCall
using Random

include("preprocessing_he_data.jl")

export COAST_loaded, forward_diffusion, cur_path, decompose_eu

"""
Constrained Optimization and Sensitivity for Thermochronology
R. Stoner
11/2020
"""

# define constants
const R_joules = 8.314 # gas constant
const sec_in_yrs = 3.1558e7
const lambda_f = 8.46e-17/sec_in_yrs
const lambda_38 = 1.55125 * 1e-10/sec_in_yrs
const lambda_32 = 4.9475*1e-11/sec_in_yrs
const tau = 1.0./lambda_38

"""
test functionality
"""
function COAST_loaded()
    return true
end

"""
see which path COAST sees
"""
function cur_path()
  current_path = pwd()
  print("current path COAST sees is: $current_path \n")
  return nothing
end
"""

Calculate radioactive ingrowth and diffusion of He4 using modified eqns
 from Meesters & Dunai, 2002 for single crystal.

# Arguments:
- `density::Float64`: the .
"""
function rdaam_forward_diffusion(density::Float64,n_iter,c0,c1,c2,c3,alpha,rmr0,
    U238_V,Th232_V,U238,Th232,E_L,L,T0,kappa,times,
    T::Tvv...; D0_L2=16865.0,E_trap=34*1e3,omega_rho = 1e-22,
    psi_rho = 1e-13,L_dist = 8.1*1e-4,eta_q = 0.91) where {Tvv<:Real}
  N_t_segs = length(T)+1
  @assert length(times)=N_t_segs

# initialize values
rho_r=0.0
erho_s=0.0
D0_rdaam = zeros(Tvv,N_t_segs+1) # type needs to be generalized for autodiff
F = zeros(Tvv,N_t_segs+1)
zeta = zeros(Tvv,N_t_segs+1)
dzeta = zeros(Tvv,N_t_segs+1)
dfdchi = zeros(Tvv,(N_t_segs-1))
a = 0.0

# calculate radiation damage, diffusivities
for (ind,time_i) in enumerate(times)
  # run a short, one year pass before to stabilize
  if ind>1
    a = ((c0+c1*(log(times[ind-1]-time_i)-c2)/(log(1/T[ind-1])-c3))^(1/alpha)+1)^(-1)
  else
    a = ((c0+c1*(log(sec_in_yrs)-c2)/(log(1/T0)-c3))^(1/alpha)+1)^(-1)
  end
  rclr=((a-rmr0)/(1-rmr0))^kappa
  if rclr>0.765
    rho_r = 1.6*rclr-0.6
  elseif rclr<=0.765
    rho_r = 9.205*rclr^2-9.157*rclr+2.269
  end

  if ind==1
    rho_v=(8/8)*U238_V*(exp(lambda_38*(time_i))-exp(lambda_38*(time_i-sec_in_yrs)))#+(6/8)*Th232_V*(exp(lambda_32*(time_i))-exp(lambda_32*(time_i-sec_in_yrs)))
  else
    rho_v=(8/8)*U238_V*(exp(lambda_38*(times[ind-1]))-exp(lambda_38*(time_i)))#+(6/8)*Th232_V*(exp(lambda_32*(times[ind-1]))-exp(lambda_32*(time_i)))
  end

  erho_s += eta_q*rho_v*rho_r*L_dist*lambda_f/lambda_38
  if ind==1
  D0_L2_rdaam = ((D0_L2*exp(-E_L./(R_joules*T0)))/
          (exp(E_trap/(R_joules*T0))*(psi_rho*erho_s+omega_rho*erho_s^3)+1))
  else
    D0_L2_rdaam = ((D0_L2*exp(-E_L/(R_joules*T[ind-1])))/
            (exp(E_trap/(R_joules*T[ind-1]))*(psi_rho*erho_s+omega_rho*erho_s^3)+1))
  end
  D0_rdaam[ind] = D0_L2_rdaam*L^2
  if ind>1
       dzeta_val = times[ind-1]-times[ind]
       #print("dzeta diff is: $dzeta_val \n")
       dzeta[ind] = (D0_rdaam[ind-1]+D0_rdaam[ind])*(times[ind-1]-times[ind])/2
       zeta[ind] = zeta[ind-1]+dzeta[ind]
       F[ind] = tau*(1.0-exp(-times[ind]/tau))



  end

  if (ind<N_t_segs+1) & (ind>1)
    dfdchi[ind-1]=(F[ind-1]-F[ind])/(dzeta[ind])
  end

end


uterm2 = 0.0
mu_n = 0.0

zeta_end = zeta[end-1]


uterm2 = fill_u_term2(L,n_iter,N_t_segs,F,dfdchi,dzeta,zeta,mu_n,uterm2,zeta_end)


U238_0 = U238*(exp(lambda_38*times[end])) # U238 is measured at present

uF = 8*(U238_0/tau)*uterm2*(8)/pi

uF = uF/(pi*4/3) # [uF] = ppm - [He] @ modern day/after ingrowth
#zerpl = D0_rdaam[1]
#print("$uF \n")

return (uF,uterm2)
end

function mod_constraints(T0,T::Tvv...) where {Tvv<:Real}

smooth_mat=Tridiagonal(ones(length(T)-1),-2*ones(length(T)),1*ones(length(T)-1))
smooth_measure = zeros(Tvv,length(T))
smooth_measure[1]=(T0-2*T[1]+T[2]).^2
smooth_measure[2:end-1] = (smooth_mat[2:end-1,:]*collect(T)).^2
smooth_tot = sum(smooth_measure)
return smooth_tot

end

function fill_u_term2(L,n_iter,N_t_segs,F,dfdchi,dzeta,zeta,mu_n,uterm2,zeta_end)
    mu_base = (pi/L)^2
  for n in 1:n_iter
          utermbase = 0.0
          mu_n = mu_base*n^2
          for j in 1:(N_t_segs-1)
               #dfdchi = (F[j+1]-F[j])/(dzeta[j+1])
               #if mu_n*(sum(dzeta[j+2:end]))>=1e-14
              utermbase+= dfdchi[j]*(exp(-mu_n*(zeta_end-zeta[j+1]))-exp(-mu_n*(zeta_end-zeta[j])))
           end

           uterm2 += (1/mu_n)*(1/(n*n))*utermbase #(-fx)*(exp(-t[]/tau)-exp(-k*(n*pi/L)^2*t))/(1-tau*k*(n*pi/L)^2) #cos.(n_term*r./L)*(1-exp(-t*k*(n_term/L)^2))*fn_t/(k*(n_term/L)^2)
  end
  return uterm2
end

function register_forward_JuMP(linear_solver,print_level=5,tol=1e-3,max_iter=1000,
  acceptable_constr_viol_tol=0.001)


model = Model(() -> Ipopt.Optimizer(print_level=print_level,tol=tol,max_iter=max_iter,
  acceptable_constr_viol_tol=acceptable_constr_viol_tol,linear_solver=linear_solver))
return model

end

# end of module
end
