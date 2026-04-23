.validate_flag <- function(x, arg) {
    if (!is.logical(x) || length(x) != 1 || is.na(x)) {
        cli::cli_abort("{.arg {arg}} must be TRUE or FALSE.")
    }

    x
}

.validate_scalar_string <- function(x, arg) {
    if (!is.character(x) || length(x) != 1 || is.na(x) || !nzchar(x)) {
        cli::cli_abort("{.arg {arg}} must be a single non-empty string.")
    }

    x
}

.validate_positive_number <- function(x, arg, allow_null = FALSE) {
    if (is.null(x)) {
        if (isTRUE(allow_null)) {
            return(NULL)
        }

        cli::cli_abort("{.arg {arg}} must not be NULL.")
    }

    if (!is.numeric(x) || length(x) != 1 || is.na(x) || x <= 0) {
        cli::cli_abort("{.arg {arg}} must be a single number > 0.")
    }

    x
}

.validate_output_units <- function(units) {
    units <- .validate_scalar_string(units, "units")
    rlang::arg_match0(tolower(units), values = c("in", "cm", "mm", "px"))
}

.is_grob_like <- function(x) {
    inherits(x, c("grob", "gTree", "gtable"))
}
