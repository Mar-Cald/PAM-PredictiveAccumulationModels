functions {
  // adapted from https://github.com/laurafontanesi/rlssm_R_workshop/blob/main/stan_models/RDM.stan
     real race_pdf(real t, real b, real v){
          real pdf;
          pdf = b/sqrt(2 * pi() * pow(t, 3)) * exp(-pow(v*t-b, 2) / (2*t));
          return pdf;
     }

     real race_cdf(real t, real b, real v){
          real cdf;
          cdf = Phi((v*t-b)/sqrt(t)) + exp(2*v*b) * Phi(-(v*t+b)/sqrt(t));
          return cdf;
     }

     real race_lpdf(matrix RT, vector  ndt, vector b_cor,vector b_inc, vector drift_cor, vector drift_inc){

          real t;
          vector[rows(RT)] prob;
          real cdf;
          real pdf;
          real out;

          for (i in 1:rows(RT)){
               t = RT[i,1] - ndt[i];
               if(t > 0){
                  if(RT[i,2] == 1){
                    pdf = race_pdf(t, b_cor[i], drift_cor[i]);
                    cdf = 1 - race_cdf(t | b_inc[i], drift_inc[i]);
                  }
                  else{
                    pdf = race_pdf(t, b_inc[i], drift_inc[i]);
                    cdf = 1 - race_cdf(t | b_cor[i], drift_cor[i]);
                  }
                  prob[i] = pdf*cdf;

                if(prob[i] < 1e-10){
                    prob[i] = 1e-10;
                }
               }
               else{
                    prob[i] = 1e-10;
               }
          }
          out = sum(log(prob));
          return out;
     }
   // Sigmoid for VKF
  real sigmoid(real x) {
    return 1 / (1 + exp(-x));
  }
}
data {
  int<lower=1> N;	// number of data items
	array[N] int<lower=1, upper=2> choice;
	array[N] real<lower=0> rt;	// rt
	array[N] int<lower=0,upper=1> stim_1; 
  array[N] int<lower=0,upper=1> stim_2; 
}
transformed data {
	matrix [N, 2] RT;
	for (n in 1:N){
		RT[n, 1] = rt[n];
		RT[n, 2] = choice[n];
	}
}
parameters {
  //VKF
  real omega;
  real lambda;
  //RDM
	real ndt; 
	real threshold; 
	real drift;
  real b_a;
  real b_val;
  real b_vol;
}
transformed parameters {
  
  //VKF
  real<lower=0> transf_omega;
  real transf_lambda;

  //loop
  real v;
  real w;
  vector [N] muhat;
  real mpre; // prediction n-1
  real delta_m; // pred error
  real wpre; // variance n-1
  real k; // kalman gain
  real wcov; // covariance
  real u; // input
  real delta_v; //volatility pred error
  real m = 0; //init predictions

  //RDM
	vector<lower=0> [N] drift1_t;				// trial-by-trial drift rate for predictions
	vector<lower=0> [N] drift2_t;				// trial-by-trial drift rate for predictions
	vector<lower=0> [N] threshold1_t;		// trial-by-trial threshold
	vector<lower=0> [N] threshold2_t;		// trial-by-trial threshold
	vector<lower=0> [N] ndt_t;				 // trial-by-trial ndt 

	real<lower=0> transf_drift;
	real<lower=0> transf_threshold;
	real<lower=0> transf_ndt;
  
  // VKF
  transf_omega = log(1 + exp(omega)); // > 0
  transf_lambda = Phi(lambda); // > 0
  
  v = transf_omega;  // Initialize volatilities
  w = transf_omega; // Initialize posterior variances
  
  //RDM
	transf_drift = log(1 + exp(drift)); // > 0
	transf_threshold = log(1 + exp(threshold)); // > 0
	transf_ndt = log(1 + exp(ndt)); // > 0

  // Trial-by-trial
	for (n in 1:N) {
	  //VKF
    u = stim_1[n]; // input
    mpre = m; // prediction
    wpre = w; // variance
    muhat[n] = sigmoid(mpre); 
    
    //RDM
    threshold1_t[n] = transf_threshold + (.5-muhat[n]) * b_a + v * b_vol; //effect of beliefs + volatility
		threshold2_t[n] = transf_threshold + (.5-(1-muhat[n])) * b_a + v * b_vol; 
		drift1_t[n] = transf_drift + stim_1[n] * b_val ; //effect of validity 
		drift2_t[n] = transf_drift + stim_2[n] * b_val ;
		ndt_t[n] = transf_ndt;
		
		//VKF updates
    delta_m     = u - sigmoid(mpre);    //pred error
    k           = (w+v)/(w+v+ transf_omega); //kalman gain                     
    m           = mpre + sqrt(w+v)*delta_m; // pred update                            
    w           = (1-k)*(w+v); // variance                                    
    wcov        = (1-k)*wpre;   // covariance                                   
    delta_v     = (m-mpre)^2 + w + wpre - 2*wcov - v; //volatility pred error
    v           = v + transf_lambda*delta_v; //volatility update
	}
}
model {
  //Prior VKF
  omega ~ normal(0,1);
  lambda ~ normal(0,1);
  //Prior RDM
	ndt ~  normal(-1.5, 1);
	threshold ~ normal(0.5, 1);
	drift ~ normal(0.5, 1);
  b_a ~ normal(0,1);
  b_val ~ normal(0,1);
  b_vol ~ normal(0,1);
  
	RT ~ race(ndt_t, threshold1_t,threshold2_t, drift1_t, drift2_t);
}
generated quantities {
	vector[N] log_lik;
	{
	for (n in 1:N){
		log_lik[n] = race_lpdf(block(RT, n, 1, 1, 2)| segment(ndt_t, n, 1), segment(threshold1_t, n, 1), segment(threshold2_t, n, 1),segment(drift1_t, n, 1), segment(drift2_t, n, 1));
	}
	}
}
