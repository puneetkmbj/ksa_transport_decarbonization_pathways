# ==============================================================================
# Figures for:
#   Kamboj, P., Bhatt, Y., Xu, X., Alswaina, F., Shetty, P. K., Arora, A., Hejazi, M.
#   (2026). Pathways to Decarbonizing Land Transport in Saudi Arabia: An integrated
#   assessment of technologies and policy interventions.
#   Energy and Climate Change 7, 100245.
#
# Run from the repository root:  Rscript make_figures.R
# Output: figures/*.png and source_data/*.csv
# ==============================================================================

REPO_ROOT <- local({
  d <- normalizePath(getwd())
  while (!file.exists(file.path(d, "R", "common.R"))) {
    if (dirname(d) == d) stop("Run this script from inside the repository.")
    d <- dirname(d)
  }
  d
})
source(file.path(REPO_ROOT, "R", "common.R"))
source(file.path(REPO_ROOT, "R", "prep.R"))
unlink(file.path(REPO_ROOT, c("figures", "source_data")), recursive = TRUE)

end_labels <- function(df, digits = 0) {
  geom_text(data = filter(df, year == 2060),
            aes(x = year, y = value, label = round(value, digits), colour = scenario),
            hjust = -0.2, size = 3.3, show.legend = FALSE)
}
years_axis <- scale_x_continuous(limits = c(2015, 2063), breaks = seq(2015, 2060, 5),
                                 expand = expansion(mult = 0.01))

# ---- Fig. 1  Land-transport final energy ------------------------------------------
fe <- land_final_energy()
p1 <- ggplot(fe, aes(year, value, colour = scenario)) +
  history_band() +
  geom_line(linewidth = 0.8) +
  end_labels(fe) +
  scale_colour_manual(values = PAL_SCENARIO) +
  years_axis +
  scale_y_continuous(limits = c(0, 700), breaks = seq(0, 700, 100)) +
  labs(x = NULL, y = "MBOE") +
  theme_trn() + theme(axis.text.x = element_text(angle = 45, hjust = 1))
save_figure(p1, "fig01_land_transport_final_energy", fe, width = 9, height = 6.5)

# ---- Fig. 2  Land-transport CO2 (a) and 2060 reduction by measure (b) ---------------
co2 <- land_co2()
p2a <- ggplot(co2, aes(year, value, colour = scenario)) +
  history_band() +
  geom_line(linewidth = 0.8) +
  end_labels(co2) +
  scale_colour_manual(values = PAL_SCENARIO) +
  years_axis +
  scale_y_continuous(limits = c(0, 300), breaks = seq(0, 300, 50)) +
  labs(x = NULL, y = expression(MtCO[2]), title = "(a)") +
  theme_trn()

wf <- emissions_waterfall()
if (is.null(wf)) {
  message("  Fig. 2b skipped: data/external/trn_waterfall_chart.csv not found")
  save_figure(p2a, "fig02_land_transport_co2", co2, width = 9, height = 6.5)
} else {
  # Bars for the start and end totals rise from zero; measures hang between levels.
  # The endpoints must agree with the scenario database
  e2060 <- setNames(co2$value[co2$year == 2060], as.character(co2$scenario[co2$year == 2060]))
  stopifnot(abs(wf$value[wf$variable == "No Policy"] - e2060["No Policy"]) < 0.01,
            abs(wf$value[wf$variable == "Residual Emissions"] - e2060["Ambition+"]) < 0.01)
  wf <- wf %>% mutate(id = rank(id), size = abs(start - end),
                      label = ifelse(start == 0 | end == 0, sprintf("%s\n%.0f", sub(" and ", "\nand ", variable), size),
                                     sprintf("%s\n-%.0f", sub(" and ", "\nand ", variable), size)))
  p2b <- ggplot(wf) +
    geom_rect(aes(xmin = id - 0.45, xmax = id + 0.45, ymin = end, ymax = start, fill = variable)) +
    geom_text(aes(x = id, y = pmin(start, end) - 12, label = label), size = 2.6, lineheight = 0.9) +
    scale_fill_manual(values = PAL_WATERFALL, guide = "none") +
    scale_y_continuous(limits = c(-25, 310), breaks = seq(0, 300, 50)) +
    labs(x = "Emissions reduction in 2060", y = NULL, title = "(b)") +
    theme_trn() +
    theme(axis.text.x = element_blank(), panel.grid.major.x = element_blank())
  save_figure(p2a + p2b, "fig02_land_transport_co2", list(a = co2, b = wf), width = 14, height = 6.5)
}

