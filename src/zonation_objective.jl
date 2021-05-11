
function smooth_zon_objective(T) 

    #smooth_mat=Tridiagonal(ones(length(T)-1),-2*ones(length(T)),1*ones(length(T)-1))
    #smooth_measure[2:end-1] = (smooth_mat[2:end-1,:]*collect(T)).^2
    #smooth_tot = sum(smooth_measure)
    n_smooth = length(T)-2
    smooth_tot = 0.0
    for i in 1:n_smooth
      smooth_tot += 1*(T[i]-2*T[i+1]+T[i+2])^2
    end
    
    return smooth_tot
    
end

function grad_smooth_zon_objective(T,dT) 

    Nt = length(T)
    dT[:] = zeros(Nt)

    for i in 1:(Nt-2)
        dT[i] += 1*(2*T[i]-4*T[i+1]+2*T[i+2])
        dT[i+1] += 1*(8*T[i+1]-4*T[i]-4*T[i+2])
        dT[i+2] += 1*(2*T[i+2]-4*T[i+1]+2*T[i])
            
    end
    
    return 
       
end

function decreasing_zon_objective(T) 
    n_grad = length(T)-1
    grad_decrease_tot = 0.0

    for i in 1:n_grad
        grad_decrease_tot+=maximum([T[i+1]-T[i],0.0])
    end
    return grad_decrease_tot
    
end

function grad_decreasing_zon_objective(T,dT)
    Nt = length(T)
    dT[:] = zeros(Nt)
    for i in 1:(Nt-1)
        if T[i+1]>T[i]
            dT[i] += -1.0
            dT[i+1] += 1.0
        else
            dT[i] = 0.0
        end
    end
    return
end

function create_zon_loglike_objective(Ea,R,D0,U238,U235,Th232,Nt,Nx,t,r,Pbmeas,sigmeas,ngrains)
    function zon_loglike_objective(T)
        loglike = 0.0

        for igrain in 1:ngrains
            lhs_lo = zeros(Nx[igrain])
            lhs_top = zeros(Nx[igrain])
            lhs_mid = zeros(Nx[igrain])
            rhs = zeros(Nx[igrain])

            U238_0 = U238[igrain][:]*(exp(lambda_38*t[1])) # U238 is measured at present
            U235_0 = U235[igrain][:]*(exp(lambda_35*t[1])) # U238 is measured at present
            Th232_0 = Th232[igrain][:]*(exp(lambda_32*t[1])) # U238 is measured at present

            dr = r[igrain][2] - r[igrain][1]

            Pb_rad = 0.0

            Pb = zeros(Nx[igrain])
            
            for i in 1:(Nt-1)
                
                dt = t[i] - t[i+1]
                U238_cur = U238_0*(exp(-lambda_38*(t[1]-t[i]+dt/2)))
                D_diffn = D0*exp(-Ea/(R*T[i]))
                A = D_diffn*dt/(dr^2)
                B = D_diffn*dt/(2*dr)
                lhs_mid[:] = [1.0 + 3*A; fill(1.0 + A, Nx[igrain]-2);1.0]
                lhs_top[1] = -3*A
                rhs[1] = (1.0-3*A)*Pb[1] + 3*A*Pb[2] + U238_cur[1]*lambda_38*dt
                for ii in 2:(Nx[igrain]-1)
                    lhs_lo[ii] = -(A/2)+ B/r[igrain][ii]
                    lhs_top[ii] = -(A/2)- B/r[igrain][ii]
                    rhs[ii] = (A/2 - B/r[igrain][ii])*Pb[ii-1] + (1.0 - A)*Pb[ii] + (A/2 + B/r[igrain][ii])*Pb[ii+1] + U238_cur[ii]*lambda_38*dt
                    lhs_mid[ii] = lhs_mid[ii] - lhs_top[ii-1]*lhs_lo[ii]/lhs_mid[ii-1]            
                    rhs[ii] = rhs[ii] - rhs[ii-1]*lhs_lo[ii]/lhs_mid[ii-1]
                end        
                rhs[Nx[igrain]] = Pb_rad
                Pb[Nx[igrain]] = rhs[Nx[igrain]]/lhs_mid[Nx[igrain]]

                for k in (Nx[igrain]-1):-1:1
                    Pb[k] = (rhs[k] - lhs_top[k]*Pb[k+1])/lhs_mid[k]
                end
                
            end
            
            for j in 1:(Nx[igrain]-1)
                loglike+= ((Pb[j]-Pbmeas[igrain][j])/sigmeas[igrain][j])^2#+minimum([(exp(-Ea/(R*T[i+1]))-exp(-Ea/(R*T[i])))/((t[i+1]-t[i])*sum(t)),0.0])
            end
        end
        
        return loglike
    end
    return zon_loglike_objective
