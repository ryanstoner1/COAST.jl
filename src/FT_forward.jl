
function FT_forward(alpha,beta,c0,c1,c2,c3,T,times,rmr0,cf_irad=false)
    ind_oldest = 1
    n_times = length(times)
    dt_equiv = 0.0
    rcb2_base = 0.0
    Tvv = eltype(T)
    N_t_segs = length(T)+1
    rho_r = zeros(Tvv,(N_t_segs,N_t_segs))
    rho_rm = zeros(Tvv,(N_t_segs))
    r_m = zeros(Tvv,(N_t_segs))
    prior = zeros(Tvv,(N_t_segs))
    rho_r_orig = zeros(Tvv,(N_t_segs))
    rcb2 = zeros(Tvv,(N_t_segs))
    taus = zeros(Tvv,(N_t_segs))

    kappa = 1.04 - rmr0
    rdaam2nd_root = 0.0#0.5274 # cutoff bellow which rho_r values can be negative
    rdaam2nd_root_cutoff = (rdaam2nd_root^(1/kappa))*(1-rmr0)+rmr0 # also prevents
    min_red_tracks = 0.13 # after Ketcham, 2000; no tracks shorter than 2.18 um
    for ind in eachindex(times)
        if ind<n_times
            t_dam = times[n_times-ind]-times[n_times-ind+1]+dt_equiv
            rcb2_base = (c0 + c1*(log(t_dam)-c2)/(log((1.0/T[n_times-ind]))-c3))
            rcb2_fill_val = ((rcb2_base^(1.0/alpha))+1)^(-1)
            rcb2[ind] = rcb2_fill_val

            if rcb2[ind]>=rdaam2nd_root_cutoff
                rho_rm[n_times-ind] = ((rcb2_fill_val-rmr0)/(1.0-rmr0))^kappa
            else
                rho_rm[n_times-ind] = 0.0
            end

            rho_r_mean = rho_rm[n_times-ind]#(rho_rm[n_times-ind]+rho_rm[n_times-ind+1])/2

            if cf_irad==true
                r_m[n_times-ind+1] = 1.396*rho_r_mean - 0.4017
            else
                r_m[n_times-ind+1] = -1.499*rho_r_mean^2 + 4.150*rho_r_mean - 1.656
            end
            prior[n_times-ind] = (exp(lambda_38*times[n_times-ind]) -
                exp(lambda_38*times[n_times-ind+1]))/lambda_38
            if (ind>1) & (rho_rm[n_times-ind+1]>0.0)
                if rho_r_mean>=0.765
                    rho_r[n_times-ind,n_times] = 1.6*rho_r_mean - 0.6
                elseif rho_r_mean<0.765
                    rho_r[n_times-ind,n_times] = 9.205*rho_r_mean^2 - 9.157*rho_r_mean + 2.269
                end

                rho_r_orig[n_times-ind+1] = rho_r[n_times-ind,n_times]
                taus[n_times-ind+1] += (1.0./(0.893))*(rho_r[n_times-ind,n_times]*
                    (times[n_times-ind]-times[n_times-ind+1]))
            elseif (ind>1) & iszero(ind_oldest)
                ind_oldest = n_times - ind + 1
            end



        else
            if (ind>1)
                rho_r_mean = rho_rm[n_times-1]

                if rho_r_mean>=0.765
                    rho_r = 1.6*rho_r_mean - 0.6
                elseif rho_r_mean<0.765
                    rho_r = 9.205*rho_r_mean^2 - 9.157*rho_r_mean + 2.269
                end
                rho_r_orig[end] = rho_r

                taus[end] += 0.5*(1.0./(0.893))*(rho_r*
                    (times[n_times-1]-times[n_times]))

            end
        end
              # use concept of equivalent time


        if ind<(n_times-1)
        dt_equiv = exp((((((1.0/rcb2[ind])-1.0)^alpha-c0)*(log(1.0/T[n_times-ind-1])-c3))/c1)+c2)
        end
    end

    return times[ind_oldest],taus, r_m, rho_rm, rcb2, rho_r_orig, prior
end


function FT_forward_age_distribution()
    return nothing
end
