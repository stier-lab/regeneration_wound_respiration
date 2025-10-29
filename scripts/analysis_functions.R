# ==============================================================================
# ANALYSIS FUNCTIONS FOR WOUND RESPIRATION PROJECT
# Extracted from "similar analysis" Acropora Regeneration Project
# Created: 2025-10-27
# ==============================================================================

# Required Libraries -----------------------------------------------------------
# Note: Libraries should be loaded in the main script before sourcing this file
# This file only contains function definitions

# Check if required packages are available (don't load them, just check)
required_pkgs <- c("tidyverse", "lmerTest", "emmeans", "rstatix", "janitor", "ggthemes")
missing_pkgs <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  warning("Missing required packages: ", paste(missing_pkgs, collapse = ", "))
}

# Data Cleaning Functions ------------------------------------------------------

#' Remove specific corals from dataset
#' @param data Dataframe containing coral data
#' @param coral_ids Vector of coral IDs to remove
#' @return Filtered dataframe
remove_corals <- function(data, coral_ids) {
  data <- data[!(data$coral_id %in% coral_ids), ]
  return(data)
}

#' Convert timepoint labels to numeric values
#' @param data Dataframe with timepoint column
#' @param timepoint_col Name of timepoint column (default: "timepoint")
#' @return Dataframe with numeric timepoint values
convert_timepoint_to_numeric <- function(data, timepoint_col = "timepoint") {
  data %>%
    mutate(!!timepoint_col := case_when(
      get(timepoint_col) == "day0" | get(timepoint_col) == "initial" ~ "0",
      get(timepoint_col) == "day1" | get(timepoint_col) == "postwound" ~ "1",
      get(timepoint_col) == "day7" ~ "7",
      get(timepoint_col) == "day10" ~ "10",
      get(timepoint_col) == "day19" | get(timepoint_col) == "final" ~ "19",
      TRUE ~ as.character(get(timepoint_col))
    )) %>%
    mutate(!!timepoint_col := as.numeric(get(timepoint_col)))
}

#' Convert treatment columns to factors
#' @param data Dataframe
#' @param factor_cols Vector of column names to convert to factors
#' @return Dataframe with specified columns as factors
convert_to_factors <- function(data, factor_cols = c("temp", "wound", "genotype", "genus")) {
  for (col in factor_cols) {
    if (col %in% names(data)) {
      data[[col]] <- as.factor(data[[col]])
    }
  }
  return(data)
}

#' Create wound treatment labels (binary: Control vs Injured)
#' @param data Dataframe with wound column
#' @return Dataframe with wound2 column added
create_wound_binary <- function(data) {
  data %>%
    mutate(wound2 = case_when(
      wound == "0" ~ "Control",
      wound == "1" ~ "Injured",
      wound == "2" ~ "Injured"
    ))
}

# Statistical Analysis Functions -----------------------------------------------

#' Run linear mixed model with standard contrasts
#' @param data Dataframe
#' @param formula Model formula
#' @param filter_var Optional variable to filter (e.g., rate == "Respiration")
#' @return lmer model object
run_lmer_model <- function(data, formula, filter_var = NULL) {
  if (!is.null(filter_var)) {
    data <- data %>% filter(!!rlang::parse_expr(filter_var))
  }

  mod <- lmer(formula,
              data = data,
              contrasts = list(wound = "contr.sum"))

  return(mod)
}

#' Run model and extract ANOVA table
#' @param model lmer model object
#' @param type Type of sums of squares (default: 3)
#' @return ANOVA table
get_anova_table <- function(model, type = 3) {
  anova(model, type = type)
}

#' Run pairwise comparisons with Tukey adjustment
#' @param model lmer model object
#' @param factors Formula for comparison (e.g., ~wound*temp)
#' @return emmeans object with pairwise comparisons
get_pairwise_comparisons <- function(model, factors) {
  emm <- emmeans(model, as.formula(paste0("~", factors)))
  pairs <- pairs(emm, adjust = "tukey")
  return(list(emmeans = emm, pairwise = pairs))
}

# Data Summarization Functions -------------------------------------------------

