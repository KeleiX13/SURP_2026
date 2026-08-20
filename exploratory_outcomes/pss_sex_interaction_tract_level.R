library(dplyr)
library(readr)
library(tidyr)
library(purrr)

pre  <- read_csv("pre_eharmonize_FA.csv",       show_col_types = FALSE)
post <- read_csv("post_eharmonize_FA.csv",      show_col_types = FALSE)
qc   <- read_csv("participant_qc_metrics.csv",  show_col_types = FALSE)

meta    <- c("subjectID", "Age", "Sex", "prodromal_psychosis")
regions <- setdiff(intersect(names(pre), names(post)), meta)

to_long <- function(df, stage) {
  df %>%
    filter(!is.na(Sex)) %>%
    left_join(qc %>% select(subjectID, mean_fd), by = "subjectID") %>%
    select(subjectID, Sex, Age, mean_fd, prodromal_psychosis, all_of(regions)) %>%
    pivot_longer(all_of(regions), names_to = "region", values_to = "FA") %>%
    mutate(
      stage = stage,
      PSS = factor(if_else(prodromal_psychosis, "PSS", "NonPSS"),
                   levels = c("NonPSS", "PSS")),
      SexF = factor(if_else(Sex == 1, "Male", "Female"),
                    levels = c("Female", "Male"))
    )
}

# For one region slice, fit raw & adjusted interaction models, pull sex-by-PSS term
interaction_stats <- function(d) {
  sd_fa <- sd(d$FA, na.rm = TRUE)                 # for standardizing the coefficient
  term  <- "PSSPSS:SexFMale"                      # the PSS x Sex interaction term

  grab <- function(fit) {
    cf <- coef(summary(fit))
    if (!term %in% rownames(cf)) return(c(b = NA_real_, p = NA_real_))
    c(b = unname(cf[term, "Estimate"]),
      p = unname(cf[term, "Pr(>|t|)"]))
  }

  raw <- tryCatch(grab(lm(FA ~ PSS * SexF, data = d)),
                  error = function(e) c(b = NA_real_, p = NA_real_))
  dadj <- d %>% filter(!is.na(mean_fd), !is.na(Age))
  adj <- tryCatch(grab(lm(FA ~ PSS * SexF + Age + mean_fd, data = dadj)),
                  error = function(e) c(b = NA_real_, p = NA_real_))

  tibble(
    b_int_raw = raw["b"], d_int_raw = raw["b"] / sd_fa, p_int_raw = raw["p"],
    b_int_adj = adj["b"], d_int_adj = adj["b"] / sd_fa, p_int_adj = adj["p"],
    n = nrow(d)
  )
}

stats_for_stage <- function(df, stage) {
  to_long(df, stage) %>%
    group_by(region) %>%
    group_modify(~ interaction_stats(.x)) %>%
    ungroup() %>%
    mutate(stage = stage)
}

s_pre  <- stats_for_stage(pre,  "pre")
s_post <- stats_for_stage(post, "post")

# join pre & post side by side
interaction_table <- s_post %>%
  select(region, n,
         d_int_raw_post = d_int_raw, p_int_raw_post = p_int_raw,
         d_int_adj_post = d_int_adj, p_int_adj_post = p_int_adj) %>%
  left_join(
    s_pre %>% select(region,
                     d_int_raw_pre = d_int_raw, p_int_raw_pre = p_int_raw,
                     d_int_adj_pre = d_int_adj, p_int_adj_pre = p_int_adj),
    by = "region"
  ) %>%
  select(region, n,
         d_int_raw_pre,  d_int_raw_post,
         p_int_raw_pre,  p_int_raw_post,
         d_int_adj_pre,  d_int_adj_post,
         p_int_adj_pre,  p_int_adj_post) %>%
  arrange(region)

write_csv(interaction_table, "pss_sex_interaction_per_region.csv")

cat("Done. Regions:", nrow(interaction_table), "\n")
cat("Interaction term = PSS x Sex (positive d = PSS effect more positive in males).\n")
