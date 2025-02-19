#' Calculate model summary statistics. Applicable to training data only.
#'
#' @param modeled_data_obj  List with model results. Output from model_with_SLR, model_with_CP, model_with_HDD_CDD, and model_with_TOWT.
#'
#' @return a dataframe with five model statistics: "R_squared", "CVRMSE", "NDBE", "MBE", "#Parameters"
#'
#' @export
#'
calculate_summary_statistics <- function(modeled_data_obj = NULL) {

  # residuals' calculation based on day normalization
  if (modeled_data_obj$model_input_options$day_normalized == FALSE) {

    model_fit <- modeled_data_obj$training_data$model_fit
    eload <- modeled_data_obj$training_data$eload
    fit_residuals_numeric <- eload - model_fit

  } else if (modeled_data_obj$model_input_options$day_normalized == TRUE) {

    model_fit <- modeled_data_obj$training_data$model_fit/modeled_data_obj$training_data$days
    eload <- modeled_data_obj$training_data$eload_perday
    fit_residuals_numeric <- eload - model_fit

  }

  # Calculation of model parameter count

  if(modeled_data_obj$model_input_options$regression_type == "TOWT" | modeled_data_obj$model_input_options$regression_type == "TOW") {

    nparameter <- length(modeled_data_obj$model_occupied$coefficients)

    if(exists("model_unoccupied", where = modeled_data_obj)) {
      nparameter <- nparameter + length(modeled_data_obj$model_unoccupied$coefficients)
    }

  } else {
    nparameter <- length(modeled_data_obj$model$coefficients)
  }

  effective_parameters <- length(fit_residuals_numeric) %>%
    magrittr::subtract(nparameter)

  # R-sqaured (Absolute)

  SSR_over_SST <- fit_residuals_numeric %>%
    magrittr::raise_to_power(2) %>%
    mean(na.rm = T) %>%
    magrittr::divide_by(var(eload, na.rm = T))

  R_squared <- round(1 - SSR_over_SST,2)

  # Adjusted R-sqaured (Absolute)

  N <- length(fit_residuals_numeric)

  Adjusted_R_squared <- round(1 - (((1-R_squared)*(N-1))/(effective_parameters - 1)),2)

  # Root Mean Sqaured Error (Absolute)
  RMSE <- fit_residuals_numeric %>%
    magrittr::raise_to_power(2) %>%
    sum(na.rm = T) %>%
    magrittr::divide_by(effective_parameters) %>%
    magrittr::raise_to_power(0.5)


  # Coefficient of Variation of the Root Mean Square Error (Percentage)
  CVRMSE <- RMSE %>%
    magrittr::divide_by(mean(eload, na.rm = T)) %>%
    magrittr::multiply_by(100) %>%
    round(., 2)

  # Normalized Mean Bias Error (Percentage)
  NMBE <- fit_residuals_numeric %>%
    sum(na.rm = T) %>%
    magrittr::divide_by(effective_parameters*mean(eload, na.rm = T)) %>%
    magrittr::multiply_by(100) %>%
    format(round(., 2), nsmall = 4)

  # Coefficient of Variation of Mean Absolute error (Absolute)
  CVMAE <- fit_residuals_numeric %>%
    abs(.) %>%
    magrittr::divide_by(length(fit_residuals_numeric)) %>%
    sum(na.rm = T) %>%
    magrittr::divide_by(mean(eload, na.rm = T))

  # Net Determination Bias Error (Percentage)
  NDBE <- fit_residuals_numeric %>%
    sum(na.rm = T) %>%
    magrittr::divide_by(sum(eload, na.rm = T)) %>%
    magrittr::multiply_by(100) %>%
    format(round(., 2), nsmall = 4)

  goodness_of_fit <- as.data.frame(matrix(nr = 1, nc = 7))
  names(goodness_of_fit) <- c("R_squared", "Adjusted_R_squared", "CVRMSE %", "NDBE %", "NMBE %", "#Parameters", "deg_of_freedom")
  goodness_of_fit$R_squared <- R_squared
  goodness_of_fit$Adjusted_R_squared <- Adjusted_R_squared
  goodness_of_fit$`CVRMSE %` <- CVRMSE
  goodness_of_fit$`NDBE %` <- NDBE
  goodness_of_fit$`NMBE %` <- NMBE
  goodness_of_fit$"#Parameters" <- nparameter
  goodness_of_fit$"deg_of_freedom" <- effective_parameters

  return(goodness_of_fit)

}