# ---- Fig. 3  Policy interaction: trajectories (a) and 2060 decomposition (b) --------
pol <- land_co2(c("Ambition", POLICY_VARIANTS, "Ambition+"))
p3a <- ggplot() +
  history_band() +
  geom_line(data = filter(pol, scenario %in% POLICY_VARIANTS),
            aes(year, value, colour = scenario), linewidth = 0.6, linetype = "dashed") +
  geom_line(data = filter(pol, !scenario %in% POLICY_VARIANTS),
            aes(year, value, colour = scenario), linewidth = 0.8) +
  geom_line(data = land_co2("Baseline") %>% filter(year <= POLICY_START),
            aes(year, value), colour = "darkgreen", linewidth = 0.8) +
  end_labels(pol) +
  scale_colour_manual(values = PAL_SCENARIO) +
  years_axis +
  scale_y_continuous(limits = c(0, 200), breaks = seq(0, 200, 50)) +
  labs(x = NULL, y = expression(MtCO[2]), title = "(a)") +
  theme_trn(legend_position = c(0.2, 0.3)) +
  theme(legend.background = element_rect(fill = "white", colour = NA))

dec <- policy_interaction_2060()
amb <- dec$value[dec$item == "Ambition"]; apl <- dec$value[dec$item == "Ambition+"]
indiv <- dec %>% filter(item %in% sub("Ambition_", "", POLICY_VARIANTS)) %>%
  mutate(item = factor(item, levels = c("EPT", "Scrapage", "ECV", "Price Deregulation")),
         ymax = amb - cumsum(lag(value, default = 0)), ymin = ymax - value)
total_ind <- dec$value[dec$item == "Sum of individual reductions"]
inter     <- dec$value[dec$item == "Interaction"]
pal_pol <- c("EPT" = "#F4A582", "Scrapage" = "#A6DBA0", "ECV" = "#92C5DE", "Price Deregulation" = "#E7B8E3")
p3b <- ggplot() +
  geom_col(aes(x = 1, y = amb), fill = "orange", width = 0.6) +
  geom_rect(data = indiv, aes(xmin = 1.7, xmax = 2.3, ymin = ymin, ymax = ymax, fill = item),
            colour = "grey40", linewidth = 0.2) +
  geom_rect(aes(xmin = 2.7, xmax = 3.3, ymin = amb - total_ind, ymax = amb - total_ind + inter),
            fill = "grey85", colour = "grey40", linewidth = 0.2) +
  geom_col(aes(x = 4, y = apl), fill = "#006600", width = 0.6) +
  annotate("text", x = c(1, 4), y = c(amb, apl) + 7, label = round(c(amb, apl)), fontface = "bold", size = 3.3) +
  annotate("text", x = 2, y = amb - total_ind - 7, label = sprintf("- %.0f", total_ind), fontface = "bold", size = 3.3) +
  annotate("text", x = 3, y = amb - total_ind + inter + 7, label = sprintf("+ %.0f", inter), fontface = "bold", size = 3.3) +
  scale_fill_manual(values = pal_pol) +
  scale_x_continuous(breaks = 1:4, labels = c("Ambition", "Perceived reduction\nindividual policy",
                                              "Combined policies\ninteraction", "Ambition+")) +
  scale_y_continuous(limits = c(0, 200), breaks = seq(0, 200, 50), expand = c(0, 0)) +
  labs(x = NULL, y = expression(MtCO[2]), title = "(b)") +
  theme_trn(legend_position = "right") + theme(panel.grid.major.x = element_blank())
save_figure(p3a + p3b + plot_layout(widths = c(1.1, 1)), "fig03_policy_interaction",
            list(a = pol, b = dec), width = 14, height = 6)

# ---- Fig. 4  Service demand by mode (a) and change vs Baseline (b) ------------------
svc <- service_by_mode()
chg <- service_change_vs_baseline()
bars <- function(d, y) {
  ggplot(d, aes(factor(year), .data[[y]], fill = mode)) +
    geom_col(colour = "black", linewidth = 0.2) +
    scale_fill_manual(values = PAL_MODE) +
    labs(x = NULL, y = "billion tkm/pkm") +
    theme_trn() +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))
}
p4a <- bars(svc, "value") + facet_grid(segment ~ scenario) +
  labs(title = "(a). Transport Service Demand by Mode") + guides(fill = guide_legend(nrow = 1))
p4b <- bars(chg, "value") + facet_grid(segment ~ comparison) +
  geom_hline(yintercept = 0, colour = "red", linewidth = 0.5) +
  labs(title = "(b). Growth in Public Transport") + theme(legend.position = "none")
save_figure(p4a / p4b, "fig04_service_demand_and_modal_shift", list(a = svc, b = chg),
            width = 12, height = 13)

# ---- Fig. 5  New vehicle sales by powertrain ----------------------------------------
sales <- new_sales_share()
p5 <- ggplot(sales, aes(factor(year), share, fill = technology)) +
  geom_col(width = 0.6, colour = "black", linewidth = 0.2) +
  facet_grid(vehicle ~ scenario) +
  scale_fill_manual(values = PAL_TECH) +
  scale_y_continuous(breaks = seq(0, 100, 25), expand = c(0, 0)) +
  labs(x = NULL, y = "Share of New Vehicle Sales (%)") +
  theme_trn(base_size = 9, legend_position = "right")
save_figure(p5, "fig05_new_vehicle_sales", sales, width = 8, height = 7)

writeLines(capture.output(sessionInfo()), file.path(REPO_ROOT, "session_info.txt"))
message("Done.")
