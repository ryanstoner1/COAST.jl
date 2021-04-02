import chaospy 
from chaospy.example import coordinates, exponential_model, distribution

import numpy
from matplotlib import pyplot
# Sampling schemes we want to include
rules = ["random","halton", "gaussian"]

# Generate samples for different orders:
quadrature_order = 10
number_of_samples = (quadrature_order+1)**2
samples = {
    "random": distribution.sample(
        number_of_samples, rule="random"),
    "halton": distribution.sample(
        number_of_samples, rule="halton"),
    "gaussian": chaospy.generate_quadrature(
        quadrature_order, distribution, rule="gaussian")[0],
}

assert samples["halton"].shape ==  (len(distribution), number_of_samples)
assert samples["gaussian"].shape == (len(distribution), number_of_samples)

evaluations = {}
for rule in rules:
    evaluations[rule] = numpy.array(
        [exponential_model(sample,coordinates=coordinates)
         for sample in samples[rule].T])

assert evaluations["random"].shape == (number_of_samples, len(coordinates))
assert evaluations["halton"].shape == (number_of_samples, len(coordinates))
assert evaluations["gaussian"].shape == (number_of_samples, len(coordinates))

polynomial_order = 4
polynomial_expansion = chaospy.generate_expansion(
    polynomial_order, distribution)
polynomial_expansion[:6].round(5)

model_approximations = {
    rule: chaospy.fit_regression(
        polynomial_expansion, samples[rule], evaluations[rule])
    for rule in rules
}
(model_approximations["random"][:4].round(3),
    model_approximations["halton"][:4].round(3),
 model_approximations["gaussian"][:4].round(3))

sens_t = chaospy.Sens_m(
         model_approximations["halton"], distribution)
print(sens_t[:,0])
# for fig_idx, rule in enumerate(rules, start=1):
#     pyplot.subplot(1, len(rules), fig_idx)

#     mean = chaospy.E(
#         model_approximations[rule], distribution)
#     var = chaospy.Var(
#         model_approximations[rule], distribution)

#     pyplot.fill_between(coordinates, mean-numpy.sqrt(var),
#                         mean+numpy.sqrt(var), alpha=0.3)
#     pyplot.plot(coordinates, mean, "k-")

#     pyplot.xlabel("coordinates $t$")
#     pyplot.ylabel("Model evaluations $u$")
#     pyplot.axis([0, 10, 0, 2])
#     pyplot.title(rule)

#pyplot.show()

def fit_data_kde(data):
    distribution = chaospy.GaussianKDE(data, estimator_rule="silverman")
    return distribution

def get_input_distributions(input_means, input_stds):
    if len(input_means) == 1:
        distribution = chaospy.Normal(input_means[0],input_stds[0])
    else:
        pass
    return distribution

def polychaos_approximate_output(data, distribution, evaluations):
    # for inverse model data inputs = date + additional uncertain inputs into inverse model
    # evaluations = outputs = temperature or other
    polynomial_order = 4
    polynomial_expansion = chaospy.generate_expansion(
        polynomial_order, distribution)
    polynomial_expansion[:6].round(5)

    model_approximations = chaospy.fit_regression(
            polynomial_expansion, data, evaluations)
    return model_approximations
