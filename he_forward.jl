# forward models of he diffusion
# define constants

const R_joules = 8.314 # gas constant
const sec_in_yrs = 3.1558e7
const lambda_f = 8.46e-17/sec_in_yrs
const lambda_38 = 1.55125 * 1e-10/sec_in_yrs
const lambda_32 = 4.9475*1e-11/sec_in_yrs
const tau38 = 1.0/lambda_38
const tau32 = 1.0/lambda_32

const Na = 6.022e23  # avogadro number
const atomic_mass_U238 = 238.050791  # g/mol


"""

Calculate radioactive ingrowth and diffusion of He4 using modified eqns
 from Meesters & Dunai, 2002 for single crystal.

# Arguments:
- `density::Float64`: the .
"""
function rdaam_forward_diffusion(density,n_iter,c0,c1,c2,c3,alpha,rmr0,U238_V,Th232_V,U238,
  Th232,E_L,L,T0,kappa,D0_L2,E_trap,omega_rho,psi_rho,eta_q,L_dist,t_and_T...)#::Tvv...) where {Tvv<:Real}

n_t = length(t_and_T)/2
n_t = ceil(Int64,n_t)
times = t_and_T[1:n_t]
T = t_and_T[n_t+1:end]
Tvv = eltype(T)

# preallocate
rho_r=0.0
erho_s=0.0
N_t_segs = length(T)+1
D0_rdaam = zeros(Tvv,N_t_segs+1)
F = zeros(Tvv,N_t_segs+1)
zeta = zeros(Tvv,N_t_segs+1)
dzeta = zeros(Tvv,N_t_segs+1)
dfdchi = zeros(Tvv,(N_t_segs-1))
a = 0.0

Th232_0 = Th232*(exp(lambda_32*times[1]))
U238_0 = U238*(exp(lambda_38*times[1])) # U238 is measured at present

# calculate apatite grain damage and annealing
for (ind,time_i) in enumerate(times)

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
    rho_v=(8/8)*U238_V*(exp(lambda_38*(time_i))-exp(lambda_38*(time_i-sec_in_yrs)))
    rho_v+=(6/8)*Th232_V*(exp(lambda_32*(time_i))-exp(lambda_32*(time_i-sec_in_yrs)))
  else
    rho_v=(8/8)*U238_V*(exp(lambda_38*(times[ind-1]))-exp(lambda_38*(time_i)))
    rho_v+=(6/8)*Th232_V*(exp(lambda_32*(times[ind-1]))-exp(lambda_32*(time_i)))
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
       F[ind] = -8*U238_0*tau38*exp(-times[ind]/tau38))

       #tau*(1.0-exp(-times[ind]/tau38))

       #



  end

  if (ind<N_t_segs+1) & (ind>1)
    dfdchi[ind-1]=(F[ind-1]-F[ind])/(dzeta[ind])
  end

end


uterm2 = 0.0
mu_n = 0.0

zeta_end = zeta[end-1]


uterm2 = fill_u_term2(L,n_iter,N_t_segs,F,dfdchi,dzeta,zeta,mu_n,uterm2,zeta_end)


uF = 8*(1/tau)*uterm2/pi

uF = uF/(pi*4/3) # [uF] = ppm - [He] @ modern day/after ingrowth
#zerpl = D0_rdaam[1]
#print("$uF \n")

return uF
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

function mod_constraints(T0,T::Tvv...) where {Tvv<:Real}

smooth_mat=Tridiagonal(ones(length(T)-1),-2*ones(length(T)),1*ones(length(T)-1))
smooth_measure = zeros(Tvv,length(T))
smooth_measure[1]=(T0-2*T[1]+T[2]).^2
smooth_measure[2:end-1] = (smooth_mat[2:end-1,:]*collect(T)).^2
smooth_tot = sum(smooth_measure)
return smooth_tot

end

function register_forward_model!(n_t_segs,model;
    diffusion_func=rdaam_forward_diffusion,ancillary_func=fill_u_term2)
n_T_segs = n_t_segs-1
  forward_model = Symbol(diffusion_func)
  helper_func = Symbol(ancillary_func)

  register(model,forward_model,22+n_T_segs+n_t_segs,diffusion_func,autodiff=true)
  register(model,helper_func,10,ancillary_func,autodiff=true)

  return nothing
end

function register_objective_function!(n_T_segs,model;model_constraints=mod_constraints,autodiff=true)
  model_constraints_sym = Symbol(model_constraints)
  register(model,model_constraints_sym,1+n_T_segs,model_constraints,autodiff=autodiff)

  return nothing
end

function set_objective_function!(model,T0,T)

@NLobjective(model,Min,mod_constraints(T0,T...))
return nothing

end