#' Calculate summary statistics by group
#' @param data Dataframe
#' @param measure_var Name of variable to summarize
#' @param group_vars Vector of grouping variables
#' @return Summary dataframe with mean, SE, CI
calculate_summary_stats <- function(data, measure_var, group_vars) {
  summarySE(data,
            measurevar = measure_var,
            groupvars = group_vars,
            na.rm = TRUE,
            conf.interval = 0.95)
}

#' Calculate mean and standard error for plotting
#' @param data Dataframe
#' @param measure_var Variable to summarize
#' @param group_vars Grouping variables
#' @return List with means and standard errors
calculate_mean_se_for_plot <- function(data, measure_var, group_vars) {
  # Calculate means
  means <- data %>%
    group_by(across(all_of(group_vars))) %>%
    summarize(
      Mean = mean(get(measure_var), na.rm = TRUE),
      N = n(),
      .groups = "drop"
    )

  # Calculate standard error
  # First create treatment combination column
  data_with_treatment <- data %>%
    unite("treatment", all_of(group_vars), remove = FALSE)

  std_err <- data_with_treatment %>%
    group_by(treatment) %>%
    summarize(
      SE = sd(get(measure_var), na.rm = TRUE) / sqrt(n()),
      .groups = "drop"
    ) %>%
    separate(treatment, into = group_vars, sep = "_")

  return(list(means = means, std_err = std_err))
}

# Respiration-Specific Functions -----------------------------------------------

#' Calculate P:R ratio from rates data
#' @param data Dataframe with rates in long format
#' @param rate_col Name of rate type column
#' @param value_col Name of rate value column
#' @return Dataframe with P:R ratio calculated
calculate_pr_ratio <- function(data, rate_col = "rate", value_col = "umol.cm2.hr") {
  # Convert to wide format
  data_wide <- data %>%
    filter(get(rate_col) != "Net Photosynthesis") %>%
    select(coral_id, temp, wound, genotype, timepoint, all_of(c(rate_col, value_col))) %>%
    pivot_wider(names_from = all_of(rate_col),
                values_from = all_of(value_col)) %>%
    clean_names()

  # Calculate ratio: (12h * P) / (24h * R)
  data_wide <- data_wide %>%
    mutate(pr_ratio = (12 * gross_photosynthesis) / (24 * respiration))

  return(data_wide)
}

#' Calculate gross photosynthesis from net photosynthesis and respiration
#' @param data Dataframe with net_photo and respiration columns
#' @return Dataframe with gross_photo calculated
calculate_gross_photosynthesis <- function(data) {
  data %>%
    mutate(gross_photo = net_photo + abs(respiration))
}

# Growth Analysis Functions ----------------------------------------------------

#' Calculate growth rate from buoyant weights
#' @param data Dataframe with initial and final weights
#' @param initial_col Name of initial weight column
#' @param final_col Name of final weight column
#' @param days Number of days between measurements
#' @return Dataframe with growth rate added
calculate_growth_rate <- function(data, initial_col, final_col, days) {
  data %>%
    mutate(growth_rate = (get(final_col) - get(initial_col)) / days)
}

#' Normalize growth rate to surface area
#' @param data Dataframe with growth_rate and surface area
#' @param sa_col Name of surface area column
#' @return Dataframe with normalized growth rate
normalize_growth_to_sa <- function(data, sa_col = "surface_area_cm2") {
  data %>%
    mutate(growth_norm = growth_rate / get(sa_col))
}

# Visualization Functions ------------------------------------------------------

