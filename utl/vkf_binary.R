## Volatile Kalman Filter

vkf_bin = function(u,lambda,v0,omega){
  # % Volatile Kalman Filter for binary outcomes (binary VKF)
  # % [predictions, signals] = vkf_bin(lambda,omega,v0,outcomes)
  # % Inputs: 
  #   %       u: column-vector of outcomes
  # %       0<lambda<1, volatility learning rate
  # %       v0>0, initial volatility
  # %       omega>0, noise parameter
  # % Outputs:
  #   %       predictions: predicted state
  # %       signals: a struct that contains signals that might be useful:
  #   %             predictions
  # %               volatility
  # %               learning rate
  # %               prediction error
  # %               volatility prediction error
  # % 
  # % Note: outputs of VKF also depends on initial variance (w0), which is
  # % assumed here w0 = omega
  # % 
  # % See the following paper and equations therein
  # % Piray and Daw, "A simple model for learning in volatile environments"
  # % https://doi.org/10.1101/701466
  
  if (lambda<=0 | lambda>=1){
    print('lambda should be in the unit range')
    return()}
  
  if (omega <= 0 ){
    print('omega should be positive')
    return()}
  
  if (v0<=0 ) {
    print('v0 should be positive');
    return()}
  
  w0 = omega
  
  # TN: number of trials
  TN = length(u)# Get nrows
  
  m = rep(0, TN)
  w = rep(w0, TN)
  v = rep(v0, TN)
  
  predictions = rep(NA, TN)
  learning_rate = rep(NA, TN)
  volatility = rep(NA, TN)
  prediction_error = rep(NA, TN)
  volatility_error = rep(NA, TN)
  
  sigmoid = function(x) {
    1 / (1 + exp(-x))
  }
  
  t = 1; 
  for (t in 1:TN) { 
    o = u[t];
    predictions[t] = m[t];    
    volatility[t] = v[t];    
    mpre        = m;
    wpre        = w;
    delta_m     = o - sigmoid(m);    
    k           = (w+v)/(w+v+ omega);                              # Eq 14
    alpha       = sqrt(w+v);                                       # Eq 15
    m           = m + alpha*delta_m;                               # Eq 16
    w           = (1-k)*(w+v);                                     # Eq 17
    wcov        = (1-k)*wpre;                                      # Eq 18
    delta_v     = (m-mpre)^2 + w + wpre - 2*wcov - v;    
    v           = v + lambda*delta_v;                              # Eq 19
    learning_rate[t] = alpha[t];
    prediction_error[t] = delta_m[t];
    volatility_error[t] = delta_v[t];
  }
  
  signals <- data.frame(
    predictions = predictions,
    volatility = volatility,
    learning_rate = learning_rate,
    prediction_error = prediction_error,
    volatility_prediction_error = volatility_error
  )
  return(signals)
}
