function create_constraint_zon(Ea,R,D0,U238,U235,Th232,Nt,Nx,t,r)
    function constraint_zon(T,Pb)
        lhs_lo = zeros(Nx)
        lhs_top = zeros(Nx)
        lhs_mid = zeros(Nx)
        rhs = zeros(Nx)

        U238_0 = U238*(exp(lambda_38*t[1])) # U238 is measured at present
        U235_0 = U235*(exp(lambda_35*t[1])) # U238 is measured at present
        Th232_0 = Th232*(exp(lambda_32*t[1])) # U238 is measured at present

        dr = r[2] - r[1]

        Pb_rad = 0.0

        Pb[1:Nx] = zeros(Nx)
        for i in 1:(Nt-1)
            
            dt = t[i] - t[i+1]
            U238_cur = U238_0*(exp(-lambda_38*(t[1]-t[i]+dt/2)))
            D_diffn = D0*exp(-Ea/(R*T[i]))
            A = D_diffn*dt/(dr^2)
            B = D_diffn*dt/(2*dr)
            lhs_mid[:] = [1.0 + 3*A; fill(1.0 + A, Nx-2);1.0]
            lhs_top[1] = -3*A
            rhs[1] = (1.0-3*A)*Pb[1] + 3*A*Pb[2] + U238_cur[1]*lambda_38*dt
            for ii in 2:(Nx-1)
                lhs_lo[ii] = -(A/2)+ B/r[ii]
                lhs_top[ii] = -(A/2)- B/r[ii]
                rhs[ii] = (A/2 - B/r[ii])*Pb[ii-1] + (1.0 - A)*Pb[ii] + (A/2 + B/r[ii])*Pb[ii+1] + U238_cur[ii]*lambda_38*dt
                lhs_mid[ii] = lhs_mid[ii] - lhs_top[ii-1]*lhs_lo[ii]/lhs_mid[ii-1]            
                rhs[ii] = rhs[ii] - rhs[ii-1]*lhs_lo[ii]/lhs_mid[ii-1]
            end        
            rhs[Nx] = Pb_rad
            Pb[Nx] = rhs[Nx]/lhs_mid[Nx]

            for k in (Nx-1):-1:1
                Pb[k] = (rhs[k] - lhs_top[k]*Pb[k+1])/lhs_mid[k]
            end
            
        end
    

        return 
    end
    return constraint_zon
end

