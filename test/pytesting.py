from SALib.sample import saltelli
from SALib.analyze import sobol
from SALib.test_functions import Ishigami
import numpy as np
# Define the model inputs
problem = {
    'num_vars': 3,
    'names': ['x1', 'x2', 'x3'],
    'bounds': [[-3.14159265359, 3.14159265359],
               [-3.14159265359, 3.14159265359],
               [-3.14159265359, 3.14159265359]]
}

# Generate samples
param_values = saltelli.sample(problem, 1000)
# Run model (example)
Y = Ishigami.evaluate(param_values)

# Perform analysis
Si = sobol.analyze(problem, Y, print_to_console=False)

# Print the first-order sensitivity indices
print(Si['S1'])

# 

#
# Define the model inputs
problem2 = {
    'num_vars': 1,
    'names': ['x1'],
    'bounds': [[-3.14159265359, 3.14159265359]]
}

# Generate samples
param_values2 = saltelli.sample(problem2, 7500)
param_values2 = param_values2.flatten()
noise = np.random.rand(30000)

print(param_values2)
Y2 = param_values2*1.0*noise

# Perform analysis
Si2 = sobol.analyze(problem2, Y2, print_to_console=True)
