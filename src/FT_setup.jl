

"""
Dpar - input as either 5.0M or 5.5M case
"""
function init_track_len(;calc_type="Dpar",Dpar=1.65,OH=0.0,Cl=0.0,rmr0=0.0,
  a_vol=0.0,Ketcham07_5_5m=false,Ketcham07_5_0m=false,Donelick99=false,
  orig_calc=true,custom=false,custom_intercept=0.0,custom_slope=0.0,
  custom_param=0.0,custom_c_intercept=0.0,custom_c_slope=0.0)

  num_args = Ketcham07_5_5m+Ketcham07_5_0m+Donelick99+custom
  if isone(num_args)==false
    error("COASTerror: must select only one calculation method
          (probably need to set Ketcham07_5_5m=false)")
  end

  if Ketcham07_5_5m==true
    (l0_m,l0_c_m) = ketcham5_5_init_len(calc_type,orig_calc,Dpar,OH,Cl,rmr0,
                                        a_vol)
  elseif Ketcham07_5_0m==true
    (l0_m,l0_c_m) = ketcham5_0_init_len(calc_type,orig_calc,Dpar,OH,Cl,rmr0,
                                        a_vol)
  elseif Donelick99==true
    (l0_m,l0_c_m) = donelick99_init_len(calc_type,orig_calc,Dpar,OH,Cl,rmr0,
                                        a_vol)
  elseif custom==true
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
  raw_data_ketcham5_5_hefty = Dict("Dpar"=>[0.283,15.63,0.35,15.72],
                                  "rmr0"=>[0.0,16.14,0.0,16.35],
                                  "OH_apfu"=>[0.638,16.04,0.932,16.18],
                                  "Cl_apfu"=>[1.004,16.14,1.197,16.35],
                                  "a_vol"=>[5.519,-35.6,6.4,-43.635])
  raw_data_ketcham5_5_original = Dict("Dpar"=>[0.283,15.63,0.35,15.72],
                                  "rmr0"=>[0.0,16.14,0.0,16.35],
                                  "OH_apfu"=>[0.638,16.04,0.932,16.18],
                                  "Cl_apfu"=>[1.004,16.14,1.197,16.35],
                                  "a_vol"=>[5.519,-35.6,6.4,-43.635])


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
  raw_data_ketcham5_0_hefty = Dict("Dpar"=>[0.258,15.391,0.287,15.582],
                                  "rmr0"=>[0.0,15.936,0.0,16.187],
                                  "OH_apfu"=>[0.0,15.936,0.0,16.187],
                                  "Cl_apfu"=>[0.538,15.936,0.604,16.187],
                                  "a_vol"=>[7.094,-50.702,7.184,-51.287])
  raw_data_ketcham5_0_original = Dict("Dpar"=>[0.258,15.391,0.287,15.582],
                                  "rmr0"=>[0.0,15.936,0.0,16.187],
                                  "OH_apfu"=>[0.0,15.936,0.0,16.187],
                                  "Cl_apfu"=>[0.538,15.936,0.604,16.187],
                                  "a_vol"=>[7.094,-50.702,7.184,-51.287])


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
  raw_data_donelick99_hefty = Dict("Dpar"=>[0.283,15.63,0.35,15.72],
                                  "rmr0"=>[0.0,16.14,0.0,16.35],
                                  "OH_apfu"=>[0.638,16.04,0.932,16.18],
                                  "Cl_apfu"=>[1.004,16.14,1.197,16.35],
                                  "a_vol"=>[5.519,-35.6,6.4,-43.635])
  raw_data_donelick99_original = Dict("Dpar"=>[0.283,15.63,0.35,15.72],
                                  "rmr0"=>[0.0,16.14,0.0,16.35],
                                  "OH_apfu"=>[0.638,16.04,0.932,16.18],
                                  "Cl_apfu"=>[1.004,16.14,1.197,16.35],
                                  "a_vol"=>[5.519,-35.6,6.4,-43.635])

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
