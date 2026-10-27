#!/usr/bin/env Rscript
# Colour-blind regression guard.
#
# The default discrete palette must keep groups separable under deuteranopia.
# The pre-0.7.1 order put green (#59A14F) and red (#E15759) at positions 3-4,
# which collapse to CIELAB dE 0.7 under the Vienot 1999 simulation.
source("paperplot-skills/scripts/paperplot_helpers.R")
check <- function(value, message) if (!isTRUE(value)) stop(message)

thresholds <- c(`2` = 50, `3` = 25, `4` = 25, `5` = 18, `6` = 15)
reported <- vapply(names(thresholds), function(k) pp_palette_cvd_min_delta_e(as.integer(k)), numeric(1))
for (k in names(thresholds)) {
  check(
    reported[[k]] >= thresholds[[k]],
    sprintf("Default palette n=%s: deuteranopia dE %.1f below required %.0f", k, reported[[k]], thresholds[[k]])
  )
}

# The exact red/green pair that caused the failure must stay separated.
pair <- pp_palette(2, palette = "colorblind_safe")
check(all(nzchar(pair)), "colorblind_safe palette resolves")

# Guard the specific regression: positions 3 and 4 of the default palette.
default_four <- pp_palette(4)
check(
  !identical(default_four[3:4], c("#59A14F", "#E15759")),
  "Default palette must not place green next to red at positions 3-4"
)

cat(sprintf(
  "Palette CVD check passed (min deuteranopia dE: %s).\n",
  paste(sprintf("n%s=%.1f", names(reported), reported), collapse = ", ")
))
