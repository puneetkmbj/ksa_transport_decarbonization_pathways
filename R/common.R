# ------------------------------------------------------------------------------
# common.R — packages, constants, data access, theme and output helpers
# ------------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(rgcam)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(patchwork)
})
options(dplyr.summarise.inform = FALSE)

if (!exists("REPO_ROOT")) REPO_ROOT <- "."

# ---- Scenario database ---------------------------------------------------------
# Project file of the scenario runs used in the paper (run of 24 July 2025).
DATA_FILE <- file.path(REPO_ROOT, "data", "trn_study_24_July.proj")
if (!exists(".trn_project")) .trn_project <- rgcam::loadProject(DATA_FILE)

# GCAM scenario names -> labels used in the paper (order = legend order)
SCENARIO_LABELS <- c(
  No_Policy                   = "No Policy",
  Baseline                    = "Baseline",
  Ambition                    = "Ambition",
  Ambition_EPT                = "Ambition_EPT",
  Ambition_Scrapage           = "Ambition_Scrapage",
  Ambition_ECV                = "Ambition_ECV",
  Ambition_Price_deregulation = "Ambition_Price Deregulation",
  Ambition_Plus               = "Ambition+"
)
MAIN_SCENARIOS   <- c("No Policy", "Baseline", "Ambition", "Ambition+")
POLICY_VARIANTS  <- c("Ambition_EPT", "Ambition_Scrapage", "Ambition_ECV", "Ambition_Price Deregulation")

#' One query, restricted to the paper's scenarios and 2015-2060, with labels.
gq <- function(query) {
  rgcam::getQuery(.trn_project, query) %>%
    filter(scenario %in% names(SCENARIO_LABELS), year >= 2015, year <= 2060) %>%
    mutate(scenario = factor(SCENARIO_LABELS[scenario], levels = unname(SCENARIO_LABELS)))
}

# ---- Constants -----------------------------------------------------------------
C_TO_CO2     <- 3.6667            # MtC -> MtCO2
EJ_TO_MBOE   <- 170.60421187678   # 1 EJ = 170.6 million barrels of oil equivalent
POLICY_START <- 2025              # first year in which the policy scenarios diverge

# Land transport = road and rail; aviation, shipping and non-motorised modes excluded
LAND_SUBSECTORS <- c("2W and 3W", "Car", "Large Car and Truck", "Mini Car", "Bus",
                     "Passenger Rail", "HSR",
                     "Light truck", "Medium truck", "Heavy truck", "Freight Rail")

# ---- Theme and palettes ----------------------------------------------------------
theme_trn <- function(base_size = 11, legend_position = "bottom") {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "grey88", linewidth = 0.25),
      panel.border     = element_rect(colour = "grey30", fill = NA, linewidth = 0.4),
      strip.background = element_rect(fill = "grey90", colour = "grey30", linewidth = 0.4),
      strip.text       = element_text(size = base_size + 1, margin = margin(3, 3, 3, 3)),
      plot.title       = element_text(size = base_size + 2, hjust = 0),
      axis.title.y     = element_text(margin = margin(r = 8)),
      legend.title     = element_blank(),
      legend.position  = legend_position,
      plot.margin      = margin(8, 12, 8, 8)
    )
}

PAL_SCENARIO <- c(
  "No Policy" = "black", "Baseline" = "darkgrey", "Ambition" = "orange",
  "Ambition_EPT" = "#1f78b4", "Ambition_Scrapage" = "#33a02c",
  "Ambition_ECV" = "#6a3d9a", "Ambition_Price Deregulation" = "#e31a1c",
  "Ambition+" = "#006600"
)
PAL_MODE <- c(
  "Bus" = "#F8766D", "Freight Rail" = "#C49A00", "Heavy truck" = "#53B400",
  "LDVs" = "#00C094", "Light truck" = "#00B6EB", "Medium truck" = "#A58AFF",
  "Passenger Rail" = "#FB61D7"
)
PAL_TECH <- c("BEV" = "#FEE12B", "FCEV" = "#0188A7", "ICE Hybrids" = "#DAB4C7", "ICE" = "#787878")
PAL_WATERFALL <- c(
  "No Policy" = "black", "Fuel Efficiency and EPR" = "#FAD105",
  "Public Transport" = "#FA3605", "BEVs" = "#006600", "FCEVs" = "#05C9FA",
  "Residual Emissions" = "#A6AAAB"
)

#' Shaded band marking the historical/calibration period before policies diverge
history_band <- function() {
  annotate("rect", xmin = -Inf, xmax = POLICY_START, ymin = -Inf, ymax = Inf,
           fill = "lightgrey", alpha = 0.3)
}

# ---- Output --------------------------------------------------------------------
#' Save a figure (PNG, 300 dpi) and the data plotted in it (CSV, one per panel)
save_figure <- function(plot, name, data, width, height) {
  dir.create(file.path(REPO_ROOT, "figures"), showWarnings = FALSE)
  dir.create(file.path(REPO_ROOT, "source_data"), showWarnings = FALSE)
  ggsave(file.path(REPO_ROOT, "figures", paste0(name, ".png")), plot,
         width = width, height = height, dpi = 300, bg = "white")
  if (is.data.frame(data)) data <- list(data)
  sfx <- if (length(data) > 1) paste0("_", names(data)) else ""
  for (i in seq_along(data)) {
    out <- data[[i]] %>% ungroup() %>% mutate(across(where(is.numeric), ~ signif(.x, 6)))
    utils::write.csv(out, file.path(REPO_ROOT, "source_data", paste0(name, sfx[i], ".csv")),
                     row.names = FALSE)
  }
  message("  wrote ", name)
  invisible(plot)
}
