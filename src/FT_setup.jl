

function FT_forward_age_distribution()
  return nothing
end

"""
Dpar - input as either 5.0M or 5.5M case
"""
function init_track_len(;calc_type="Dpar",Dpar=1.65,OH=0.0,Cl=0.0,rmr0=0.0,
  a_vol=0.0,Ketcham07_5_5m=true,Ketcham07_5_0m=false,Donelick99=false,
  orig_calc=true,custom_calc=false,custom_intercept=0.0,custom_slope=0.0,
  custom_param=0.0,custom_c_intercept=0.0,custom_c_slope=0.0)

  num_args = Ketcham07_5_5m+Ketcham07_5_0m+Donelick99+custom_calc
  if isone(num_args)==false
    error("COASTerror: must select only one calculation method
          (probably need to set Ketcham07_5_5m=false)")
  end

  if Ketcham5_5m==true
    (l0_m,l0_c_m) = ketcham5_5_init_len(calc_type,orig_calc,Dpar,OH,Cl,rmr0,
                                        a_vol)
  elseif Ketcham5_0m==true
    (l0_m,l0_c_m) = ketcham5_0_init_len(calc_type,orig_calc,Dpar,OH,Cl,rmr0,
                                        a_vol)
  elseif Donelick99==true
    (l0_m,l0_c_m) = donelick99_init_len(calc_type,orig_calc,Dpar,OH,Cl,rmr0,
                                        a_vol)
  elseif custom_calc==true
    l0_m = custom_slope*custom_param + custom_intercept
    l0_c_m = custom_c_slope*custom_param + custom_c_intercept

  else
    error("COASTerror: Must select at least one l0 calc method!")
  end

  return l0_m,l0_c_m
end

function ketcham5_5_init_len(calc_type,orig_calc,Dpar,OH,Cl,rmr0,a_vol)

  # Dicts w raw data
  # 1st val = unproj slope
  # 2nd val = unproj intercept
  # 3rd val = c proj slope
  # 4th val = c proj intercept
  raw_data_ketcham5_5_hefty = Dict("Dpar"=>[],
                                  "rmr0"=>[],
                                  "OH_apfu"=>[],
                                  "Cl_apfu"=>[]
                                  "a_vol"=>[])
  raw_data_ketcham5_5_original = Dict("Dpar"=>[],
                                  "rmr0"=>[],
                                  "OH_apfu"=>[],
                                  "Cl_apfu"=>[]
                                  "a_vol"=>[])

  if orig_calc==true # use as originally in paper
     (param_in,unproj_slope,unproj_intercept,c_slope,c_intercept
     )= extract_raw_l0_data(raw_data_ketcham5_5_original,calc_type,
                                         Dpar,OH,Cl,rmr0,a_vol)
  elseif (orig_calc==false)  # HeFTy defaults (unpublished)
    (param_in,unproj_slope,unproj_intercept,c_slope,c_intercept
    )= extract_raw_l0_data(raw_data_ketcham5_5_hefty,calc_type,
                                        Dpar,OH,Cl,rmr0,a_vol)
  else
    error("COASTerror: received non-boolean for initial len calculations!")
  end

  l0_m = unproj_slope*param_in + unproj_intercept
  l0_c_m = c_slope*param_in + c_intercept


  return l0_m,l0_c_m
end

function ketcham5_0_init_len(calc_type,orig_calc,Dpar,OH,Cl,rmr0,a_vol)

  # Dicts w raw data
  # 1st val = unproj slope
  # 2nd val = unproj intercept
  # 3rd val = c proj slope
  # 4th val = c proj intercept
  raw_data_ketcham5_0_hefty = Dict("Dpar"=>[],
                                  "rmr0"=>[],
                                  "OH_apfu"=>[],
                                  "Cl_apfu"=>[]
                                  "a_vol"=>[])
  raw_data_ketcham5_0_original = Dict("Dpar"=>[],
                                  "rmr0"=>[],
                                  "OH_apfu"=>[],
                                  "Cl_apfu"=>[]
                                  "a_vol"=>[])

  if orig_calc==true # use as originally in paper
     (param_in,unproj_slope,unproj_intercept,c_slope,c_intercept
     )= extract_raw_l0_data(raw_data_ketcham5_0_original,calc_type,
                                         Dpar,OH,Cl,rmr0,a_vol)
  elseif (orig_calc==false)  # HeFTy defaults (unpublished)
    (param_in,unproj_slope,unproj_intercept,c_slope,c_intercept
    )= extract_raw_l0_data(raw_data_ketcham5_0_hefty,calc_type,
                                        Dpar,OH,Cl,rmr0,a_vol)
  else
    error("COASTerror: received non-boolean for initial len calculations!")
  end

  l0_m = unproj_slope*param_in + unproj_intercept
  l0_c_m = c_slope*param_in + c_intercept


  return l0_m,l0_c_m
end

function donelick99_init_len(calc_type,orig_calc,Dpar,OH,Cl,rmr0,a_vol)

  # Dicts w raw data
  # 1st val = unproj slope
  # 2nd val = unproj intercept
  # 3rd val = c proj slope
  # 4th val = c proj intercept
  raw_data_donelick99_hefty = Dict("Dpar"=>[],
                                  "rmr0"=>[],
                                  "OH_apfu"=>[],
                                  "Cl_apfu"=>[]
                                  "a_vol"=>[])
  raw_data_donelick99_original = Dict("Dpar"=>[],
                                  "rmr0"=>[],
                                  "OH_apfu"=>[],
                                  "Cl_apfu"=>[]
                                  "a_vol"=>[])

  if orig_calc==true # use as originally in paper
     (param_in,unproj_slope,unproj_intercept,c_slope,c_intercept
     )= extract_raw_l0_data(raw_data_donelick99_original,calc_type,
                                         Dpar,OH,Cl,rmr0,a_vol)
  elseif (orig_calc==false)  # HeFTy defaults (unpublished)
    (param_in,unproj_slope,unproj_intercept,c_slope,c_intercept
    )= extract_raw_l0_data(raw_data_donelick99_hefty,calc_type,
                                        Dpar,OH,Cl,rmr0,a_vol)
  else
    error("COASTerror: received non-boolean for initial len calculations!")
  end

  l0_m = unproj_slope*param_in + unproj_intercept
  l0_c_m = c_slope*param_in + c_intercept


  return l0_m,l0_c_m
end

function extract_raw_l0_data(data_dict,calc_type,Dpar,OH,Cl,rmr0,a_vol)

  if calc_type=="Dpar"
    param_in = Dpar
    unproj_slope = data_dict["Dpar"][1]
    unproj_intercept = data_dict["Dpar"][2]
    c_slope = data_dict["Dpar"][3]
    c_intercept = data_dict["Dpar"][4]
  elseif calc_type=="Cl_apfu"
    param_in = Cl
    unproj_slope = data_dict["Cl_apfu"][1]
    unproj_intercept = data_dict["Cl_apfu"][2]
    c_slope = data_dict["Cl_apfu"][3]
    c_intercept = data_dict["Cl_apfu"][4]
  elseif calc_type=="OH_apfu"
    param_in = OH
    unproj_slope = data_dict["OH_apfu"][1]
    unproj_intercept = data_dict["OH_apfu"][2]
    c_slope = data_dict["OH_apfu"][3]
    c_intercept = data_dict["OH_apfu"][4]
  elseif calc_type=="rmr0"
    param_in = rmr0
    unproj_slope = data_dict["rmr0"][1]
    unproj_intercept = data_dict["rmr0"][2]
    c_slope = data_dict["rmr0"][3]
    c_intercept = data_dict["rmr0"][4]
  elseif calc_type=="a_len"
    param_in = a_vol
    unproj_slope = data_dict["a_vol"][1]
    unproj_intercept = data_dict["a_vol"][2]
    c_slope = data_dict["a_vol"][3]
    c_intercept = data_dict["a_vol"][4]
  else
    error("COASTerror: choose calculation type from the following:
          Dpar, Cl_apfu, OH_apfu, rmr0, a_len or specify custom values")
  end

  return param_in,unproj_slope,unproj_intercept,c_slope,c_intercept
end