function create_jacobian_constraint(Ea,R,D0,U235,Th232,Nt,Nx,t,r,U238)
    function jacobian_constraint(T,mode, rows, cols, dPb_dT)
        if mode == :Structure
            rows[:] = repeat(1:Nx,inner=Nt)
            cols[:] = repeat(1:Nt,outer=Nx)
        else
            dPb_dT[:] = zeros(Nt*Nx)
            U238_0 = U238*(exp(lambda_38*t[1])) # U238 is measured at present
            U235_0 = U235*(exp(lambda_35*t[1])) # U238 is measured at present
            Th232_0 = Th232*(exp(lambda_32*t[1])) # U238 is measured at present

            dr = r[2] - r[1]



            Pb = 0.0*ones(Nx)
            Pb_rad = 0.0
            rhs = zeros(Nx,Nt)
            lhs_lo = zeros(Nx,Nt)
            lhs_top = zeros(Nx,Nt)
            lhs_mid = zeros(Nx,Nt)

            dlhs_lo = zeros(Nx,Nt)
            dlhs_top = zeros(Nx,Nt)
            dlhs_mid = zeros(Nx,Nt)
            drhs = zeros(Nx)

            bprime_lhs_mid = zeros(Nx,Nt)
            dprime_rhs = zeros(Nx)

            dAdT = zeros(Nt)
            dBdT = zeros(Nt)

            drhs_upto_i = zeros(Nx,Nt-1)
            dprime_rhs_upto_i = zeros(Nx,Nt-1)

            for i in 1:(Nt-1)
                dt = t[i] - t[i+1]
                U238_cur = U238_0*(exp(-lambda_38*(t[1]-t[i]+dt/2))) # Crank-Nicolson is staggered in time, hence dt/2
                D_diffn = D0*exp(-Ea/(R*T[i]))
                A = D_diffn*dt/(dr^2)
                B = D_diffn*dt/(2*dr)
                dAdT[i] = Ea*dt*D0*exp(-Ea/(R*T[i]))/(R*T[i]^2*dr^2)
                dBdT[i] = Ea*dt*D0*exp(-Ea/(R*T[i]))/(2*R*T[i]^2*dr)

                lhs_mid[:,i] = [1.0 + 3*A; fill(1.0 + A, Nx-2);1.0]
                dlhs_mid[:,i] = [3*dAdT[i]; fill(dAdT[i],Nx-2);0.0] # with respect to T
                bprime_lhs_mid[1,i] = dlhs_mid[1,i]

                lhs_top[1,i] = -3*A
                dlhs_top[1,i] = -3*dAdT[i]

                rhs[1,i] = (1.0-3*A)*Pb[1] + 3*A*Pb[2] + U238_cur[1]*lambda_38*dt

                ind_top = ind_dPb(1,i,Nt)
                ind_bot = ind_dPb(2,i,Nt)
                drhs[1] = (1.0 - 3*A)*dPb_dT[ind_top] - 3*Pb[1]*dAdT[i] + 3*A*dPb_dT[ind_bot] + 3*Pb[2]*dAdT[i]
                dprime_rhs[1] = drhs[1]   
                
                for j in 2:(Nx-1)
                    lhs_lo[j,i] = -(A/2)+ B/r[j]
                    lhs_top[j,i] = -(A/2)- B/r[j]
                    dlhs_lo[j] = -(dAdT[i]/2)+dBdT[i]/r[j]
                    dlhs_top[j,i] = -(dAdT[i]/2)-dBdT[i]/r[j]
                    rhs[j,i] = (A/2 - B/r[j])*Pb[j-1] + (1.0 - A)*Pb[j] + (A/2 + B/r[j])*Pb[j+1] + U238_cur[j]*lambda_38*dt

                    ind_top = ind_dPb(j-1,i,Nt)
                    ind_mid = ind_dPb(j,i,Nt)
                    ind_bot = ind_dPb(j+1,i,Nt)

                    drhs[j] = ((A/2 - B/r[j])*dPb_dT[ind_top] + (dAdT[i]/2 - dBdT[i]/r[j])*Pb[j-1] + (1.0 - A)*dPb_dT[ind_mid] - 
                        Pb[j]*dAdT[i] +  (A/2 + B/r[j])*dPb_dT[ind_bot] + (dAdT[i]/2 + dBdT[i]/r[j])*Pb[j+1])
                    
                    bprime_lhs_mid[j,i] = (dlhs_mid[j,i] -lhs_lo[j,i]*dlhs_top[j-1,i]/lhs_mid[j-1,i] + lhs_lo[j,i]*lhs_top[j-1,i]*
                        bprime_lhs_mid[j-1,i]/(lhs_mid[j-1,i]^2) - lhs_top[j-1,i]*dlhs_lo[j]/lhs_mid[j-1,i])

                    lhs_mid[j,i] = lhs_mid[j,i] - lhs_top[j-1,i]*lhs_lo[j,i]/lhs_mid[j-1,i]

                    dprime_rhs[j] = (drhs[j] -lhs_lo[j,i]*dprime_rhs[j-1]/lhs_mid[j-1,i] + lhs_lo[j,i]*rhs[j-1,i]*
                        bprime_lhs_mid[j-1,i]/(lhs_mid[j-1,i]^2) - rhs[j-1,i]*dlhs_lo[j]/lhs_mid[j-1,i])
                    rhs[j,i] = rhs[j,i] - rhs[j-1,i]*lhs_lo[j,i]/lhs_mid[j-1,i]
                end
                rhs[Nx,i] = Pb_rad

                ind_end = ind_dPb(Nx,i,Nt)
                dPb_dT[ind_end] = dprime_rhs[Nx]/lhs_mid[Nx,i] - rhs[Nx,i]*bprime_lhs_mid[Nx,i]/(lhs_mid[Nx,i])
                Pb[Nx] = rhs[Nx,i]/lhs_mid[Nx,i]
                
                for k in (Nx-1):-1:1
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
                    for j in 2:(Nx-1)
                        ind_j_top = ind_dPb_vec(j-1,range_i,Nt,i)
                        ind_j_mid = ind_dPb_vec(j,range_i,Nt,i)
                        ind_j_bot = ind_dPb_vec(j+1,range_i,Nt,i)
                        drhs_upto_i[j,1:(i-1)] = ((A/2 - B/r[j])*dPb_dT[ind_j_top]  + (1.0 - A)*dPb_dT[ind_j_mid]  +
                        (A/2 + B/r[j])*dPb_dT[ind_j_bot])
                        dprime_rhs_upto_i[j,1:i-1] = (drhs_upto_i[j,1:i-1] -lhs_lo[j,i]*dprime_rhs_upto_i[j-1,1:(i-1)]/lhs_mid[j-1,i])        
                    end
                    ind_vec_end = ind_dPb_vec(Nx,range_i,Nt,i)
                    dPb_dT[ind_vec_end] = dprime_rhs_upto_i[Nx,1:i-1]/lhs_mid[Nx,i] 

                    for k in (Nx-1):-1:1
                        ind_vec_k = ind_dPb_vec(k,range_i,Nt,i)
                        ind_vec_k_bot = ind_dPb_vec(k+1,range_i,Nt,i)
                        dPb_dT[ind_vec_k] = (( - lhs_top[k,i]*dPb_dT[ind_vec_k_bot] + dprime_rhs_upto_i[k,1:i-1])/lhs_mid[k,i])
                    end
                end # end if
            end # end Nt for loop
        end # end if structure

        return
    end # end jacobian_constraint

    return jacobian_constraint
end # end create_jacobian constraint 

function ind_dPb(x_ind,t_ind,Nt)
    return t_ind + Nt*(x_ind - 1)
end

function ind_dPb_vec(x_ind,t_ind,Nt,i)
    return (t_ind) + Nt*(x_ind - 1)*ones(Int64,i-1)
end