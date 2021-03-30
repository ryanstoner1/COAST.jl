import numpy as np

# extract user-defined bounding boxes in HeFTy
def extract_Tt_constraints(default_envelope_ind,decoded):
    # default no. of constraints in HeFTy is two
    n_extra_constraints = 0 

    min_times = np.array([])
    max_times = np.array([])
    min_temp = np.array([])
    max_temp = np.array([])

    # strip header lines 
    decoded = decoded[2:]
    for (ind,line) in enumerate(decoded):
                
                line_split = line.split()
                
                if line_split[0].isdigit():
                    # get constraint box parameters
                    line_arr = np.array(line_split).astype(float)
                    max_times = np.append(max_times, line_arr[1])
                    min_times = np.append(min_times, line_arr[2])
                    max_temp = np.append(max_temp, line_arr[3])
                    min_temp = np.append(min_temp, line_arr[4])

                    # increment if more than default number of constraints
                    if ind>3:
                        n_extra_constraints += 1
                else:
                    break
    # remove lines we've already processed
    decoded_shortened = decoded[ind:]
    bound_box = (max_times, min_times, max_temp, min_temp)
    
    return bound_box, n_extra_constraints, decoded_shortened

# extract envelopes for T-t paths; either good or acceptable based on 
# goodness of fit (GOF) criteria
def extract_Tt_bounds(decoded_shortened):
    
    # strip intervening lines
    decoded_shortened = decoded_shortened[2:]
    
    for (ind,line) in enumerate(decoded_shortened):
        line_split = line.split()
        
        if ind == 0:
            good_time = np.array(line_split[3:]).astype(float)
        if ind== 1:            
            good_hi = np.array(line_split[4:]).astype(float)
        if ind== 2:
            good_lo = np.array(line_split[4:]).astype(float)
        if ind == 3:
            acc_time = np.array(line_split[3:]).astype(float)
        if ind == 4:
            acc_hi = np.array(line_split[4:]).astype(float)
        if ind == 5:
            acc_lo = np.array(line_split[4:]).astype(float)
    good_acc_bounds = (good_time, good_hi, good_lo, acc_time, acc_hi, acc_lo)

    # cull what was iterated over
    decoded_shortened = decoded_shortened[6:]
    return (good_acc_bounds, decoded_shortened)

# extract individual acceptable and good T-t paths
def interp_Tt(good_time, acc_time, decoded_shortened):
    date = np.array([]) 
    # strip data between acc/good bounds and where T-t data starts
    decoded_shortened = decoded_shortened[12:]
    # initialize data to be filled
    acc_time_interp = np.empty((0,len(acc_time)))
    good_time_interp = np.empty((0,len(good_time)))    

    # alternate between even and odd lines because hefty 
    # has two lines: one for time and one for temperature
    upper_line_Tt = True      

    for (ind,line) in enumerate(decoded_shortened):        
        line_split = line.split()
         
                   
        if upper_line_Tt:
            date = np.append(date,line_split[1])
            time_Tt = np.array(line_split[4:]).astype(float)
            time_Tt = time_Tt[::-1]
            if ind == 0:    
                time_Ma = np.empty((0,len(time_Tt)))
            
            time_Ma = np.vstack((time_Ma,time_Tt))
            
            
            upper_line_Tt = False
                            
        else:               
            T_Tt = np.array(line_split[4:]).astype(float)
            T_Tt = T_Tt[::-1]
            if ind == 1: 
                T_celsius = np.empty((0,len(T_Tt)))
            T_celsius = np.vstack((T_celsius,T_Tt))
            upper_line_Tt = True
            good_time_interp_line = np.interp(good_time,time_Tt,T_Tt)
            good_time_interp = np.vstack((good_time_interp,good_time_interp_line))
            acc_time_interp_line = np.interp(acc_time,time_Tt,T_Tt)
            acc_time_interp = np.vstack((acc_time_interp,acc_time_interp_line))
            # need if statement?
            
            upper_line_Tt = True
    return (acc_time_interp, good_time_interp)
