library(dplyr)
library(readr)
library(tidyr)
library(purrr)

pre <- read_csv("pre_eharmonize_FA.csv",      show_col_types = FALSE)
qc  <- read_csv("participant_qc_metrics.csv", show_col_types = FALSE)

# QC filter: 635 subjects passing IQR-5 criteria
qc_pass <- qc %>%
  filter(raw_num_bad_slices <= 269.50, mean_fd <= 1.3659,
         raw_neighbor_corr >= 0.7765, max_rel_translation <= 1.6286,
         CNR3_mean >= 0.4196, CNR4_mean >= 0.2491) %>% pull(subjectID)

dat <- pre %>%
  filter(!is.na(Sex), subjectID %in% qc_pass) %>%
  mutate(SexF = if_else(Sex == 1, "Male", "Female"))

# all tract FA columns (exclude the whole-brain average)
regions <- setdiff(grep("_FA$", names(dat), value = TRUE), "AverageFA_FA")

# age effect from FA ~ Age, one sex, one tract
age_effect <- function(col, sex) {
  d <- dat %>% filter(SexF == sex) %>%
    mutate(FA = .data[[col]]) %>% filter(!is.na(FA), !is.na(Age))
  f  <- lm(FA ~ Age, data = d)
  cc <- coef(summary(f))["Age", ]
  tibble(
    beta      = unname(cc["Estimate"]),           # raw: FA units per year
    std_beta  = unname(cc["Estimate"] * sd(d$Age) / sd(d$FA)),  # standardized
    t         = unname(cc["t value"]),
    p         = unname(cc["Pr(>|t|)"]),
    n         = nrow(d)
  )
}

# build table: tract x sex
age_tbl <- expand_grid(region = regions, Sex = c("Male", "Female")) %>%
  mutate(stats = map2(region, Sex, age_effect)) %>%
  unnest(stats) %>%
  arrange(region, Sex)

write_csv(age_tbl, "age_effect_per_tract_by_sex.csv")

cat("tracts:", length(regions), " rows:", nrow(age_tbl), "\n\n")
cat("=== Average FA age effect (for reference) ===\n")
for (s in c("Male", "Female")) {
  a <- age_effect("AverageFA_FA", s)
  cat(sprintf("  %-7s beta=%.5f  std=%.3f  t=%.2f  p=%.3g  (n=%d)\n",
              s, a$beta, a$std_beta, a$t, a$p, a$n))
}
cat("\n=== strongest age effects (by |t|, either sex) ===\n")
print(age_tbl %>% arrange(desc(abs(t))) %>%
        select(region, Sex, std_beta, t, p) %>% head(8), n = 8)
