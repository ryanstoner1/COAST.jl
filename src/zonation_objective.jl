
function zon_objective(T) 

    #smooth_mat=Tridiagonal(ones(length(T)-1),-2*ones(length(T)),1*ones(length(T)-1))
    #smooth_measure[2:end-1] = (smooth_mat[2:end-1,:]*collect(T)).^2
    #smooth_tot = sum(smooth_measure)
    n_smooth = length(T)-2
    smooth_tot = 0.0
    for i in 1:n_smooth
      smooth_tot += 0.1*(T[i]-2*T[i+1]+T[i+2])^2
    end
    
    return smooth_tot
    
end

function grad_zon_objective(T,dT) 

    Nt = length(T)
    dT[:] = zeros(Nt)

    for i in 1:(Nt-2)
        dT[i] += 0.1*(2*T[i]-4*T[i+1]+2*T[i+2])
        dT[i+1] += 0.1*(8*T[i+1]-4*T[i]-4*T[i+2])
        dT[i+2] += 0.1*(2*T[i+2]-4*T[i+1]+2*T[i])
            
    end
    
    return 
    
    
    
end