#' Create barplot with error bars and individual points
#' @param mean_data Dataframe with mean values
#' @param raw_data Dataframe with raw data for points
#' @param x_var X-axis variable
#' @param y_var Y-axis variable (mean)
#' @param y_var_raw Y-axis variable in raw data
#' @param facet_var Faceting variable
#' @param fill_var Fill variable (for color)
#' @param error_data Dataframe with standard errors
#' @param y_label Y-axis label
#' @param x_label X-axis label
#' @param facet_labels Named vector for facet labels
#' @param letters Optional vector of significance letters
#' @return ggplot object
create_barplot_with_points <- function(mean_data, raw_data,
                                       x_var, y_var, y_var_raw,
                                       facet_var, fill_var,
                                       error_data,
                                       y_label, x_label,
                                       facet_labels = NULL,
                                       letters = NULL) {

  p <- ggplot(mean_data, aes(x = get(x_var), y = get(y_var),
                             colour = get(fill_var), fill = get(fill_var))) +
    geom_bar(stat = "identity", position = "dodge") +
    geom_errorbar(aes(ymin = get(y_var) - error_data[[y_var_raw]],
                     ymax = get(y_var) + error_data[[y_var_raw]]),
                 width = 0,
                 position = position_dodge(width = 0.9)) +
    geom_point(data = raw_data,
               aes(x = get(x_var), y = get(y_var_raw), colour = get(fill_var)),
               shape = 21, alpha = 0.7,
               position = position_jitterdodge(jitter.width = 0.3,
                                              jitter.height = 0.2,
                                              dodge.width = 0.9)) +
    scale_color_manual(values = c('black', 'black'), guide = "none") +
    scale_fill_manual(values = c('white', 'grey'), guide = "none") +
    xlab(x_label) +
    ylab(y_label) +
    theme_few(base_size = 12) +
    theme(axis.text.x = element_text(colour = "black"),
          axis.text.y = element_text(colour = "black"))

  # Add faceting if specified
  if (!is.null(facet_var)) {
    if (!is.null(facet_labels)) {
      p <- p + facet_wrap(as.formula(paste0("~", facet_var)),
                         labeller = labeller(.default = facet_labels))
    } else {
      p <- p + facet_wrap(as.formula(paste0("~", facet_var)))
    }
  }

  # Add significance letters if provided
  if (!is.null(letters)) {
    mean_data$letters <- letters
    p <- p + geom_text(aes(label = letters), nudge_y = 0.32, color = "black")
  }

  return(p)
}

#' Create time series plot with error bars
#' @param data Dataframe
#' @param x_var X-axis variable (typically timepoint)
#' @param y_var Y-axis variable
#' @param color_var Color grouping variable
#' @param facet_formula Formula for faceting (e.g., "rate~wound")
#' @param y_label Y-axis label
#' @param x_label X-axis label
#' @param color_label Legend title
#' @param color_values Vector of colors
#' @param color_labels Vector of color labels
#' @param facet_labels Named list for facet labels
#' @return ggplot object
create_timeseries_plot <- function(data, x_var, y_var, color_var,
                                   facet_formula = NULL,
                                   y_label, x_label,
                                   color_label = NULL,
                                   color_values = c('blue', 'red'),
                                   color_labels = NULL,
                                   facet_labels = NULL) {

  p <- ggplot(data = data, aes(x = get(x_var), y = get(y_var), col = get(color_var))) +
    stat_summary(fun.data = mean_se, geom = "errorbar",
                width = 0.2, position = position_dodge(width = 0.2)) +
    stat_summary(fun = "mean", geom = "point", size = 3,
                position = position_dodge(width = 0.2)) +
    stat_summary(fun = "mean", geom = "line", size = 1,
                position = position_dodge(width = 0.2),
                linetype = "dashed", aes(group = get(color_var))) +
    ylab(y_label) +
    xlab(x_label) +
    theme_classic() +
    theme_few(base_size = 12)

  # Add color scale
  if (!is.null(color_label)) {
    if (!is.null(color_labels)) {
      p <- p + scale_color_manual(values = color_values,
                                  labels = color_labels,
                                  name = color_label)
    } else {
      p <- p + scale_color_manual(values = color_values, name = color_label)
    }
  } else {
    p <- p + scale_color_manual(values = color_values)
  }

  # Add faceting if specified
  if (!is.null(facet_formula)) {
    if (!is.null(facet_labels)) {
      p <- p + facet_grid(as.formula(facet_formula),
                         labeller = labeller(.default = facet_labels),
                         scales = "free_y", space = "free")
    } else {
      p <- p + facet_grid(as.formula(facet_formula),
                         scales = "free_y", space = "free")
    }
  }

  return(p)
}

