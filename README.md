﻿# optimzation_UC

To do

 - Fix conditions when creating a model: when choosing the booleans parameters in run_solver() (use_uc, use_reserve, etc) model.jl is not creating the correct model for the chosen model. Got to check carefully all the constraints used in specific cases, such as using uc but no using ramps, or using uc with ramps but without reserve. 
 - Create examples of cases using certain configurations of grid.
