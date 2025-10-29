library(tidyverse)
library(ggplot2)

# Suppress automatic plotting to PDF (prevents Rplots.pdf)
pdf(NULL)

getwd()

#read in raw data and combine time points into one data frame
pam1<- read.csv("data/raw/pam/20230603_pam.csv")%>%select(-X)
pam2<- read.csv("data/raw/pam/20230619_pam.csv")%>% select_if(~ !any(is.na(.)))
combined<- rbind(pam1, pam2)%>%mutate(genus=as.factor(genus))

#read in info about samples (i.e., treatments) 
sample_info<- read.csv("data/metadata/sample_info.csv")

#filter by genus 
samp_info_acr<- sample_info%>%
  filter(genus == "acr")%>%select(treatment, coral_id, genus)
samp_info_por<- sample_info%>%
  filter(genus == "por")%>%select(treatment, coral_id, genus)
###################### NOT AVERAGED Fv/Fm ###################################### #####
#filter acr by genus and date, doing do this to average replicate fv/fm values from 1 timepoint
acr_only <- combined %>%
  filter(genus == "acr")
acr_only_20230603 <- acr_only %>%
  filter(date == 20230603)
acr_only_20230619 <- acr_only %>%
  filter(date == 20230619)

#filter por by date
por_only <- combined %>%
  filter(genus == "por")
por_only_20230603 <- por_only %>%
  filter(date == 20230603)
por_only_20230619 <- por_only %>%
  filter(date == 20230619)


acr_only_full<- left_join(acr_only, samp_info_acr, by = "coral_id")
view(acr_only_full)
acr_only_full<- acr_only_full%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))

# Exploratory plots commented out to avoid Rplots.pdf
# ggplot(acr_only_full, aes(x = treatment, y = fv_fm)) +
#   geom_boxplot() +
#   ylab('fv/fm') +
#   xlab('treatment')+
#   facet_wrap(~ date)

por_only_full<- left_join(por_only, samp_info_por, by = "coral_id")
view(por_only_full)
por_only_full<- por_only_full%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))

# Exploratory plots commented out to avoid Rplots.pdf
# ggplot(por_only_full, aes(x = treatment, y = fv_fm)) +
#   geom_boxplot() +
#   ylab('fv/fm') +
#   xlab('treatment')+
#   facet_wrap(~ date)

combined_full<-rbind(acr_only_full, por_only_full)%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))
combined_full<- combined_full%>%select(-genus.y)
combined_full<- combined_full%>%rename(genus = genus.x)

write.csv(combined_full, 'data/processed/pam/all_fvfm.csv')
###################### AVERAGING FV/FM ######################################### #####
#acr average 
acr_avg_20230603 <- acr_only_20230603 %>%
  group_by(coral_id) %>%
  summarize(average_fv_fm = mean(fv_fm))
acr_avg_20230619 <- acr_only_20230619 %>%
  group_by(coral_id) %>%
  summarize(average_fv_fm = mean(fv_fm))

#combining averaged acr data for timepoint 1 with sample info 
acr_full_20230603<- left_join(acr_avg_20230603, samp_info_acr, by = "coral_id")
acr_full_20230603<- acr_full_20230603%>%mutate(date = 20230603)
view(acr_full_20230603)
#combining averaged acr data for timepoint 2 with sample info 
acr_full_20230619<- left_join(acr_avg_20230619, samp_info_acr, by = "coral_id")
acr_full_20230619<- acr_full_20230619%>%mutate(date = 20230619)
view(acr_full_20230619)

#por average
por_avg_20230603 <- por_only_20230603 %>%
  group_by(coral_id) %>%
  summarize(average_fv_fm = mean(fv_fm))
por_avg_20230619 <- por_only_20230619 %>%
  group_by(coral_id) %>%
  summarize(average_fv_fm = mean(fv_fm))

#combining averaged por data for timepoint 1 with sample info 
por_full_20230603<- left_join(por_avg_20230603, samp_info_por, by = "coral_id")
por_full_20230603<- por_full_20230603%>%mutate(date = 20230603)
view(por_full_20230603)
#combining averaged por data for timepoint 2 with sample info 
por_full_20230619<- left_join(por_avg_20230619, samp_info_por, by = "coral_id")
por_full_20230619<- por_full_20230619%>%mutate(date = 20230619)
view(por_full_20230619)

#combining all averaged fv/fm data
final_PAM<- rbind(acr_full_20230603, acr_full_20230619, por_full_20230603, por_full_20230619 )
final_PAM<- final_PAM%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))

write.csv(final_PAM, 'data/processed/pam/average_fvfm.csv')

###################### VISUALIZING AVG FV/FM POR & ACR ######################### #####
#read in data 
average<- read.csv("data/processed/pam/average_fvfm.csv")%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))
view(average)

ggplot(average, aes(x = treatment, y = average_fv_fm, fill = date)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ genus)

ggplot(average, aes(x = date, y = average_fv_fm, color = genus)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('timepoint')+
  facet_wrap(~ treatment, scales = "free")

ggplot(average, aes(x = genus, y = average_fv_fm, color = date)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('genus')+
  facet_wrap(~ treatment, scales = "free")

ggplot(average, aes(x = treatment, y = average_fv_fm)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ genus)

ggplot(average, aes(x = treatment, y = average_fv_fm, color = genus)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ date)

###################### AVG POR ONLY ############################################ #####

final_POR<- rbind( por_full_20230603, por_full_20230619)

final_POR<- final_PAM%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))
ggplot(final_POR, aes(x = date, y = average_fv_fm, color = treatment)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('timepoint')

ggplot(final_POR, aes(x = treatment, y = average_fv_fm)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ date)

ggplot(final_POR, aes(x = treatment, y = average_fv_fm)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ date)

###################### AVG ACR ONLY ############################################ #####
final_ACR<- rbind(acr_full_20230603, acr_full_20230619)
final_ACR<- final_ACR%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))

