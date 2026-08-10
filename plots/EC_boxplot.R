library(dplyr)
library(readr)
library(ggplot2)

pre <- read_csv("pre_eharmonize_FA.csv",      show_col_types = FALSE)
qc  <- read_csv("participant_qc_metrics.csv", show_col_types = FALSE)

# QC filter
qc_pass <- qc %>%
  filter(raw_num_bad_slices  <= 269.50, mean_fd <= 1.3659,
         raw_neighbor_corr >= 0.7765, max_rel_translation <= 1.6286,
         CNR3_mean >= 0.4196, CNR4_mean >= 0.2491) %>% pull(subjectID)

dat <- pre %>%
  filter(!is.na(Sex), subjectID %in% qc_pass) %>%
  mutate(
    group = factor(if_else(prodromal_psychosis, "PSS", "Non-PSS"),
                   levels = c("Non-PSS", "PSS")),
    sex   = if_else(Sex == 1, "Male", "Female")
  )

COLORS <- c("Non-PSS" = "#339999", "PSS" = "#9966cc")

ggplot(dat, aes(x = group, y = EC_FA, fill = group)) +
  geom_boxplot(aes(colour = group), outlier.shape = NA, alpha = 0,
               linewidth = 0.6, width = 0.55) +
  geom_dotplot(aes(colour = group), binaxis = "y", stackdir = "center",
               dotsize = 0.4, alpha = 0.85, fill = NA, stroke = 1.5) +
  facet_wrap(~ sex) +
  scale_colour_manual(values = COLORS) +
  scale_fill_manual(values = COLORS) +
  labs(x = "Psychosis Spectrum Symptoms (PSS)", y = "External Capsule FA") +
  theme_minimal() +
  theme(
    axis.line = element_line(colour = "black", linewidth = 1),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_blank(),
    legend.position = "none",
    strip.text = element_text(face = "bold", size = 14),
    axis.title = element_text(face = "bold", size = 14),
    axis.text  = element_text(size = 13)
  )

ggsave("EC_boxplot_faceted.png", width = 5.2, height = 3.9, dpi = 300, bg = "white")