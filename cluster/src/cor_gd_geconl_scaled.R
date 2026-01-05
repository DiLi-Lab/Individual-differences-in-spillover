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

geconlnl <- read.csv("data/geco-nl/geco_nl_l1nl.csv", header = TRUE) %>% 
  separate(WORD_ID, into = c("part", "w2", "word_id"), sep = "-", remove = FALSE) %>% 
  mutate(word_id = as.integer(word_id)) %>%
  dplyr::select(PP_NR, part, TRIAL, word_id, IA_LABEL, LANGUAGE, all_of(measures_col), word_len_punct, zipf_freq, surp) %>% 
  rename(subj = PP_NR,  trial = TRIAL, word = IA_LABEL, lang = LANGUAGE, len = word_len_punct, freq = zipf_freq) %>% 
  mutate(
    subj_id = as.integer(factor(subj)),
    part = as.integer(part),
    trial = as.integer(trial)
  ) %>%
  mutate(across(all_of(measures_col), ~ as.numeric(ifelse(. == ".", "0", .)))) %>%
  mutate(across(all_of(measures_col), ~ as.numeric(.))) %>%
  group_by(subj_id, part, trial) %>%
  arrange(word_id, .by_group = TRUE) %>%
  mutate(
    prev_len = lag(len),
    prev_freq = lag(freq),
    prev_surp = lag(surp)
  ) %>%
  ungroup() %>%
  filter(freq > 0, prev_freq > 0, surp > 0, prev_surp > 0) %>%
  mutate(
    len = as.numeric(scale(len)),
    freq = as.numeric(scale(freq)),
    surp = as.numeric(scale(surp)),
    prev_len = as.numeric(scale(prev_len)),
    prev_freq = as.numeric(scale(prev_freq)),
    prev_surp = as.numeric(scale(prev_surp))
  ) %>%
  mutate(
    subj = paste0("s", subj)
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
  dplyr::select(-mean, -sd)

geconlen <- read.csv("data/geco-nl/geco_nl_l2en.csv", header = TRUE) %>% 
  separate(WORD_ID, into = c("part", "w2", "word_id"), sep = "-", remove = FALSE) %>% 
  mutate(word_id = as.integer(word_id)) %>%
  dplyr::select(PP_NR, part, TRIAL, word_id, IA_LABEL, LANGUAGE, all_of(measures_col), word_len_punct, zipf_freq, surp) %>% 
  rename(subj = PP_NR,  trial = TRIAL, word = IA_LABEL, lang = LANGUAGE, len = word_len_punct, freq = zipf_freq) %>% 
  mutate(
    subj_id = as.integer(factor(subj)),
    part = as.integer(part),
    trial = as.integer(trial)
  ) %>%
  mutate(across(all_of(measures_col), ~ as.numeric(ifelse(. == ".", "0", .)))) %>%
  mutate(across(all_of(measures_col), ~ as.numeric(.))) %>%
  group_by(subj_id, part, trial) %>%
  arrange(word_id, .by_group = TRUE) %>%
  mutate(
    prev_len = lag(len),
    prev_freq = lag(freq),
    prev_surp = lag(surp)
  ) %>%
  ungroup() %>%
  filter(freq > 0, prev_freq > 0, surp > 0, prev_surp > 0) %>%
  mutate(
    len = as.numeric(scale(len)),
    freq = as.numeric(scale(freq)),
    surp = as.numeric(scale(surp)),
    prev_len = as.numeric(scale(prev_len)),
    prev_freq = as.numeric(scale(prev_freq)),
    prev_surp = as.numeric(scale(prev_surp))
  ) %>%
  mutate(
    subj = paste0("s", subj)
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
  dplyr::select(-mean, -sd)

geconl_l1l2 <- rbind(geconlnl, geconlen)

geconl <- geconl_l1l2 %>%
  mutate(
    c1 = ifelse(lang == "Dutch", 1, 0), #  L1 Dutch reading
    c2 = ifelse(lang == "English", 1, 0)  # L2 English reading
  ) %>%
  drop_na()


# Note this loop can take two days to run!

for(mes in c("gaze_duration")) {
  print(paste0("Fitting model for ", mes))
  
  temp_df <- geconl %>%
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
    file = paste0("models/scaled/", "geconl_", mes),
    cores = 4,
    backend = "rstan",
    silent = 0,
    prior = priors_rt
  )
}

print("Done fitting models")
