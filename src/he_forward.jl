# forward models of he diffusion
# define constants

const Rjoules = 8.314 # gas constant
const sec_in_yrs = 3.1558e7
const lambda_f = 8.46e-17/sec_in_yrs
const lambda_38 = 1.55125 * 1e-10/sec_in_yrs
const lambda_35 = 9.8584*1e-10/sec_in_yrs
const lambda_32 = 4.9475*1e-11/sec_in_yrs
const τ38 = 1.0./lambda_38
const τ35 = 1.0./lambda_35
const τ32 = 1.0./lambda_32

const Na = 6.022e23  # avogadro number
const atomic_mass_U235 = 235.04393 # g/mol
const atomic_mass_U238 = 238.050791  # g/mol
const atomic_mass_Th232 = 232.03805  # g/mol, CIAAW value



"""

Calculate radioactive ingrowth and diffusion of He4 using modified eqns
 from Meesters & Dunai, 2002 for single crystal.

# Arguments:
- `density::Float64`: the .
"""
function rdaam_forward_diffusion(alpha,c0,c1,c2,c3,rmr0,eta_q,L_dist,psi,omega,Etrap,
  R,Ea,logD0_a2,n_iter,U238,U238_V,U235,U235_V,Th232,Th232_V,L,times,
  T...)

  kappa = 1.04 - rmr0
  rdaam2nd_root = 0.5274 # cutoff bellow which rho_r values can be negative
  rdaam2nd_root_cutoff = (rdaam2nd_root^(1/kappa))*(1-rmr0)+rmr0 # also prevents
  # square root term from being negative


  # diffusivity mod

  # preallocate
  (t_equiv,N_t_segs,e_rho_s,rcb2,rho_r,D0,F,zeta,dzeta,dfdchi) = preallocate_diff_data(T) # 1st arg is only for rad dam



  n_times = length(times)
  dt_equiv = 0.0
  for rev_ind in eachindex(times) # present to past
    if rev_ind>1
        t_dam = times[n_times-rev_ind+1]-times[n_times-rev_ind+2]+dt_equiv
        rcb2_base = (c0 + c1*(log(t_dam)-c2)/(log((1.0/T[n_times-rev_ind+1]))-c3))
        rcb2_fill_val = ((rcb2_base^(1.0/alpha))+1)^(-1)
        for jj in 1:(n_times-rev_ind+1)
            rcb2[rev_ind+jj-1,jj+1] = rcb2_fill_val
            if rcb2[rev_ind+jj-1,jj+1]>= rdaam2nd_root_cutoff
                rho_r[rev_ind+jj-1,jj+1] = ((rcb2_fill_val-rmr0)/(1.0-rmr0))^kappa
                rho_r_copy = copy(rho_r[rev_ind+jj-1,jj+1]) # otherwise if AND elseif

                if rho_r_copy>=0.765
                   rho_r[rev_ind+jj-1,jj+1] = 1.6*rho_r[rev_ind+jj-1,jj+1] - 0.6
                elseif rho_r_copy<0.765
                   rho_r[rev_ind+jj-1,jj+1] = 9.205*rho_r[rev_ind+jj-1,jj+1]^2 - 9.157*rho_r[rev_ind+jj-1,jj+1] + 2.269
                end
            end
        end
        # use concept of equivalent time
      if rev_ind<n_times
        dt_equiv = exp((((((1.0/rcb2[rev_ind,2])-1.0)^alpha-c0)*(log(1.0/T[n_times-rev_ind])-c3))/c1)+c2)
      end
    end
  end

