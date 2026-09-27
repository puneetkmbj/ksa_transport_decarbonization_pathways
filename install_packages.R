# Install the R packages needed to reproduce the figures.
#   Rscript install_packages.R
cran <- c("dplyr", "tidyr", "ggplot2", "patchwork", "remotes")
missing <- cran[!vapply(cran, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
if (!requireNamespace("rgcam", quietly = TRUE)) remotes::install_github("JGCRI/rgcam")
message("All packages available.")
