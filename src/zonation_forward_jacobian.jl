using LinearAlgebra
# using Pkg
# Pkg.activate(pwd())
#using Zygote
using Ipopt
#using COAST
sec_in_yrs_test = 3.1558e7
lambda_f = 8.46e-17/sec_in_yrs_test
const lambda_38 = 1.55125 * 1e-10/sec_in_yrs_test
const lambda_35 = 9.8584*1e-10/sec_in_yrs_test
const lambda_32 = 4.9475*1e-11/sec_in_yrs_test
Nt = 39
t_end = 1.0
dt = t_end/(Nt-1)
T1 = collect(LinRange(900.0,600.0,ceil(Int,Nt/2)).+273.15)
T2 = collect(LinRange(600.0,400.0,floor(Int,Nt/2)).+273.15)
T = vcat(T1,T2)
t1 = collect(LinRange(70.0,50.0,ceil(Int,Nt/2)).*3.1558e7*1e6)
t2 = collect(LinRange(49.9,0.01,floor(Int,Nt/2)).*3.1558e7*1e6)
t = vcat(t1,t2)
Ea = 250.0*1e3
D0 = 3.9*1e-10
#Rjoules = 8.314
L = 1e-4
Nx = 30
r = LinRange(0.0,L,Nx)
U238 = 1.0
U238 = U238*ones(Nx)
R = 8.314
# Nt,t_end
function forward_jacobian(Ea,R,D0,U235,Th232,L,Nt,Nx,t,T,r,U238)

    # tTcopy = collect(tTrU)
    # t = tTcopy[1:Nt]#[1:ceil(Int,length(tT)/2)] # type unstable but fastest so far
    # T = tTcopy[(Nt+1):(2*Nt)]#[ceil(Int,length(tT)/2)+1:end]
    # r = tTcopy[(2*Nt+1):(2*Nt+Nx)]
    # U238 = tTcopy[(2*Nt+Nx+1):end]
    U238_0 = U238*(exp(lambda_38*t[1])) # U238 is measured at present
    U235_0 = U235*(exp(lambda_35*t[1])) # U238 is measured at present
    Th232_0 = Th232*(exp(lambda_32*t[1])) # U238 is measured at present

    dr = r[2] - r[1]



    Pb = 0.0*ones(Nx)
    dPb_dT = zeros(Nx,Nt)
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
        drhs[1] = (1.0 - 3*A)*dPb_dT[1,i] - 3*Pb[1]*dAdT[i] + 3*A*dPb_dT[2,i] + 3*Pb[2]*dAdT[i]
        dprime_rhs[1] = drhs[1]   
        
        for j in 2:(Nx-1)
            lhs_lo[j,i] = -(A/2)+ B/r[j]
            lhs_top[j,i] = -(A/2)- B/r[j]
            dlhs_lo[j] = -(dAdT[i]/2)+dBdT[i]/r[j]
            dlhs_top[j,i] = -(dAdT[i]/2)-dBdT[i]/r[j]
            rhs[j,i] = (A/2 - B/r[j])*Pb[j-1] + (1.0 - A)*Pb[j] + (A/2 + B/r[j])*Pb[j+1] + U238_cur[j]*lambda_38*dt
            drhs[j] = ((A/2 - B/r[j])*dPb_dT[j-1,i] + (dAdT[i]/2 - dBdT[i]/r[j])*Pb[j-1] + (1.0 - A)*dPb_dT[j,i] - 
                Pb[j]*dAdT[i] +  (A/2 + B/r[j])*dPb_dT[j+1,i] + (dAdT[i]/2 + dBdT[i]/r[j])*Pb[j+1])
            
            bprime_lhs_mid[j,i] = (dlhs_mid[j,i] -lhs_lo[j,i]*dlhs_top[j-1,i]/lhs_mid[j-1,i] + lhs_lo[j,i]*lhs_top[j-1,i]*
                bprime_lhs_mid[j-1,i]/(lhs_mid[j-1,i]^2) - lhs_top[j-1,i]*dlhs_lo[j]/lhs_mid[j-1,i])

            lhs_mid[j,i] = lhs_mid[j,i] - lhs_top[j-1,i]*lhs_lo[j,i]/lhs_mid[j-1,i]

            dprime_rhs[j] = (drhs[j] -lhs_lo[j,i]*dprime_rhs[j-1]/lhs_mid[j-1,i] + lhs_lo[j,i]*rhs[j-1,i]*
                bprime_lhs_mid[j-1,i]/(lhs_mid[j-1,i]^2) - rhs[j-1,i]*dlhs_lo[j]/lhs_mid[j-1,i])
            rhs[j,i] = rhs[j,i] - rhs[j-1,i]*lhs_lo[j,i]/lhs_mid[j-1,i]
        end
        rhs[Nx,i] = Pb_rad


        dPb_dT[Nx,i] = dprime_rhs[Nx]/lhs_mid[Nx,i] - rhs[Nx,i]*bprime_lhs_mid[Nx,i]/(lhs_mid[Nx,i])
        Pb[Nx] = rhs[Nx,i]/lhs_mid[Nx,i]
        
        for k in (Nx-1):-1:1
            dPb_dT[k,i] = (-(rhs[k,i] - Pb[k+1]*lhs_top[k,i])*bprime_lhs_mid[k,i]/(lhs_mid[k,i]^2) +
                (-Pb[k+1]*dlhs_top[k,i] - lhs_top[k,i]*dPb_dT[k+1,i] + dprime_rhs[k])/lhs_mid[k,i])
            Pb[k] = (rhs[k,i] - lhs_top[k,i]*Pb[k+1])/lhs_mid[k,i]
            
        end

        if i>1
            drhs_upto_i[1,1:(i-1)] = (1.0 - 3*A)*dPb_dT[1,1:(i-1)] + 3*A*dPb_dT[2,1:(i-1)] 
            dprime_rhs_upto_i[1,1:(i-1)] = drhs_upto_i[1,1:(i-1)]    
            for j in 2:(Nx-1)
                drhs_upto_i[j,1:(i-1)] = ((A/2 - B/r[j])*dPb_dT[j-1,1:(i-1)]  + (1.0 - A)*dPb_dT[j,1:(i-1)]  +
                (A/2 + B/r[j])*dPb_dT[j+1,1:i-1])
                dprime_rhs_upto_i[j,1:i-1] = (drhs_upto_i[j,1:i-1] -lhs_lo[j,i]*dprime_rhs_upto_i[j-1,1:(i-1)]/lhs_mid[j-1,i])        
            end


            dPb_dT[Nx,1:i-1] = dprime_rhs_upto_i[Nx,1:i-1]/lhs_mid[Nx,i] 


            for k in (Nx-1):-1:1
                dPb_dT[k,1:i-1] = (( - lhs_top[k,i]*dPb_dT[k+1,1:i-1] + dprime_rhs_upto_i[k,1:i-1])/lhs_mid[k,i])
            end
        end
    end
    
    return Pb,dPb_dT