end

function create_grad_loglike_objective(Ea,R,D0,U238,U235,Th232,Nt,Nx,t,r,Pbmeas,sigmeas,ngrains)
    function grad_loglike_objective(T,dLL_dT)
        dLL_dT[:] = zeros(Nt)
        for igrain in 1:ngrains
            dPb_dT = zeros(Nt*Nx[igrain])
            U238_0 = U238[igrain][:]*(exp(lambda_38*t[1])) # U238 is measured at present
            U235_0 = U235[igrain][:]*(exp(lambda_35*t[1])) # U238 is measured at present
            Th232_0 = Th232[igrain][:]*(exp(lambda_32*t[1])) # U238 is measured at present

            dr = r[igrain][2] - r[igrain][1]



            Pb = 0.0*ones(Nx[igrain])
            Pb_rad = 0.0
            rhs = zeros(Nx[igrain],Nt)
            lhs_lo = zeros(Nx[igrain],Nt)
            lhs_top = zeros(Nx[igrain],Nt)
            lhs_mid = zeros(Nx[igrain],Nt)

            dlhs_lo = zeros(Nx[igrain],Nt)
            dlhs_top = zeros(Nx[igrain],Nt)
            dlhs_mid = zeros(Nx[igrain],Nt)
            drhs = zeros(Nx[igrain])

            bprime_lhs_mid = zeros(Nx[igrain],Nt)
            dprime_rhs = zeros(Nx[igrain])

            dAdT = zeros(Nt)
            dBdT = zeros(Nt)

            drhs_upto_i = zeros(Nx[igrain],Nt-1)
            dprime_rhs_upto_i = zeros(Nx[igrain],Nt-1)

            for i in 1:(Nt-1)
                dt = t[i] - t[i+1]
                U238_cur = U238_0*(exp(-lambda_38*(t[1]-t[i]+dt/2))) # Crank-Nicolson is staggered in time, hence dt/2
                D_diffn = D0*exp(-Ea/(R*T[i]))
                A = D_diffn*dt/(dr^2)
                B = D_diffn*dt/(2*dr)
                dAdT[i] = Ea*dt*D0*exp(-Ea/(R*T[i]))/(R*T[i]^2*dr^2)
                dBdT[i] = Ea*dt*D0*exp(-Ea/(R*T[i]))/(2*R*T[i]^2*dr)

                lhs_mid[:,i] = [1.0 + 3*A; fill(1.0 + A, Nx[igrain]-2);1.0]
                dlhs_mid[:,i] = [3*dAdT[i]; fill(dAdT[i],Nx[igrain]-2);0.0] # with respect to T
                bprime_lhs_mid[1,i] = dlhs_mid[1,i]

                lhs_top[1,i] = -3*A
                dlhs_top[1,i] = -3*dAdT[i]

                rhs[1,i] = (1.0-3*A)*Pb[1] + 3*A*Pb[2] + U238_cur[1]*lambda_38*dt

                ind_top = ind_dPb(1,i,Nt)
                ind_bot = ind_dPb(2,i,Nt)
                drhs[1] = (1.0 - 3*A)*dPb_dT[ind_top] - 3*Pb[1]*dAdT[i] + 3*A*dPb_dT[ind_bot] + 3*Pb[2]*dAdT[i]
                dprime_rhs[1] = drhs[1]   
                
                for j in 2:(Nx[igrain]-1)
                    lhs_lo[j,i] = -(A/2)+ B/r[igrain][j]
                    lhs_top[j,i] = -(A/2)- B/r[igrain][j]
                    dlhs_lo[j] = -(dAdT[i]/2)+dBdT[i]/r[igrain][j]
                    dlhs_top[j,i] = -(dAdT[i]/2)-dBdT[i]/r[igrain][j]
                    rhs[j,i] = (A/2 - B/r[igrain][j])*Pb[j-1] + (1.0 - A)*Pb[j] + (A/2 + B/r[igrain][j])*Pb[j+1] + U238_cur[j]*lambda_38*dt

                    ind_top = ind_dPb(j-1,i,Nt)
                    ind_mid = ind_dPb(j,i,Nt)
                    ind_bot = ind_dPb(j+1,i,Nt)

                    drhs[j] = ((A/2 - B/r[igrain][j])*dPb_dT[ind_top] + (dAdT[i]/2 - dBdT[i]/r[igrain][j])*Pb[j-1] + (1.0 - A)*dPb_dT[ind_mid] - 
                        Pb[j]*dAdT[i] +  (A/2 + B/r[igrain][j])*dPb_dT[ind_bot] + (dAdT[i]/2 + dBdT[i]/r[igrain][j])*Pb[j+1])
                    
                    bprime_lhs_mid[j,i] = (dlhs_mid[j,i] -lhs_lo[j,i]*dlhs_top[j-1,i]/lhs_mid[j-1,i] + lhs_lo[j,i]*lhs_top[j-1,i]*
                        bprime_lhs_mid[j-1,i]/(lhs_mid[j-1,i]^2) - lhs_top[j-1,i]*dlhs_lo[j]/lhs_mid[j-1,i])

                    lhs_mid[j,i] = lhs_mid[j,i] - lhs_top[j-1,i]*lhs_lo[j,i]/lhs_mid[j-1,i]

                    dprime_rhs[j] = (drhs[j] -lhs_lo[j,i]*dprime_rhs[j-1]/lhs_mid[j-1,i] + lhs_lo[j,i]*rhs[j-1,i]*
                        bprime_lhs_mid[j-1,i]/(lhs_mid[j-1,i]^2) - rhs[j-1,i]*dlhs_lo[j]/lhs_mid[j-1,i])
                    rhs[j,i] = rhs[j,i] - rhs[j-1,i]*lhs_lo[j,i]/lhs_mid[j-1,i]
                end
                rhs[Nx[igrain],i] = Pb_rad

                ind_end = ind_dPb(Nx[igrain],i,Nt)
                dPb_dT[ind_end] = dprime_rhs[Nx[igrain]]/lhs_mid[Nx[igrain],i] - rhs[Nx[igrain],i]*bprime_lhs_mid[Nx[igrain],i]/(lhs_mid[Nx[igrain],i])
                Pb[Nx[igrain]] = rhs[Nx[igrain],i]/lhs_mid[Nx[igrain],i]
                
                for k in (Nx[igrain]-1):-1:1
                    ind_k = ind_dPb(k,i,Nt)
                    ind_k_below = ind_dPb(k+1,i,Nt)
                    dPb_dT[ind_k] = (-(rhs[k,i] - Pb[k+1]*lhs_top[k,i])*bprime_lhs_mid[k,i]/(lhs_mid[k,i]^2) +
                        (-Pb[k+1]*dlhs_top[k,i] - lhs_top[k,i]*dPb_dT[ind_k_below] + dprime_rhs[k])/lhs_mid[k,i])
                    Pb[k] = (rhs[k,i] - lhs_top[k,i]*Pb[k+1])/lhs_mid[k,i]
                    
                end

                if i>1
                    range_i = 1:(i-1)
                    ind_top = ind_dPb_vec(1,range_i,Nt,i)
                    ind_bot = ind_dPb_vec(2,range_i,Nt,i)
                    drhs_upto_i[1,1:(i-1)] = (1.0 - 3*A)*dPb_dT[ind_top] + 3*A*dPb_dT[ind_bot] 
                    dprime_rhs_upto_i[1,1:(i-1)] = drhs_upto_i[1,1:(i-1)]    
                    for j in 2:(Nx[igrain]-1)
                        ind_j_top = ind_dPb_vec(j-1,range_i,Nt,i)
                        ind_j_mid = ind_dPb_vec(j,range_i,Nt,i)
                        ind_j_bot = ind_dPb_vec(j+1,range_i,Nt,i)
                        drhs_upto_i[j,1:(i-1)] = ((A/2 - B/r[igrain][j])*dPb_dT[ind_j_top]  + (1.0 - A)*dPb_dT[ind_j_mid]  +
                        (A/2 + B/r[igrain][j])*dPb_dT[ind_j_bot])
                        dprime_rhs_upto_i[j,1:i-1] = (drhs_upto_i[j,1:i-1] -lhs_lo[j,i]*dprime_rhs_upto_i[j-1,1:(i-1)]/lhs_mid[j-1,i])        
                    end
                    ind_vec_end = ind_dPb_vec(Nx[igrain],range_i,Nt,i)
                    dPb_dT[ind_vec_end] = dprime_rhs_upto_i[Nx[igrain],1:i-1]/lhs_mid[Nx[igrain],i] 

                    for k in (Nx[igrain]-1):-1:1
                        ind_vec_k = ind_dPb_vec(k,range_i,Nt,i)
                        ind_vec_k_bot = ind_dPb_vec(k+1,range_i,Nt,i)
                        dPb_dT[ind_vec_k] = (( - lhs_top[k,i]*dPb_dT[ind_vec_k_bot] + dprime_rhs_upto_i[k,1:i-1])/lhs_mid[k,i])
                    end
                end # end if
            end # end Nt for loop
            
            for j in 1:(Nx[igrain]-1)
                ind_vec = (1:Nt)+(j-1)*Nt*ones(Int64,Nt)
                dLL_dT[:] += (2*Pb[j]*dPb_dT[ind_vec]/(sigmeas[igrain][j]^2))-(2*Pbmeas[igrain][j]*dPb_dT[ind_vec]/(sigmeas[igrain][j]^2))
            end
        end # end grain loop
        return
    end # end grad_loglike_objective

    return grad_loglike_objective
end # end create_grad_loglike_objective

function null_objective(T)
    return 1.0
end

function grad_null_objective(T,objval)
    objval[:] = zeros(length(T))
    return
end

function create_decreasing_objective(Nt,t)
    function decreasing_objective(T)
        objval = 0.0
        for i in 1:(Nt-1)
            objval += maximum([(T[i+1]-T[i])/(t[i]-t[i+1]),0.0])
        end
        return objval
    end
    return decreasing_objective
end

function create_grad_decreasing_objective(Nt,t)
    function grad_decreasing_objective(T,jac_obj)
        
        for i in 1:(Nt-1)
            # 2*T[i]-2*T[i+1]
            # 2*T[i+1]-2*T[i]

            if (T[i+1]<=T[i])
                jac_obj[i] += 0.0
            elseif (T[i+1]>T[i])
                jac_obj[i] += ((-1.0))/(t[i]-t[i+1])
                jac_obj[i+1] +=  ((1.0))/(t[i]-t[i+1])
            end
            # jac_grad[2*i-1] = ((-1.0)*scaling)/(-t[i]+t[i+1])
            # jac_grad[2*i] = ((1.0)*scaling)/(-t[i]+t[i+1])
        end
        return
    end
    return grad_decreasing_objective
end
