
library(dplyr)
library(readr)
library(tidyr)
library(stringr)
library(ggseg)
library(ggplot2)

# read data
fa <- read_csv("pre_eharmonize_FA.csv", show_col_types = FALSE)
qc <- read_csv("participant_qc_metrics.csv", show_col_types = FALSE)

df <- fa %>%
  left_join(qc %>% select(subjectID, mean_fd), by = "subjectID") %>%
  filter(!is.na(Sex)) %>%
  mutate(PSS = factor(if_else(prodromal_psychosis, "PSS", "nonPSS"),
                      levels = c("nonPSS", "PSS")),
         Sex = if_else(Sex == 1, "Male", "Female"))

map <- tribble(
  ~col,        ~region,                                    ~hemi,
  "ACR-L_FA",  "anterior corona radiata",                  "left",
  "ACR-R_FA",  "anterior corona radiata",                  "right",
  "SCR-L_FA",  "superior corona radiata",                  "left",
  "SCR-R_FA",  "superior corona radiata",                  "right",
  "PCR-L_FA",  "posterior corona radiata",                 "left",
  "PCR-R_FA",  "posterior corona radiata",                 "right",
  "ALIC-L_FA", "anterior limb of internal capsule",        "left",
  "ALIC-R_FA", "anterior limb of internal capsule",        "right",
  "PLIC-L_FA", "posterior limb of internal capsule",       "left",
  "PLIC-R_FA", "posterior limb of internal capsule",       "right",
  "RLIC-L_FA", "retrolenticular part of internal capsule", "left",
  "RLIC-R_FA", "retrolenticular part of internal capsule", "right",
  "PTR-L_FA",  "posterior thalamic radiation",             "left",
  "PTR-R_FA",  "posterior thalamic radiation",             "right",
  "SS-L_FA",   "sagittal stratum",                         "left",
  "SS-R_FA",   "sagittal stratum",                         "right",
  "EC-L_FA",   "external capsule",                         "left",
  "EC-R_FA",   "external capsule",                         "right",
  "CGC-L_FA",  "cingulum (cingulate gyrus)",                "left",
  "CGC-R_FA",  "cingulum (cingulate gyrus)",                "right",
  "CGH-L_FA",  "cingulum (hippocampus)",                    "left",
  "CGH-R_FA",  "cingulum (hippocampus)",                    "right",
  "SLF-L_FA",  "superior longitudinal fasciculus",         "left",
  "SLF-R_FA",  "superior longitudinal fasciculus",         "right",
  "SFO-L_FA",  "superior fronto-occipital fasciculus",     "left",
  "SFO-R_FA",  "superior fronto-occipital fasciculus",     "right",
  "UNC-L_FA",  "uncinate fasciculus",                      "left",
  "UNC-R_FA",  "uncinate fasciculus",                      "right",
  "CST-L_FA",  "corticospinal tract",                      "left",
  "CST-R_FA",  "corticospinal tract",                      "right",
  "GCC_FA",    "genu of corpus callosum",                  "midline",
  "BCC_FA",    "body of corpus callosum",                  "midline",
  "SCC_FA",    "splenium of corpus callosum",               "midline"
)

cohens_d <- function(col, sex) {
  d <- df %>% filter(Sex == sex)
  a <- d[[col]][d$PSS == "PSS"]
  b <- d[[col]][d$PSS == "nonPSS"]
  (mean(a, na.rm = TRUE) - mean(b, na.rm = TRUE)) / sd(c(a, b), na.rm = TRUE)
}

eff <- map %>%
  crossing(Sex = c("Male", "Female")) %>%
  mutate(d = mapply(cohens_d, col, Sex))

#read atlas, and figure out if there's anything we need to patch

jhu_wm_atlas <- readRDS("jhu_wm_atlas.rds")

print(jhu_wm_atlas)             
atlas_regions <- brain_regions(jhu_wm_atlas)
atlas_labels  <- brain_labels(jhu_wm_atlas)
print(atlas_regions)
print(atlas_labels)

print(unique(as_tibble(jhu_wm_atlas$data)$hemi))

tryCatch(print(ggseg.formats::atlas_views(jhu_wm_atlas)),
         error = function(e) message("atlas_views() not available in your ggseg version"))

cat("\nRegions in your `map` NOT found in the atlas\n")
print(setdiff(unique(map$region), atlas_regions))

cat("\nRegions in the atlas you're NOT currently using:\n")
print(setdiff(atlas_regions, unique(map$region)))

#add what we need
         
norm <- function(x) str_squish(str_to_lower(x))

atlas_lookup <- as_tibble(jhu_wm_atlas$data) %>%
  distinct(region, hemi) %>%
  mutate(region_norm = norm(region), hemi_norm = norm(hemi))

eff_matched <- eff %>%
  mutate(region_norm = norm(region), hemi_norm = norm(hemi)) %>%
  left_join(atlas_lookup %>% select(region_norm, hemi_norm, region_atlas = region, hemi_atlas = hemi),
            by = c("region_norm", "hemi_norm"))

cat("\nRows that STILL won't match after normalizing case/whitespace:\n")
print(eff_matched %>% filter(is.na(region_atlas)) %>% distinct(region, hemi))

# Use the atlas's own spelling for the actual plot join
eff_final <- eff_matched %>%
  filter(!is.na(region_atlas)) %>%
  transmute(region = region_atlas, hemi = hemi_atlas, Sex, d)

p1 <- ggplot(eff_final |> group_by(Sex)) +
  geom_brain(atlas = jhu_wm_atlas,
             position = position_brain(hemi ~ side),   # lay out all views/hemis
             mapping = aes(fill = d)) +
  facet_wrap(~ Sex, ncol = 1) +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red",
                       midpoint = 0, name = "Cohen's d\n(PSS - non-PSS)") +
  theme_void()

print(p1)
ggsave("pss_effect_brain_patched.png", p1, width = 8, height = 8, dpi = 300, bg = "white")

library(ggsegJHU)

cat("\nRegions available in jhu_tracts():\n")
print(brain_regions(jhu_tracts()))

eff2 <- eff %>%
  mutate(region_norm = norm(region)) %>%
  left_join(
    as_tibble(jhu_tracts()$data) %>% distinct(region) %>% mutate(region_norm = norm(region)),
    by = "region_norm"
  )
cat("\nAny of your regions NOT in jhu_tracts()?\n")
print(eff2 %>% filter(is.na(region.y)) %>% distinct(region.x))

p2 <- ggplot(eff |> group_by(Sex)) +
  geom_brain(atlas = jhu_tracts(),
             position = position_brain(hemi ~ side),
             mapping = aes(fill = d)) +
  facet_wrap(~ Sex, ncol = 1) +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red",
                       midpoint = 0, name = "Cohen's d\n(PSS - non-PSS)") +
  theme_void()

print(p2)
ggsave("pss_effect_brain_jhu_package.png", p2, width = 8, height = 8, dpi = 300, bg = "white")
