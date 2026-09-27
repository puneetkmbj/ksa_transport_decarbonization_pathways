# Land transport decarbonization pathways for Saudi Arabia: figure reproduction

Code and data to reproduce the figures of

> Kamboj, P., Bhatt, Y., Xu, X., Alswaina, F., Shetty, P. K., Arora, A., Hejazi, M. (2026). Pathways to Decarbonizing Land Transport in Saudi Arabia: An integrated assessment of technologies and policy interventions. *Energy and Climate Change* 7, 100245. [doi:10.1016/j.egycc.2026.100245](https://doi.org/10.1016/j.egycc.2026.100245)

The scenarios were produced with GCAM-KSA, the Saudi Arabia–focused version of the Global Change Analysis Model. All scenario output used in the paper is archived in one project file, and one command regenerates every figure together with a CSV of the exact values plotted.

## Quick start

Requires R ≥ 4.1.

```sh
Rscript install_packages.R   # dplyr, tidyr, ggplot2, patchwork, rgcam (GitHub: JGCRI/rgcam)
Rscript make_figures.R       # about 10 s
```

Output: `figures/` (PNG, 300 dpi) and `source_data/` (CSV; multi-panel figures write one file per panel, `_a`, `_b`). `session_info.txt` records the R and package versions of the last run.

| File | Figure in the paper |
|---|---|
| `fig01_land_transport_final_energy` | Fig. 1 — land-transport final energy, four scenarios |
| `fig02_land_transport_co2` | Fig. 2 — (a) land-transport CO₂; (b) 2060 reduction by measure, No Policy to Ambition+ |
| `fig03_policy_interaction` | Fig. 3 — (a) Ambition and single-policy extensions; (b) 2060 decomposition and interaction effect |
| `fig04_service_demand_and_modal_shift` | Fig. 4 — (a) service demand by mode; (b) change relative to Baseline |
| `fig05_new_vehicle_sales` | Fig. 5 — new-vehicle sales by powertrain, Ambition and Ambition+ |

## Repository layout

```
data/
  trn_study_24_July.proj            scenario database (rgcam project file)
  external/trn_waterfall_chart.csv  2060 reduction by measure (Fig. 2b)
R/
  common.R                          packages, scenario labels, constants, theme, output helper
  prep.R                            data preparation, one function per indicator
make_figures.R
install_packages.R
```

## Scenarios

As defined in the paper:

| Label | Description |
|---|---|
| No Policy | Counterfactual: no fuel-efficiency standards, public transport underdeveloped, negligible zero-emission vehicles, no change to fuel pricing |
| Baseline | Current policies: CAFE-based fuel-efficiency improvements, a moderate exogenous shift to public transport, fuel prices applicable from January 2025 |
| Ambition | Baseline plus a 30% clean-vehicle sales target in Riyadh by 2030 (about 8% of national new-vehicle sales) and a public-transport share rising to 20% by 2060 |
| Ambition+ | Ambition plus removal of infrastructural and institutional barriers to clean vehicles (LDVs by 2035, HDVs by 2040–45), a 30% public-transport share by 2060, an ICE scrappage rule from 2030 (maximum vehicle age 15 years), and full fuel-price deregulation by 2030 |
| Ambition_ECV / _EPT / _Scrapage / _Price Deregulation | Ambition plus one of the four Ambition+ measures: enhanced clean vehicles, enhanced public transport, ICE scrappage, price deregulation (Fig. 3) |

Land transport covers road (two- and three-wheelers, cars, buses, light, medium and heavy trucks) and rail (passenger, high-speed and freight). Aviation and shipping are excluded.

## Data provenance

**Scenario database.** `data/trn_study_24_July.proj` is the run used for the published figures. A later run (17 September 2025) exists but does not reproduce the paper. Its 2060 values differ from the published ones by up to 1.9 MtCO₂ and 4.5 Mboe (e.g. No Policy final energy 688 against the published 684 Mboe; Ambition 121 against 120 MtCO₂).

**External input.** `data/external/trn_waterfall_chart.csv` attributes the 2060 reduction from No Policy to Ambition+ to individual measures (Fig. 2b). The attribution was computed outside the scenario database. Its endpoints are checked against the database each time the figures are built.

**Adjustments in the published figures.** Two presentation adjustments to the model output appear in the paper and are reproduced here. Both are applied in named steps in `R/prep.R`, and the source-data CSVs carry the unadjusted value in a `model_value` column.

1. *No Policy, 2015.* The No Policy run reports slightly higher 2015 land-transport CO₂ and final energy than the other runs (143.1 against 140.1 MtCO₂; 339.7 against 332.6 Mboe). The figures start all scenarios from the common 2015 value.
2. *Bus, 2030 (Fig. 4b).* The difference in bus service demand relative to Baseline in 2030 (−1.4 billion pkm under Ambition, −2.8 under Ambition+) is shown as zero.

Ambition, Ambition+ and the single-policy variants follow Baseline until 2025 and are plotted from 2025.

**Units.** Final energy is reported in million barrels of oil equivalent (1 EJ = 170.6 Mboe), CO₂ in Mt.

## Differences from the published layout

The text call-outs on the published Fig. 2a (policy milestones along each pathway) are not drawn. Colours and styling follow the published figures but are not pixel-identical.

## Licence

Code: MIT. The scenario data, the external input, and the generated figures and source data are © King Abdullah Petroleum Studies and Research Center (KAPSARC) and licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Reuse is permitted with citation of the paper above. Full terms in `LICENSE`.