end

function forward_clone(preall,Ea,R,D0,U238,U235,Th232,L,Nt,Nx,t,T,r)
    lhs_lo = Zygote.Buffer(preall, Nx, 1)
    lhs_top = Zygote.Buffer(preall, Nx, 1)
    lhs_mid = Zygote.Buffer(preall, Nx, 1)
    rhs = Zygote.Buffer(preall, Nx, 1)
    Pb = Zygote.Buffer(preall, Nx, 1)
    

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
    

return copy(Pb)
    
end

preall = zeros(Nx)
Tb = copy(T)
Tb[2] = Tb[2]+0.01 
initPb = [0.008857378583018752, 0.008856812929792447, 0.00885511177504213, 0.008852259612534526, 0.008848230516985477, 0.008842987011603362, 0.008836478776030107, 0.008828640808589248, 0.008819390873808581, 0.008808625978040217, 0.00879621748087797, 0.008782004239101911, 0.008765782846776095, 0.008747293506359331, 0.008726199226256422, 0.008702054713998092, 0.008674259257549808, 0.008641984671522813, 0.008604064447778814, 0.008558822633270739, 0.008503808762407928, 0.008435383783207719, 0.008348058711971884, 0.008233386603361441, 0.008077941780303029, 0.007859134069521883, 0.007534875513179412, 0.007010548962254766, 0.005967321901702219, 0.0]
#measuredPb = 1.1*initPb
#(val,grad) = forward_jacobian(Ea,R,D0,0.0,0.0,L,Nt,Nx,t,T,r,U238)
# (val2,grad2) = forward_jacobian(Ea,R,D0,0.0,0.0,L,Nt,Nx,t,Tb,r,U238)
# valest = (val2-val)/0.01
# print("Estimates value grad: $(valest)\n")
# preall = zeros(Nx)


