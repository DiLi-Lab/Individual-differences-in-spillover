data {
  int<lower=1> N;
  vector[2] x[N];  // still assumes x is in R^2
}

parameters {
  vector[2] mu;
  real<lower=0> sigma[2];
  real<lower=1> nu;
  real<lower=-1, upper=1> rho;
}

transformed parameters {
  cov_matrix[2] cov;
  cov[1,1] = square(sigma[1]);
  cov[2,2] = square(sigma[2]);
  cov[1,2] = sigma[1] * sigma[2] * rho;
  cov[2,1] = cov[1,2];
}

model {
  sigma ~ lognormal(0, 0.5);
  mu ~ normal(0, 0.5);
  nu ~ gamma(2, 0.1);
  
  x ~ multi_student_t(nu, mu, cov);
}

generated quantities {
  vector[2] x_rand;
  int attempt = 0;
  int max_attempts = 10;

  x_rand = multi_student_t_rng(nu, mu, cov);
  
  // while ((x_rand[1] < 0 || x_rand[2] < 0 || x_rand[1] > 1 || x_rand[2] > 1) && attempt < max_attempts) {
  //   x_rand = multi_student_t_rng(nu, mu, cov);
  //   attempt += 1;
  // }
  // 
  // if (attempt == max_attempts) {
  //   x_rand = rep_vector(0, 2);  // safer fallback
  // }
}