#' Create boxplot by treatment groups
#' @param data Dataframe
#' @param x_var X-axis variable
#' @param y_var Y-axis variable
#' @param color_var Color variable
#' @param facet_var Optional faceting variable
#' @param y_label Y-axis label
#' @param x_label X-axis label
#' @return ggplot object
create_boxplot <- function(data, x_var, y_var, color_var,
                          facet_var = NULL,
                          y_label, x_label) {

  p <- ggplot(data = data, aes(x = get(x_var), y = get(y_var), col = get(color_var))) +
    geom_boxplot() +
    ylab(y_label) +
    xlab(x_label) +
    theme_few(base_size = 12)

  if (!is.null(facet_var)) {
    p <- p + facet_wrap(as.formula(paste0("~", facet_var)))
  }

  return(p)
}

# Data Import Functions --------------------------------------------------------

#' Load and combine multiple timepoint data files
#' @param file_paths Named vector of file paths (names = timepoint labels)
#' @param sheet_name Excel sheet name (if applicable)
#' @param id_col Name of ID column (default: "coral_id")
#' @return Combined dataframe with timepoint column
load_timepoint_data <- function(file_paths, sheet_name = NULL, id_col = "coral_id") {
  data_list <- list()

  for (timepoint in names(file_paths)) {
    if (!is.null(sheet_name)) {
      data_list[[timepoint]] <- read_xlsx(file_paths[timepoint], sheet = sheet_name) %>%
        clean_names() %>%
        mutate(timepoint = timepoint)
    } else {
      data_list[[timepoint]] <- read_csv(file_paths[timepoint]) %>%
        clean_names() %>%
        mutate(timepoint = timepoint)
    }
  }

  combined_data <- bind_rows(data_list)
  return(combined_data)
}

# Model Comparison Functions ---------------------------------------------------

#' Compare nested models using likelihood ratio test
#' @param full_model Full lmer model
#' @param reduced_model Reduced lmer model
#' @return Comparison results
compare_nested_models <- function(full_model, reduced_model) {
  comparison <- anova(full_model, reduced_model)
  return(comparison)
}

#' Extract model summary table
#' @param model lmer model object
#' @param include_random Include random effects? (default: TRUE)
#' @return Summary table
extract_model_summary <- function(model, include_random = TRUE) {
  summ <- summary(model)

  results <- list(
    fixed_effects = as.data.frame(coef(summ)),
    anova = anova(model, type = 3)
  )

  if (include_random) {
    results$random_effects <- as.data.frame(VarCorr(model))
  }

  return(results)
}

# File Saving Functions --------------------------------------------------------

#' Save plot with standard settings
#' @param plot ggplot object
#' @param filename File name
#' @param path Directory path
#' @param width Width in inches (default: 8)
#' @param height Height in inches (default: 8)
#' @param dpi Resolution (default: 300)
save_plot_standard <- function(plot, filename, path,
                              width = 8, height = 8, dpi = 300) {
  ggsave(filename,
         plot = plot,
         path = path,
         width = width,
         height = height,
         dpi = dpi,
         units = "in")
}

#' Save data table as CSV
#' @param data Dataframe
#' @param filename File name
#' @param path Directory path
save_data_csv <- function(data, filename, path) {
  full_path <- file.path(path, filename)
  write_csv(data, full_path)
  message(paste("Data saved to:", full_path))
}

# Utility Functions ------------------------------------------------------------

#' Print model results summary
#' @param model lmer model
#' @param title Optional title for output
print_model_summary <- function(model, title = NULL) {
  if (!is.null(title)) {
    cat("\n", rep("=", 80), "\n", sep = "")
    cat(title, "\n")
    cat(rep("=", 80), "\n\n", sep = "")
  }

  cat("ANOVA Table (Type III):\n")
  print(anova(model, type = 3))

  cat("\n\nModel Summary:\n")
  print(summary(model))
}

#' Create significance letter labels from emmeans output
#' @param emmeans_obj emmeans object
#' @return Vector of compact letter display
get_significance_letters <- function(emmeans_obj) {
  cld_result <- cld(emmeans_obj, adjust = "tukey", Letters = letters)
  return(cld_result$.group)
}

# ==============================================================================
# END OF FUNCTIONS
# ==============================================================================
