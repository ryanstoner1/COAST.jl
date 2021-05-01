using LinearAlgebra
using Zygote

sec_in_yrs = 3.1558e7
lambda_f = 8.46e-17/sec_in_yrs
const lambda_38 = 1.55125 * 1e-10/sec_in_yrs
const lambda_35 = 9.8584*1e-10/sec_in_yrs
const lambda_32 = 4.9475*1e-11/sec_in_yrs
Nt = 100
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
Nx = 513
r = LinRange(0.0,L,Nx)
U238 = 1.0
R = 8.314
# Nt,t_end
function forward_jacobian(Ea,R,D0,U238,U235,Th232,L,Nt,Nx,tTr...)

    tTcopy = collect(tTr)
    t = tTcopy[1:Nt]#[1:ceil(Int,length(tT)/2)] # type unstable but fastest so far
    T = tTcopy[(Nt+1):(end-Nx)]#[ceil(Int,length(tT)/2)+1:end]
    r = tTcopy[(end-Nx+1):end]
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

        rhs[1,i] = (1.0-3*A)*Pb[1] + 3*A*Pb[2] + U238_0*lambda_38*dt
        drhs[1] = (1.0 - 3*A)*dPb_dT[1,i] - 3*Pb[1]*dAdT[i] + 3*A*dPb_dT[2,i] + 3*Pb[2]*dAdT[i]
        dprime_rhs[1] = drhs[1]   
        
        for j in 2:(Nx-1)
            lhs_lo[j,i] = -(A/2)+ B/r[j]
            lhs_top[j,i] = lhs_lo[j,i]
            dlhs_lo[j] = -(dAdT[i]/2)+dBdT[i]/r[j]
            dlhs_top[j,i] = dlhs_lo[j]
            rhs[j,i] = (A/2 - B/r[j])*Pb[j-1] + (1.0 - A)*Pb[j] + (A/2 + B/r[j])*Pb[j+1] + U238_0*lambda_38*dt
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
    Pb_tot = Zygote.Buffer(preall, Nx, Nt)

    U238_0 = U238*(exp(lambda_38*t[1])) # U238 is measured at present
    U235_0 = U235*(exp(lambda_35*t[1])) # U238 is measured at present
    Th232_0 = Th232*(exp(lambda_32*t[1])) # U238 is measured at present

    dr = r[2] - r[1]

    Pb_rad = 0.0

    Pb[1:Nx] = zeros(Nx)
    for i in 1:(Nt-1)
        # TODO U238 decay
        dt = t[i] - t[i+1]
        D_diffn = D0*exp(-Ea/(R*T[i]))
        A = D_diffn*dt/(dr^2)
        B = D_diffn*dt/(2*dr)
        lhs_mid[:] = [1.0 + 3*A; fill(1.0 + A, Nx-2);1.0]
        lhs_top[1] = -3*A
        rhs[1] = (1.0-3*A)*Pb[1] + 3*A*Pb[2] + U238_0*lambda_38*dt
        for ii in 2:(Nx-1)
            lhs_lo[ii] = -(A/2)+ B/r[ii]
            lhs_top[ii] = lhs_lo[ii]
            rhs[ii] = (A/2 - B/r[ii])*Pb[ii-1] + (1.0 - A)*Pb[ii] + (A/2 + B/r[ii])*Pb[ii+1] + U238_0*lambda_38*dt
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
(val,grad) = forward_jacobian(Ea,R,D0,U238,0.0,0.0,L,Nt,Nx,t...,T...,r...)
(val2,grad2) = forward_jacobian(Ea,R,D0,U238,0.0,0.0,L,Nt,Nx,t...,Tb...,r...)
#valest = (val2-val)/0.01
print("Estimates value grad: $(valest)\n")
preall = zeros(Nx)
forw_clone = forward_clone(preall,Ea,R,D0,U238,0.0,0.0,L,Nt,Nx,t,T,r)
preall = zeros(Nx)
#grad_g_zygote = jacobian(T->forward_clone(preall,Ea,R,D0,U238,0.0,0.0,L,Nt,Nx,t,T,r),T)[1]
print("\nAnalytical soln+jacobian are:\n$(val)\n$(grad)\n")
#print("\nAnalytical soln test is:\n$(forw_clone)\n")
#print("\nAutograd jacobian is:\n$(grad_g_zygote)")