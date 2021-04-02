from SALib.sample import saltelli
from SALib.analyze import sobol
from SALib.test_functions import Ishigami
import numpy as np
import base64
import chaospy
from coast_app import txt_read_preprocess
from coast_app import sensitivity_analysis
from matplotlib import pyplot as plt
import unittest 
import scipy
class UsageTesting(unittest.TestCase):

    def test_always_passes(self):
        self.assertTrue(True)

    def test_extract_constraints(self):
        f =  open("testfiles/mo-inv.txt","r") 
        decoded_raw = f.read()
        f.close()
        decoded = str(decoded_raw).splitlines()
        decoded = np.array(decoded)
        
        default_envelope_ind = 6
        
        print("\n starting HeFTy loading tests! \n")
        (bound_box, n_extra_constraints, decoded_shortened) = txt_read_preprocess.extract_Tt_constraints(default_envelope_ind,decoded)
        
        self.assertTrue(bound_box[0][0] == 54.2769230769231)

        (good_acc_bounds, decoded_shortened) = txt_read_preprocess.extract_Tt_bounds(decoded_shortened)
        (good_time, good_hi, good_lo, acc_time, acc_hi, acc_lo) = good_acc_bounds

        self.assertTrue(good_time[0] == 53.7312462538045)

        (dates, acc_temp_interp, good_temp_interp) = txt_read_preprocess.interp_Tt_finer_scale(
            good_time, acc_time, decoded_shortened)

    def test_sensitivity_analysis_wout_backend(self):
        f =  open("testfiles/mo-inv.txt","r") 
        decoded_raw = f.read()
        f.close()
        decoded = str(decoded_raw).splitlines()
        decoded = np.array(decoded)
        default_envelope_ind = 6
        
        print("\n starting sensitivity tests! \n")

        # same as test 2 to setup
        (bound_box, n_extra_constraints, decoded_shortened) = txt_read_preprocess.extract_Tt_constraints(default_envelope_ind,decoded)
        (good_acc_bounds, decoded_shortened) = txt_read_preprocess.extract_Tt_bounds(decoded_shortened)
        (good_time, good_hi, good_lo, acc_time, acc_hi, acc_lo) = good_acc_bounds
        (dates, acc_temp_interp, good_temp_interp) = txt_read_preprocess.interp_Tt_finer_scale(
            good_time, acc_time, decoded_shortened)
        # end same as test 2

# # Perform analysis
# Si2 = sobol.analyze(problem2, Y2, print_to_console=True)
if __name__ == '__main__':
    unittest.main()