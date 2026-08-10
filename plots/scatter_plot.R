library(dplyr)
library(readr)
library(ggplot2)

##QC filter
qc <- read_csv("participant_qc_metrics.csv", show_col_types = FALSE)
qc_pass <- qc %>%
  filter(raw_num_bad_slices <= 269.50, mean_fd <= 1.3659,
         raw_neighbor_corr >= 0.7765, max_rel_translation <= 1.6286,
         CNR3_mean >= 0.4196, CNR4_mean >= 0.2491) %>%
  pull(subjectID)

df <- read_csv("pre_eharmonize_FA.csv", show_col_types = FALSE) %>%
  filter(!is.na(Sex), subjectID %in% qc_pass) %>%
  mutate(
    PSS = if_else(prodromal_psychosis, "PSS", "non-PSS"),
    sex = if_else(Sex == 1, "Male", "Female")
  )

ggplot(df, aes(x = Age, y = AverageFA_FA, colour = PSS)) +
  geom_point(alpha = 0.4, size = 1.5) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 1.2) +
  facet_wrap(~sex) +
  scale_colour_manual(values = c("non-PSS" = "#339999", "PSS" = "#9966cc")) +
  labs(x = "Age at scan", y = "Average FA", colour = NULL) +
  theme_minimal() +
  theme(legend.position = "top",
        legend.direction = "horizontal",
        legend.margin = margin(b = -5),
        legend.box.spacing = unit(2, "pt"))

ggsave("avgFA_age_by_sex_pss.png", width = 5, height = 2.5, dpi = 300, bg = "white")