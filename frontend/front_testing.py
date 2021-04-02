from SALib.sample import saltelli
from SALib.analyze import sobol
from SALib.test_functions import Ishigami
import numpy as np
import base64
from coast_app import txtextract
import unittest 

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
        (bound_box, n_extra_constraints, decoded_shortened) = txtextract.extract_Tt_constraints(default_envelope_ind,decoded)
        
        self.assertTrue(bound_box[0][0] == 54.2769230769231)

        (good_acc_bounds, decoded_shortened) = txtextract.extract_Tt_bounds(decoded_shortened)
        (good_time, good_hi, good_lo, acc_time, acc_hi, acc_lo) = good_acc_bounds

        self.assertTrue(good_time[0] == 53.7312462538045)

        (dates, acc_temp_interp, good_temp_interp) = txtextract.interp_Tt_finer_scale(
            good_time, acc_time, decoded_shortened)


# # Define the model inputs
# problem = {
#     'num_vars': 3,
#     'names': ['x1', 'x2', 'x3'],
#     'bounds': [[-3.14159265359, 3.14159265359],
#                [-3.14159265359, 3.14159265359],
#                [-3.14159265359, 3.14159265359]]
# }

# # Generate samples
# param_values = saltelli.sample(problem, 1000)
# # Run model (example)
# Y = Ishigami.evaluate(param_values)

# # Perform analysis
# Si = sobol.analyze(problem, Y, print_to_console=False)

# # Print the first-order sensitivity indices
# print(Si['S1'])

# # 

# #
# # Define the model inputs
# problem2 = {
#     'num_vars': 1,
#     'names': ['x1'],
#     'bounds': [[-3.14159265359, 3.14159265359]]
# }

# # Generate samples
# param_values2 = saltelli.sample(problem2, 7500)
# param_values2 = param_values2.flatten()
# noise = np.random.rand(30000)

# print(param_values2)
# Y2 = param_values2*1.0*noise

# # Perform analysis
# Si2 = sobol.analyze(problem2, Y2, print_to_console=True)
if __name__ == '__main__':
    unittest.main()