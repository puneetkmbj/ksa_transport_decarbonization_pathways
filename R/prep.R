# ------------------------------------------------------------------------------
# prep.R — data preparation for each figure
# ------------------------------------------------------------------------------

# ---- Presentation adjustments applied in the published figures -------------------
# The published figures include two hand adjustments to the model output. They are
# kept here so the figures reproduce the paper, and every adjusted value is also
# written to source_data/ with its raw model value (column `model_value`).
#
# 1. No Policy, 2015. In the model the No Policy run reports slightly higher 2015
#    land-transport CO2 and final energy than the other scenarios (143.1 vs 140.1
#    MtCO2; 339.7 vs 332.6 Mboe). The published figures start all scenarios from the
#    common 2015 value of the other runs.
# 2. Bus, 2030 (Fig. 4b). The difference in bus service demand between Ambition /
#    Ambition+ and Baseline in 2030 (-1.4 / -2.8 billion pkm) is shown as zero.

align_no_policy_2015 <- function(df) {
  ref <- df$value[df$scenario == "Baseline" & df$year == 2015]
  df %>% mutate(model_value = value,
                value = ifelse(scenario == "No Policy" & year == 2015, ref, value))
}

# ---- Totals for land transport --------------------------------------------------

#' Land-transport CO2 emissions by scenario (MtCO2). Policy variants and the two
#' Ambition scenarios share the Baseline path until 2025 and are reported from 2025.
land_co2 <- function(scenarios = MAIN_SCENARIOS) {
  gq("CO2 emissions by subsector (excluding resource production)") %>%
    filter(subsector %in% LAND_SUBSECTORS, scenario %in% scenarios) %>%
    group_by(scenario, year) %>%
    summarise(value = sum(value) * C_TO_CO2, .groups = "drop") %>%
    filter(!(scenario %in% c("Ambition", "Ambition+", POLICY_VARIANTS) & year < POLICY_START)) %>%
    align_no_policy_2015() %>%
    mutate(Units = "MtCO2")
}

#' Land-transport final energy by scenario (million barrels of oil equivalent)
land_final_energy <- function() {
  gq("transport final energy by tech and fuel") %>%
    filter(mode %in% LAND_SUBSECTORS, scenario %in% MAIN_SCENARIOS) %>%
    group_by(scenario, year) %>%
    summarise(value = sum(value) * EJ_TO_MBOE, .groups = "drop") %>%
    filter(!(scenario %in% c("Ambition", "Ambition+") & year < POLICY_START)) %>%
    align_no_policy_2015() %>%
    mutate(Units = "Mboe")
}

# ---- Policy interaction (Fig. 3) --------------------------------------------------

#' 2060 decomposition: Ambition, individual policy reductions, interaction, Ambition+
policy_interaction_2060 <- function() {
  e <- land_co2(c("Ambition", POLICY_VARIANTS, "Ambition+")) %>% filter(year == 2060)
  v <- setNames(e$value, as.character(e$scenario))
  individual <- v["Ambition"] - v[POLICY_VARIANTS]
  combined   <- v["Ambition"] - v["Ambition+"]
  tibble(
    item  = c("Ambition", sub("Ambition_", "", POLICY_VARIANTS),
              "Sum of individual reductions", "Interaction", "Ambition+"),
    value = c(v["Ambition"], individual, sum(individual), sum(individual) - combined, v["Ambition+"]),
    Units = "MtCO2"
  )
}

# ---- Service demand (Fig. 4) --------------------------------------------------------

SERVICE_MODE <- c(
  "Car" = "LDVs", "Large Car and Truck" = "LDVs", "Mini Car" = "LDVs", "2W and 3W" = "LDVs",
  "Bus" = "Bus", "Passenger Rail" = "Passenger Rail", "HSR" = "Passenger Rail",
  "Light truck" = "Light truck", "Medium truck" = "Medium truck",
  "Heavy truck" = "Heavy truck", "Freight Rail" = "Freight Rail"
)
FREIGHT_MODES <- c("Light truck", "Medium truck", "Heavy truck", "Freight Rail")

#' Land-transport service demand by mode (billion pkm / billion tkm)
service_by_mode <- function() {
  gq("transport service output by tech") %>%
    filter(subsector %in% names(SERVICE_MODE),
           scenario %in% c("Baseline", "Ambition", "Ambition+")) %>%
    mutate(mode = SERVICE_MODE[subsector],
           segment = ifelse(mode %in% FREIGHT_MODES, "Freight", "Passenger")) %>%
    group_by(scenario, segment, mode, year) %>%
    summarise(value = sum(value) / 1000, .groups = "drop") %>%
    mutate(scenario = droplevels(scenario),
           Units = ifelse(segment == "Freight", "billion tkm", "billion pkm"))
}

#' Change in service demand relative to Baseline (billion pkm / tkm)
service_change_vs_baseline <- function() {
  s <- service_by_mode()
  base <- s %>% filter(scenario == "Baseline") %>% select(segment, mode, year, baseline = value)
  s %>%
    filter(scenario != "Baseline") %>%
    left_join(base, by = c("segment", "mode", "year")) %>%
    mutate(model_value = value - baseline,
           value = ifelse(mode == "Bus" & year == 2030, 0, model_value),   # adjustment 2
           comparison = factor(paste(scenario, "vs Baseline"),
                               levels = c("Ambition vs Baseline", "Ambition+ vs Baseline"))) %>%
    select(comparison, segment, mode, year, value, model_value, Units)
}

# ---- New vehicle sales (Fig. 5) ------------------------------------------------------

SALES_CLASS <- c(
  "Car" = "LDVs", "Large Car and Truck" = "LDVs", "Mini Car" = "LDVs", "2W and 3W" = "LDVs",
  "Bus" = "Bus", "Light truck" = "LDT", "Medium truck" = "MDT", "Heavy truck" = "HDT"
)
SALES_TECH <- c("Liquids" = "ICE", "Hybrid Liquids" = "ICE Hybrids", "BEV" = "BEV", "FCEV" = "FCEV")

#' Share (%) of new-vehicle sales (new-vintage service output) by powertrain
new_sales_share <- function(years = c(2030, 2040, 2050, 2060)) {
  gq("transport service output by tech (new)") %>%
    filter(subsector %in% names(SALES_CLASS), year %in% years,
           scenario %in% c("Ambition", "Ambition+")) %>%
    mutate(vehicle = SALES_CLASS[subsector], technology = SALES_TECH[technology]) %>%
    filter(!is.na(technology)) %>%
    group_by(scenario, vehicle, technology, year) %>%
    summarise(value = sum(value), .groups = "drop") %>%
    group_by(scenario, vehicle, year) %>%
    mutate(share = 100 * value / sum(value)) %>%
    ungroup() %>%
    mutate(scenario = droplevels(scenario),
           technology = factor(technology, levels = names(PAL_TECH)))
}

# ---- External input -----------------------------------------------------------------

WATERFALL_FILE <- file.path(REPO_ROOT, "data", "external", "trn_waterfall_chart.csv")

#' 2060 decomposition of the No Policy -> Ambition+ reduction by measure (Fig. 2b).
#' Attribution of the reduction to measures was done outside the scenario database;
#' its endpoints equal No Policy and Ambition+ 2060 emissions. NULL if absent.
emissions_waterfall <- function() {
  if (!file.exists(WATERFALL_FILE)) return(NULL)
  utils::read.csv(WATERFALL_FILE, check.names = FALSE, stringsAsFactors = FALSE)
}
