# PAM-PredictiveAccumulationModels

This project implements the **PAM framework** in R/Stan. The Perceptual Model component of this implementation utilizes the Volatile Kalman Filter (VKF). This work is still in progress. Because we are currently unable to recover the initial volatility (v0) and volatility learning rate (lambda), we have set them to omega and 0.1, respectively (users can modify these values). 

## Repository Structure
* ## demo
  - VKF_RDM_tutorial.md: Simulation and Recovery of the combined VKF - Racing Diffusion Model (RDM)
  - u.rds : trial list (input)
* ## utl
  - pdf_rdm.R : probability density function for the RDM
  - vkf_binary.R : VKF translated from matlab code (https://github.com/payampiray/VKF)
* ## stan_models
  - vkf_fixed_rdm.stan: model file with v0 and lambda fixed (RDM code adapted from https://github.com/laurafontanesi/rlssm_R_workshop/blob/main/stan_models/RDM.stan)

-----------------------
## References
- Piray, P., & Daw, N. D. (2020). A simple model for learning in volatile environments. PLoS computational biology, 16(7), e1007963.
- Tillman, G., Van Zandt, T., & Logan, G. D. (2020). Sequential sampling models without random between-trial variability: the racing diffusion model of speeded decision making. Psychonomic bulletin & review, 27(5), 911–936. https://doi.org/10.3758/s13423-020-01719-6