ggplot(final_ACR, aes(x = treatment, y = average_fv_fm)) +
  geom_boxplot() +
  ylab('fv/fm') +
  xlab('treatment')+
  facet_wrap(~ date)



























data<- read.csv("data/processed/pam/all_fvfm.csv")%>%mutate(date=as.factor(date))%>%mutate(treatment=as.factor(treatment))
view(data)
# Suppress exploratory plots to avoid Rplots.pdf
invisible(dev.off())  # Close any open devices

# ==============================================================================
# PUBLICATION-QUALITY FIGURES
# ==============================================================================

# Define labels
treatment_labels <- c("0" = "Control", "1" = "Small Wound", "2" = "Large Wound")
date_labels <- c("20230603" = "Day 7", "20230619" = "Day 23")
genus_labels <- c("acr" = "Acropora pulchra", "por" = "Porites sp.")

# Figure 1: Fv/Fm by Treatment and Timepoint (both genera)
p1 <- ggplot(data, aes(x = treatment, y = fv_fm, fill = treatment)) +
  geom_boxplot(outlier.shape = 21, outlier.size = 2, alpha = 0.8) +
  geom_jitter(width = 0.2, alpha = 0.3, size = 1.5) +
  facet_grid(genus ~ date,
             labeller = labeller(genus = genus_labels,
                                date = date_labels)) +
  scale_fill_manual(
    values = c("0" = "#2E86AB", "1" = "#A23B72", "2" = "#F18F01"),
    labels = treatment_labels,
    name = "Treatment"
  ) +
  scale_x_discrete(labels = treatment_labels) +
  labs(
    title = "Photosynthetic Efficiency by Wound Treatment",
    subtitle = "Measured by PAM fluorometry (Fv/Fm)",
    x = "",
    y = expression(F[v]/F[m])
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 11, hjust = 0.5, color = "gray30"),
    axis.title = element_text(face = "bold", size = 12),
    axis.text = element_text(size = 10, color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom",
    strip.background = element_rect(fill = "gray95", color = "black"),
    strip.text.x = element_text(face = "bold", size = 11),
    strip.text.y = element_text(face = "bold.italic", size = 11),
    panel.grid.major.y = element_line(color = "gray90", linetype = "dashed"),
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1)
  )

ggsave("reports/Figures/pam_fvfm_by_treatment_timepoint.png", p1,
       width = 9, height = 7, dpi = 300, bg = "white")

# Figure 2: Time series for Porites
p2_por <- data %>%
  filter(genus == "por") %>%
  ggplot(aes(x = date, y = fv_fm, color = treatment, group = treatment)) +
  stat_summary(fun = mean, geom = "line", linewidth = 1.2) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun.data = mean_se, geom = "errorbar",
               width = 0.1, linewidth = 1) +
  scale_color_manual(
    values = c("0" = "#2E86AB", "1" = "#A23B72", "2" = "#F18F01"),
    labels = treatment_labels,
    name = "Treatment"
  ) +
  scale_x_discrete(labels = date_labels) +
  labs(
    title = expression(paste(italic("Porites"), " sp. - Photosynthetic Efficiency Over Time")),
    x = "Time Post-Wounding",
    y = expression(F[v]/F[m])
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    axis.title = element_text(face = "bold", size = 12),
    axis.text = element_text(size = 11, color = "black"),
    legend.position = "right",
    panel.grid.major.y = element_line(color = "gray90", linetype = "dashed"),
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1)
  )

ggsave("reports/Figures/pam_porites_timeseries.png", p2_por,
       width = 7, height = 5, dpi = 300, bg = "white")

# Figure 3: Time series for Acropora
p2_acr <- data %>%
  filter(genus == "acr") %>%
  ggplot(aes(x = date, y = fv_fm, color = treatment, group = treatment)) +
  stat_summary(fun = mean, geom = "line", linewidth = 1.2) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun.data = mean_se, geom = "errorbar",
               width = 0.1, linewidth = 1) +
  scale_color_manual(
    values = c("0" = "#2E86AB", "1" = "#A23B72", "2" = "#F18F01"),
    labels = treatment_labels,
    name = "Treatment"
  ) +
  scale_x_discrete(labels = date_labels) +
  labs(
    title = expression(paste(italic("Acropora pulchra"), " - Photosynthetic Efficiency Over Time")),
    x = "Time Post-Wounding",
    y = expression(F[v]/F[m])
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    axis.title = element_text(face = "bold", size = 12),
    axis.text = element_text(size = 11, color = "black"),
    legend.position = "right",
    panel.grid.major.y = element_line(color = "gray90", linetype = "dashed"),
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1)
  )

ggsave("reports/Figures/pam_acropora_timeseries.png", p2_acr,
       width = 7, height = 5, dpi = 300, bg = "white")

cat("\n✓ Publication-quality PAM figures saved:\n")
cat("  - reports/Figures/pam_fvfm_by_treatment_timepoint.png\n")
cat("  - reports/Figures/pam_porites_timeseries.png\n")
cat("  - reports/Figures/pam_acropora_timeseries.png\n\n")








