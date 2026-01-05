#!/usr/bin/env Rscript
rm(list=ls())

# print working directory
print(getwd())

# Set locale to English
Sys.setlocale("LC_ALL", "en_US.UTF-8")

library(ggplot2)
library(boot)
library(readr)
library(tidyr)
library(dplyr)
library(gridExtra)
library(lme4)
library(MASS)
library(brms)
library(cmdstanr)

# set priors
priors_rt <- c(
  prior(normal(5.5, 0.1), class = Intercept),
  prior(normal(0, 0.1), class = b),
  prior(exponential(2), class = sd),
  prior(exponential(2), class = sigma),
  prior(lkj(2), class = cor)
)

measures_col <- c("gaze_duration", "first_fixation", "total_duration", "go_past_time", "FPReg", "skip")

et_indico <- read.csv("data/indico/indico_et.csv") %>%
  mutate(word_id = as.integer(word_id), skip = ifelse(FPRT == 0, 1, 0)) %>%
  dplyr::select(subj_id, text_id, screen_id, session_label, word_id, word, FPRT, FD, TFT, RPD_inc, FPReg, skip, word_length, word_length_word_n_minus_1, lex_freq, lex_freq_word_n_minus_1, surprisal, surprisal_word_n_minus_1) %>%
  rename(subj = subj_id,  trial = screen_id, gaze_duration = FPRT, first_fixation = FD, total_duration = TFT, go_past_time = RPD_inc, len = word_length, prev_len = word_length_word_n_minus_1, freq = lex_freq, prev_freq = lex_freq_word_n_minus_1, surp = surprisal, prev_surp = surprisal_word_n_minus_1) %>%
  gather(key = "measures", value = "value", all_of(measures_col)) %>%
  group_by(measures) %>%
  mutate(mean = mean(value, na.rm = TRUE),
         sd = sd(value, na.rm = TRUE)) %>%
  filter((measures %in% c("FPReg", "skip")) | value <= (mean + 5 * sd)) %>%
  ungroup() %>%
  dplyr::select(-mean, -sd) %>%
  mutate(
    subj_id = as.integer(factor(subj)),
    c1 = ifelse(session_label == "ET1", 1, 0),
    c2 = ifelse(session_label == "ET2", 1, 0)
    ) %>%
  drop_na()

# Note this loop can take two days to run!
for(mes in c("gaze_duration")) {
  print(paste0("Fitting model for ", mes))
  
  temp_df <- et_indico %>%
    filter(measures == mes) %>%
    filter(value > 0)
  
  # Fit the model for RT measures
  model <- brms::brm(
    value ~ 1 + c2 + len + freq + surp + prev_len + prev_freq + prev_surp + 
    (0 + c1 + c2 + (len + freq + surp + prev_len + prev_freq + prev_surp):c1 + (len + freq + surp + prev_len + prev_freq + prev_surp):c2 | subj_id),
    data = temp_df,
    chains = 4,
    family = lognormal(),
    warmup = 1000,
    iter = 2000,
    file = paste0("models/scaled/", "indicos_", mes),
    cores = 4,
    backend = "rstan",
    silent = 0,
    control = list(adapt_delta = 0.95,
                max_treedepth = 10),
    prior = priors_rt
  )
}

print("Done fitting models")
