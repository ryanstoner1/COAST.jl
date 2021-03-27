# COAST
### Constrained Optimization and Sensitivity for Thermochronology

This package is for thermochronological modeling and has two main focuses: 

- **sensitivity analysis**:  
quantifying how uncertainties in input parameters explain the variance of permissible temperature-time paths and vice-versa using both global and local sensitivity analysis techniques
- **open-source forward and inverse thermochronlogical modeling**:  
a community-oriented resource for thermal history inversion
---

Documentation can be accessed [XXXXX - under construction]

---
#### **COAST** can be accessed in three ways:
---
1. Using the GUI at [coast.thermochron.org](coast.thermochron.org "COAST")
2. Downloading COAST as a Julia package.  

Julia can be downloaded [here](https://julialang.org/downloads/ "available for Mac, Linux, Windows").  

After julia is set up use the package mode (type *]* in the julia REPL):
```julia
    (v1.5) pkg> add https://github.com/ryanstoner1/COAST.jl
```  

It is also possible to clone COAST by pasting
```shell
git clone https://github.com/ryanstoner1/COAST.jl.git
```
in the terminal/shell/command prompt. Moving the folder to ~/.julia/dev/ and using
```julia
    (v1.5) pkg> add COAST.jl
```

3. Use docker [XXXXX - under construction]
