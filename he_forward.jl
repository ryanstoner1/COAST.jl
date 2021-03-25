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
- `alpha::Float64`: α -  1/5 fit factors from
  [Flowers et al. 2009](https://doi.org/10.1016/j.gca.2009.01.015) and
  [Ketcham et al. (2007)](https://doi.org/10.2138/am.2007.2281)
- `c0`: 2/5 fit factor: Fanning Curvilinear fit
- `c1`: 3/5 fit factor: Fanning Curvilinear fit
- `c2`: 4/5 fit factor: Fanning Curvilinear fit
- `c3`: 5/5 fit factor: Fanning Curvilinear fit
- `rmr0`: reduced mean length of B2 apatite, see Ketcham et al., 2007
- `eta_q`: product η*q; η - fission-track etching efficiency, q - scaling factor

"""
function rdaam_forward_diffusion(alpha,c0,c1,c2,c3,rmr0,eta_q,L_dist,psi,omega,Etrap,
  R,Ea,logD0_a2,n_iter,U238,U238_V,U235,U235_V,Th232,Th232_V,L,
  tT...)
  tTcopy = collect(tT)
  times = tTcopy[1:ceil(Int,length(tT)/2)] # type unstable but fastest so far
  T = tTcopy[ceil(Int,length(tT)/2)+1:end]


  kappa = 1.04 - rmr0
  rdaam2nd_root = 0.5274 # cutoff bellow which rho_r values can be negative
  rdaam2nd_root_cutoff = (rdaam2nd_root^(1/kappa))*(1-rmr0)+rmr0 # also prevents
  # square root term from being negative


  # diffusivity mod

  # preallocate
  (t_equiv,N_t_segs,e_rho_s,rcb2,rho_r,D0,F,zeta,dzeta,dfdchi) = preallocate_diff_data(T) # 1st arg is only for rad dam



  n_times = length(times)
  dt_equiv = 0.0


U238_0 = U238*(exp(lambda_38*times[1])) # U238 is measured at present
U235_0 = U235*(exp(lambda_35*times[1])) # U238 is measured at present
Th232_0 = Th232*(exp(lambda_32*times[1])) # U238 is measured at present

"""
Damage calculation

"""

for ind in eachindex(times)
  if ind>1
      t_dam = times[n_times-ind+1]-times[n_times-ind+2]+dt_equiv
      rcb2_base = (c0 + c1*(log(t_dam)-c2)/(log((1.0/T[n_times-ind+1]))-c3))
      rcb2_fill_val = ((rcb2_base^(1.0/alpha))+1)^(-1)
      rcb2[ind,2] = rcb2_fill_val
      for jj in 1:(ind-1)
          if rcb2[ind,2]>=rdaam2nd_root_cutoff
            rho_r[n_times-ind+jj,n_times-jj] = ((rcb2_fill_val-rmr0)/(1.0-rmr0))^kappa
            rho_r_copy = rho_r[n_times-ind+jj,n_times-jj] # otherwise if AND elseif

            if rho_r_copy>=0.765
                rho_r[n_times-ind+jj,n_times-jj] = 1.6*rho_r[n_times-ind+jj,n_times-jj] - 0.6
            elseif rho_r_copy<0.765
                rho_r[n_times-ind+jj,n_times-jj] = 9.205*rho_r[n_times-ind+jj,n_times-jj]^2 - 9.157*rho_r[n_times-ind+jj,n_times-jj] + 2.269
            end
          end
      end
      # use concept of equivalent time
    if ind<n_times
      dt_equiv = exp((((((1.0/rcb2[ind,2])-1.0)^alpha-c0)*(log(1.0/T[n_times-ind])-c3))/c1)+c2)
    end
  end
end

w_rho_r = -diff(times)
prepend!(w_rho_r,w_rho_r[1])
append!(w_rho_r,1.0)
  ## prep diffusivity input
  for ind in eachindex(times)

        """
        Damage calculation

        """
        if ind>1





         update_damage!(times,eta_q,L_dist,U238_V,U235_V,Th232_V,e_rho_s,ind,rho_r,w_rho_r)
       end

      # from Meesters & Dunai 02 formulation
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
function update_damage!(times,eta_q,L_dist,U238_V,U235_V,Th232_V,e_rho_s,ind,rho_r_final,w_rho_r)

  dt = times[ind-1]-times[ind]

  rho_v = (8/8)*U238_V*(exp(lambda_38*times[ind-1])-exp(lambda_38*times[ind]))
  rho_v += (7/8)*U235_V*(exp(lambda_35*times[ind-1])-exp(lambda_35*times[ind]))
  rho_v += (6/8)*Th232_V*(exp(lambda_32*times[ind-1])-exp(lambda_32*times[ind]))

  e_rho_s[ind]= 1.0*rho_v*sum(rho_r_final[end-(ind-1):(end-1),ind].*(w_rho_r[2:ind]./w_rho_r[ind]))*eta_q*L_dist*lambda_f/lambda_38

#./w_rho_r[end-(ind-2):(end)]
  return nothing
end

function arrhenius(L,T,R,Ea,log10D0_a2)

  D = 10^(log10D0_a2)*L^2.0.*exp(-Ea./(R*T))

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

function mod_constraints(T::Tvv...) where {Tvv<:Real}

#smooth_mat=Tridiagonal(ones(length(T)-1),-2*ones(length(T)),1*ones(length(T)-1))
#smooth_measure[2:end-1] = (smooth_mat[2:end-1,:]*collect(T)).^2
#smooth_tot = sum(smooth_measure)
n_smooth = length(T)-2
smooth_tot = 0.0
for i in 1:n_smooth
  smooth_tot += ((T[i]-2*T[i+1]+T[i+2])^2)*1e0
end

return smooth_tot

end