# forw_clone = forward_clone(preall,Ea,R,D0,U238,0.0,0.0,L,Nt,Nx,t,T,r)
#preall = zeros(Nx)
#grad_g_zygote = jacobian(T->forward_clone(preall,Ea,R,D0,U238,0.0,0.0,L,Nt,Nx,t,T,r),T)[1]
# print("\nAnalytical soln+jacobian are:\n$(val)\n$(grad)\n")
#print("\nAnalytical soln test is:\n$(forw_clone)\n")
#print("\nAutograd jacobian is:\n$(grad_g_zygote)")

function create_constraint_zonation(Ea,R,D0,U238,U235,Th232,Nt,Nx,t,r)
    function constraint_zonation(T,Pb)
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
    return constraint_zonation
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

jacobian_constraint = create_jacobian_constraint(Ea,R,D0,0.0,0.0,Nt,Nx,t,r,U238)
rows = zeros(Int64,Nx*Nt)
cols = zeros(Int64,Nx*Nt)
dPb_dT = zeros(Float64,Nx*Nt)
#mode = :Mod
#jacobian_constraint(T,mode, rows, cols, dPb_dT)

Pb = zeros(Nx)
constraint_zonation = create_constraint_zonation(Ea,R,D0,U238,0.0,0.0,Nt,Nx,t,r)
# create function as function of T only

function objective(T) 

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

function grad_objective(T,dT) 

    Nt = length(T)
    dT[:] = zeros(Nt)

    for i in 1:(Nt-2)
        dT[i] += 0.1*(2*T[i]-4*T[i+1]+2*T[i+2])
        dT[i+1] += 0.1*(8*T[i+1]-4*T[i]-4*T[i+2])
        dT[i+2] += 0.1*(2*T[i+2]-4*T[i+1]+2*T[i])
            
    end
    
    return 
    
    
    
end
T1 = [3.1,4.3,3.97,6.3,5.5,6.2]
x = zeros(length(T1))
grad_objective(T1,x)


x_L = zeros(Float64,Nt)
x_U = 2900*ones(Float64,Nt)


g_L = initPb - 0.03*initPb
g_U = initPb + 0.03*initPb 

prob = createProblem(
    Nt,
    x_L,
    x_U,
    Nx,
    g_L,
    g_U,
    Nt*Nx,
    Nt*Nx,
    objective,
    constraint_zonation,
    grad_objective,
    jacobian_constraint,
)
addOption(prob, "hessian_approximation", "limited-memory")
addOption(prob, "tol", 300.0)
#addOption(prob, "constr_viol_tol", 1e-4)
#addOption(prob,"dual_inf_tol",0.1)
#addOption(prob,"compl_inf_tol",1e-6)
prob.x = 1.1*T
status=solveProblem(prob)

println(Ipopt.ApplicationReturnStatus[status])
println(prob.x)
println(prob.obj_val)