U238_0 = U238*(exp(lambda_38*times[1])) # U238 is measured at present
U235_0 = U235*(exp(lambda_35*times[1])) # U238 is measured at present
Th232_0 = Th232*(exp(lambda_32*times[1])) # U238 is measured at present


  ## prep diffusivity input
  for ind in eachindex(times)
       if ind>1
         update_damage!(times,eta_q,L_dist,U238_V,U235_V,Th232_V,e_rho_s,ind,rho_r)
       end



      # ## tested
      F[ind] = 8*(U238_0)*(-exp(-times[ind]/τ38))
      F[ind] += 7*(U235_0)*(-exp(-times[ind]/τ35))
      F[ind] += 6*(Th232_0)*(-exp(-times[ind]/τ32))
      if ind>1
        damage_mod_term = ((psi*e_rho_s[ind] + omega*e_rho_s[ind]^3)*exp(Etrap/(R*T[ind-1])))+1
        D0[ind] = arrhenius(L,T[ind-1],R,Ea,logD0_a2)/damage_mod_term
        dzeta_val = times[ind-1]-times[ind]
        dzeta[ind] = (D0[ind-1]+D0[ind])*(times[ind-1]-times[ind])/2
        zeta[ind] = zeta[ind-1]+dzeta[ind]


      else
        damage_mod_term = ((psi*e_rho_s[ind] + omega*e_rho_s[ind]^3)*exp(Etrap/(R*T[1])))+1
        D0[ind] = arrhenius(L,T[1],R,Ea,logD0_a2)/damage_mod_term
      end

      if (ind<N_t_segs+1) & (ind>1)
         dfdchi[ind-1]=(F[ind-1]-F[ind])/(dzeta[ind])
      end

    end

   zeta_end = zeta[end]

    uterm = fill_u_term(L,n_iter,N_t_segs,F,dfdchi,dzeta,zeta,zeta_end)


    uF = uterm*(8)/pi
    uF = (uF/(pi*4/3))

     return uF

end
# end rdaam

## calc new damage
function update_damage!(times,eta_q,L_dist,U238_V,U235_V,Th232_V,e_rho_s,ind,rho_r_final)

  dt = times[ind-1]-times[ind]

  rho_v = (8/8)*U238_V*(exp(lambda_38*times[ind-1])-exp(lambda_38*times[ind]))
  rho_v += (7/8)*U235_V*(exp(lambda_35*times[ind-1])-exp(lambda_35*times[ind]))
  rho_v += (6/8)*Th232_V*(exp(lambda_32*times[ind-1])-exp(lambda_32*times[ind]))

  e_rho_s[ind]= 1.0*rho_v*sum(rho_r_final[ind,:])*eta_q*L_dist*lambda_f/lambda_38

  return nothing
end

function arrhenius(L,T,R,Ea,logD0_a2)

  D = 10^(logD0_a2)*L^2.0.*exp(-Ea./(R*T))

  return D
end

function fill_u_term(L,n_iter,N_t_segs,F,dfdchi,dzeta,zeta,zeta_end)
  uterm = 0.0
  mu_n = 0.0
  for n in 1:n_iter
          utermbase = 0.0
          mu_n = (pi/(L))^2*n^2
          for j in 1:(N_t_segs-1)

             utermbase+= dfdchi[j]*(exp(-mu_n*(zeta_end-zeta[j+1]))-exp(-mu_n*(zeta_end-zeta[j])))

          end
          uterm += (1/mu_n)*(1/(n*n))*utermbase

  end
  return uterm
end

function preallocate_diff_data(T)

  Tvv = eltype(T)
  N_t_segs = length(T)+1
  e_rho_s= zeros(Tvv,N_t_segs)
  t_equiv = zeros(Tvv,N_t_segs)
  D0 = zeros(Tvv,N_t_segs)
  F = zeros(Tvv,N_t_segs)
  zeta = zeros(Tvv,N_t_segs)
  dzeta = zeros(Tvv,N_t_segs)
  dfdchi = zeros(Tvv,(N_t_segs-1))
  rcb2 = zeros(Tvv,(N_t_segs,N_t_segs))
  rho_r = zeros(Tvv,(N_t_segs,N_t_segs))

  return t_equiv,N_t_segs,e_rho_s,rcb2,rho_r,D0,F,zeta,dzeta,dfdchi
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
  register(model,model_constraints_sym,1+n_T_segs,model_constraints,autodiff=autodiff)

  return nothing
end

function set_objective_function!(model,T0,T)

@NLobjective(model,Min,mod_constraints(T0,T...))
return nothing

end
