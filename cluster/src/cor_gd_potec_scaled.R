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

# read data
potec <- read.csv("data/potec/potec_expertise.csv", header=TRUE) %>% 
  dplyr::select(PP_ID, trial, text_id_numeric, expert_reading_label_numeric, word_index_in_text, word_with_punct, all_of(measures_col), surp, word_len_punct, zipf_freq) %>% 
  rename(subj = PP_ID,  text = text_id_numeric, expertise = expert_reading_label_numeric, word_id = word_index_in_text, word = word_with_punct, len = word_len_punct, freq = zipf_freq) %>% 
  mutate(
    subj_id = as.integer(factor(subj))
  ) %>%
  group_by(subj_id, trial, text) %>%
  arrange(word_id, .by_group = TRUE) %>%
  mutate(
    prev_len = lag(len),
    prev_freq = lag(freq),
    prev_surp = lag(surp)
  ) %>%
  ungroup() %>%
  filter(surp > 0, prev_surp > 0) %>%
  mutate(
    freq = ifelse(freq == 0, 1, freq),
    prev_freq = ifelse(prev_freq == 0, 1, prev_freq)) %>%
  mutate(
    len = as.numeric(scale(len)),
    freq = as.numeric(scale(freq)),
    surp = as.numeric(scale(surp)),
    prev_len = as.numeric(scale(prev_len)),
    prev_freq = as.numeric(scale(prev_freq)),
    prev_surp = as.numeric(scale(prev_surp))
  ) %>%
  mutate(
    subj = paste0("s", subj),
    text = paste0("t", text)
  ) %>%
  filter(total_duration != 0) %>%
  pivot_longer(cols = all_of(measures_col), names_to = "measures", values_to = "value") %>%
  group_by(measures) %>%
  mutate(
    mean = mean(value, na.rm = TRUE),
    sd = sd(value, na.rm = TRUE)
  ) %>%
  filter((measures %in% c("FPReg", "skip")) | value <= (mean + 5 * sd)) %>%
  ungroup() %>%
  dplyr::select(-mean, -sd) %>%
  mutate(
    c1 = ifelse(expertise == 0, 1, 0), #  non-expert reading
    c2 = ifelse(expertise == 1, 1, 0)  # expert reading
  ) %>%
  drop_na()


# Note this loop can take two days to run!

for(mes in c("gaze_duration")) {
  print(paste0("Fitting model for ", mes))
  
  temp_df <- potec %>%
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
    file = paste0("models/scaled/", "potec_", mes),
    cores = 4,
    backend = "rstan",
    silent = 0,
    prior = priors_rt
  )
}

print("Done fitting models")
