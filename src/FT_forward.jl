
function FT_forward(alpha,beta,c0,c1,c2,c3,T,times)
n_times = length(times)
dt_equiv = 0.0
    for ind in eachindex(times)
        if ind>1
            t_dam = times[n_times-ind+1]-times[n_times-ind+2]+dt_equiv
            rcb2_base = (c0 + c1*(log(t_dam)-c2)/(log((1.0/T[n_times-ind+1]))-c3))
            rcb2_fill_val = ((rcb2_base^(1.0/alpha))+1)^(-1)
        end
    end

end


function FT_forward_age_distribution()
    return nothing
end
