# Log-Likelihood Calculator for Species Distribution Models
# This script calculates log-likelihood for each row in a CSV file
# CSV format: column 1 = path to datapoints, column 2 = path to .asc raster, column 3 = path to .lambdas file

# Required libraries
library(raster)
library(sp)





# Function to read and validate lambdas file
read_lambdas <- function(lambdas_path) {
  if (!file.exists(lambdas_path)) {
    stop(paste("Lambdas file not found:", lambdas_path))
  }
  
  tryCatch({
    # Try reading with different methods to handle inconsistent formatting
    # First try: read as lines and parse manually
    lines <- readLines(lambdas_path)
    lines <- lines[lines != ""]  # Remove empty lines
    
    # Parse each line, handling variable number of columns
    parsed_data <- list()
    for (i in 1:length(lines)) {
      # Split by whitespace (tab or space)
      parts <- unlist(strsplit(lines[i], "\\s+"))
      if (length(parts) >= 2) {
        parsed_data[[i]] <- parts
      }
    }
    
    # Convert to data frame, handling variable column counts
    if (length(parsed_data) > 0) {
      max_cols <- max(sapply(parsed_data, length))
      # Pad shorter rows with NA
      for (i in 1:length(parsed_data)) {
        if (length(parsed_data[[i]]) < max_cols) {
          parsed_data[[i]] <- c(parsed_data[[i]], rep(NA, max_cols - length(parsed_data[[i]])))
        }
      }
      
      lambdas <- do.call(rbind, lapply(parsed_data, function(x) x))
      lambdas <- as.data.frame(lambdas, stringsAsFactors = FALSE)
      
      # Filter out parameters with value "0.0" in second column
      if (ncol(lambdas) >= 2) {
        # Convert second column to numeric for comparison
        second_col_numeric <- suppressWarnings(as.numeric(lambdas[, 2]))
        valid_indices <- !is.na(second_col_numeric) & second_col_numeric != 0.0
        valid_lambdas <- lambdas[valid_indices, ]
        return(valid_lambdas)
      } else {
        return(lambdas)
      }
    } else {
      stop("No valid data found in lambdas file")
    }
  }, error = function(e) {
    # Fallback: try read.table with fill=TRUE
    tryCatch({
      lambdas <- read.table(lambdas_path, header = FALSE, stringsAsFactors = FALSE, 
                            fill = TRUE, sep = "", quote = "")
      
      # Filter out parameters with value "0.0" in second column
      if (ncol(lambdas) >= 2) {
        second_col_numeric <- suppressWarnings(as.numeric(lambdas[, 2]))
        valid_indices <- !is.na(second_col_numeric) & second_col_numeric != 0.0
        valid_lambdas <- lambdas[valid_indices, ]
        return(valid_lambdas)
      } else {
        return(lambdas)
      }
    }, error = function(e2) {
      stop(paste("Could not read lambdas file:", e2$message))
    })
  })
}

# Function to read datapoints file
read_datapoints <- function(datapoints_path) {
  if (!file.exists(datapoints_path)) {
    stop(paste("Datapoints file not found:", datapoints_path))
  }
  
  # Read datapoints file (species, latitude, longitude)
  datapoints <- read.csv(datapoints_path, header = FALSE, stringsAsFactors = FALSE)
  
  # Ensure we have at least 3 columns
  if (ncol(datapoints) < 3) {
    stop(paste("Datapoints file must have at least 3 columns (species, lat, lon):", datapoints_path))
  }
  
  # Name the columns for clarity
  colnames(datapoints)[1:3] <- c("species", "latitude", "longitude")
  
  # Convert coordinates to numeric
  datapoints$latitude <- as.numeric(datapoints$latitude)
  datapoints$longitude <- as.numeric(datapoints$longitude)
  
  # Remove rows with NA coordinates
  datapoints <- datapoints[!is.na(datapoints$latitude) & !is.na(datapoints$longitude), ]
  
  return(datapoints)
}

# Function to calculate log-likelihood for a single row
calculate_loglikelihood <- function(datapoints_path, raster_path, lambdas_path) {
  tryCatch({
    # Read input files
    cat("Reading datapoints from:", datapoints_path, "\n")
    datapoints <- read_datapoints(datapoints_path)
    
    cat("Reading raster from:", raster_path, "\n")
    if (!file.exists(raster_path)) {
      stop(paste("Raster file not found:", raster_path))
    }
    prediction_raster <- raster(raster_path)
    
    cat("Reading lambdas from:", lambdas_path, "\n")
    lambdas <- read_lambdas(lambdas_path)
    
    cat("Processing", nrow(datapoints), "datapoints\n")
    
    # Step 1: Calculate normalization factor (probsum)
    cat("Calculating normalization factor...\n")
    raster_values <- getValues(prediction_raster)
    
    # Remove NA values and values that might represent "No Data" (like -9999)
    valid_values <- raster_values[!is.na(raster_values) & raster_values != -9999]
    probsum <- sum(valid_values, na.rm = TRUE)
    
    cat("Normalization factor (probsum):", probsum, "\n")
    
    if (probsum <= 0) {
      warning("Probsum is zero or negative, cannot calculate log-likelihood")
      return(NA)
    }
    
    # Step 2: Initialize log-likelihood
    loglikelihood <- 0
    valid_points <- 0
    
    # Step 3: Process each occurrence point
    cat("Processing occurrence points...\n")
    
    xx = 0
    
    for (i in 1:nrow(datapoints)) {
      lat <- datapoints$latitude[i]
      lon <- datapoints$longitude[i]
      
      # Extract prediction value at this point
      point_coords <- data.frame(x = lon, y = lat)
      coordinates(point_coords) <- ~x + y
      
      # Set the same CRS as the raster
      proj4string(point_coords) <- proj4string(prediction_raster)
      
      # Extract value from raster
      layer_value <- extract(prediction_raster, point_coords)
      
      # Check if value is valid (greater than 0)
      if (!is.na(layer_value) && layer_value > 0) {
        # Calculate normalized probability
        probability <- layer_value / probsum
        
        # Add log of probability to total
        loglikelihood <- loglikelihood + log(probability)
        valid_points <- valid_points + 1
      }
      
      xx = xx + 1
      if(xx %% 100 == 0){
        cat(xx, " of ", nrow(datapoints), " points processed...\n")
      }
      
    }
    
    cat("Valid points processed:", valid_points, "out of", nrow(datapoints), "\n")
    cat("Log-likelihood:", loglikelihood, "\n\n")
    
    return(list(
      loglikelihood = loglikelihood,
      valid_points = valid_points,
      total_points = nrow(datapoints),
      probsum = probsum
    ))
    
  }, error = function(e) {
    cat("Error processing row:", e$message, "\n")
    cat("Continuing to next row...\n\n")
    return(list(
      loglikelihood = NA,
      valid_points = NA,
      total_points = NA,
      probsum = NA,
      error = e$message
    ))
  })
}

# Main function to process CSV file
process_csv_loglikelihood <- function(csv_path, output_path = NULL) {
  if (!file.exists(csv_path)) {
    stop("CSV file not found:", csv_path)
  }
  
  # Read the CSV file
  input_data <- read.csv(csv_path, header = FALSE, stringsAsFactors = FALSE)
  
  # Check that we have at least 3 columns
  if (ncol(input_data) < 3) {
    stop("CSV file must have at least 3 columns: datapoints_path, raster_path, lambdas_path")
  }
  
  # Name the columns
  colnames(input_data)[1:3] <- c("datapoints_path", "raster_path", "lambdas_path")
  
  cat("Processing", nrow(input_data), "rows from CSV file\n")
  cat(paste(rep("=", 50), collapse = ""), "\n")
  
  # Initialize results data frame
  results <- data.frame(
    row_number = 1:nrow(input_data),
    datapoints_path = input_data$datapoints_path,
    raster_path = input_data$raster_path,
    lambdas_path = input_data$lambdas_path,
    loglikelihood = numeric(nrow(input_data)),
    valid_points = integer(nrow(input_data)),
    total_points = integer(nrow(input_data)),
    probsum = numeric(nrow(input_data)),
    error_message = character(nrow(input_data)),
    stringsAsFactors = FALSE
  )
  
  # Process each row
  for (i in 1:nrow(input_data)) {
    cat("Processing row", i, "of", nrow(input_data), "\n")
    
    result <- calculate_loglikelihood(
      input_data$datapoints_path[i],
      input_data$raster_path[i],
      input_data$lambdas_path[i]
    )
    
    # Store results
    results$loglikelihood[i] <- result$loglikelihood
    results$valid_points[i] <- ifelse(is.null(result$valid_points), NA, result$valid_points)
    results$total_points[i] <- ifelse(is.null(result$total_points), NA, result$total_points)
    results$probsum[i] <- ifelse(is.null(result$probsum), NA, result$probsum)
    results$error_message[i] <- ifelse(is.null(result$error), "", result$error)
  }
  
  # Save results if output path is provided
  if (!is.null(output_path)) {
    write.csv(results, output_path, row.names = FALSE)
    cat("Results saved to:", output_path, "\n")
  }
  
  # Print summary
  cat("\n", paste(rep("=", 20), collapse = ""), " SUMMARY ", paste(rep("=", 20), collapse = ""), "\n")
  cat("Total rows processed:", nrow(results), "\n")
  cat("Successful calculations:", sum(!is.na(results$loglikelihood)), "\n")
  cat("Failed calculations:", sum(is.na(results$loglikelihood)), "\n")
  
  if (sum(!is.na(results$loglikelihood)) > 0) {
    valid_results <- results[!is.na(results$loglikelihood), ]
    cat("Mean log-likelihood:", mean(valid_results$loglikelihood), "\n")
    cat("Range of log-likelihood:", range(valid_results$loglikelihood), "\n")
  }
  
  return(results)
}

# Function to read Maxent lambdas file and filter for active parameters
read_lambdas <- function(lambdas_path) {
  # 1. Basic file existence check
  if (!file.exists(lambdas_path)) {
    stop(paste("Lambdas file not found:", lambdas_path))
  }
  
  # 2. Read the raw data from the CSV file
  #    - header = FALSE: Maxent lambda files do not have a header row.
  #    - stringsAsFactors = FALSE: Prevents character strings from being converted to factors,
  #                                which is generally good practice for this type of data.
  #    - comment.char = "": Important! Maxent lambda files can have lines starting with '#'
  #                         or other characters if commented out. Set to "" to ensure
  #                         all lines are read unless they are truly empty.
  #    - fill = TRUE: Helps if some lines might have fewer columns (though less common for lambdas).
  #    - quote = "": Prevents R from interpreting single quotes (') or backticks (`) as text delimiters,
  #                  which can be present in feature names like 'bio4 or `1912.
  raw_data <- read.csv(lambdas_path, header = FALSE, stringsAsFactors = FALSE, comment.char = "", quote = "", strip.white = TRUE)
  
  # 3. Handle potential parsing issues: Ensure the second column (coefficient) is numeric.
  #    If there are non-numeric values, they will become NA.
  #    Maxent lambda files usually have the coefficient in the second column (V2).
  raw_data$V2_numeric <- as.numeric(raw_data$V2)
  
  # 4. Filter out metadata lines and rows where coefficient is NA (due to parsing errors)
  #    Metadata lines are usually at the end and have specific names in the first column.
  #    They do not represent features/parameters.
  metadata_keywords <- c("linearPredictorNormalizer", "densityNormalizer", "numBackgroundPoints", "entropy")
  
  # Create a logical vector indicating if a row is a metadata row
  is_metadata <- raw_data$V1 %in% metadata_keywords
  
  # Filter out metadata rows AND rows where V2_numeric is NA (i.e., non-numeric coefficients)
  # This also implicitly handles any fully empty lines or malformed lines that lead to NA
  filtered_data <- raw_data[!is_metadata & !is.na(raw_data$V2_numeric), ]
  
  # 5. Filter out features with a 0.0 coefficient
  #    These are features that Maxent considered but did not use in the final model.
  #    Only non-zero coefficients are typically counted as "parameters" for model complexity.
  active_parameters <- filtered_data[filtered_data$V2_numeric != 0.0, ]
  
  # Return only the relevant columns if desired, or the whole filtered data frame
  # For counting, nrow() of this data frame is what you need.
  return(active_parameters)
}

# Function to calculate AICc from log-likelihood
# AICc = -2 * log-likelihood + 2 * k + (2 * k * (k + 1)) / (n - k - 1)
# where k = number of parameters, n = sample size
calculate_aicc <- function(loglikelihood, n_parameters, sample_size) {
  if (is.na(loglikelihood) || is.na(n_parameters) || is.na(sample_size)) {
    return(NA)
  }
  
  if (sample_size <= n_parameters + 1) {
    warning("Sample size too small for AICc calculation (n <= k + 1)")
    return(NA)
  }
  
  aic <- -2 * loglikelihood + 2 * n_parameters
  aicc_correction <- (2 * n_parameters * (n_parameters + 1)) / (sample_size - n_parameters - 1)
  aicc <- aic + aicc_correction
  
  return(aicc)
}

# Function to add AICc calculations to existing results
calculate_aicc_from_results <- function(results) {
  cat("Calculating AICc values for", nrow(results), "models...\n")
  
  # Add new columns
  results$n_parameters <- numeric(nrow(results))
  results$aic <- numeric(nrow(results))
  results$aicc <- numeric(nrow(results))
  
  for (i in 1:nrow(results)) {
    if (!is.na(results$loglikelihood[i])) {
      # Count parameters from lambdas file
      n_params <- count_parameters(results$lambdas_path[i])
      results$n_parameters[i] <- ifelse(is.na(n_params), NA, n_params)
      
      # Calculate AIC
      if (!is.na(n_params)) {
        results$aic[i] <- -2 * results$loglikelihood[i] + 2 * n_params
        
        # Calculate AICc using valid_points as sample size
        results$aicc[i] <- calculate_aicc(
          results$loglikelihood[i], 
          n_params, 
          results$valid_points[i]
        )
      } else {
        results$aic[i] <- NA
        results$aicc[i] <- NA
      }
    } else {
      results$n_parameters[i] <- NA
      results$aic[i] <- NA
      results$aicc[i] <- NA
    }
  }
  
  return(results)
}

# Enhanced main function that includes AICc calculations
process_csv_loglikelihood_with_aicc <- function(csv_path, output_path = NULL) {
  # First calculate log-likelihoods
  results <- process_csv_loglikelihood(csv_path, output_path = NULL)
  
  # Then add AICc calculations
  results_with_aicc <- calculate_aicc_from_results(results)
  
  # Save enhanced results if output path is provided
  if (!is.null(output_path)) {
    write.csv(results_with_aicc, output_path, row.names = FALSE)
    cat("Results with AICc saved to:", output_path, "\n")
  }
  
  # Print enhanced summary
  cat("\n", paste(rep("=", 15), collapse = ""), " ENHANCED SUMMARY ", paste(rep("=", 15), collapse = ""), "\n")
  cat("Total rows processed:", nrow(results_with_aicc), "\n")
  cat("Successful calculations:", sum(!is.na(results_with_aicc$loglikelihood)), "\n")
  cat("Failed calculations:", sum(is.na(results_with_aicc$loglikelihood)), "\n")
  
  if (sum(!is.na(results_with_aicc$loglikelihood)) > 0) {
    valid_results <- results_with_aicc[!is.na(results_with_aicc$loglikelihood), ]
    cat("Mean log-likelihood:", round(mean(valid_results$loglikelihood), 4), "\n")
    cat("Range of log-likelihood:", round(range(valid_results$loglikelihood), 4), "\n")
    
    if (sum(!is.na(valid_results$n_parameters)) > 0) {
      valid_params <- valid_results[!is.na(valid_results$n_parameters), ]
      cat("Mean number of parameters:", round(mean(valid_params$n_parameters), 2), "\n")
      cat("Range of parameters:", range(valid_params$n_parameters), "\n")
      
      if (sum(!is.na(valid_params$aicc)) > 0) {
        valid_aicc <- valid_params[!is.na(valid_params$aicc), ]
        cat("Mean AICc:", round(mean(valid_aicc$aicc), 4), "\n")
        cat("Range of AICc:", round(range(valid_aicc$aicc), 4), "\n")
        
        # Find best model (lowest AICc)
        best_model_idx <- which.min(valid_aicc$aicc)
        cat("\nBest model (lowest AICc):\n")
        cat("Row:", valid_aicc$row_number[best_model_idx], "\n")
        cat("AICc:", round(valid_aicc$aicc[best_model_idx], 4), "\n")
        cat("Parameters:", valid_aicc$n_parameters[best_model_idx], "\n")
        cat("Log-likelihood:", round(valid_aicc$loglikelihood[best_model_idx], 4), "\n")
      }
    }
  }
  
  return(results_with_aicc)
}


# Example usage:
# results <- process_csv_loglikelihood_with_aicc("input_file.csv", "output_results.csv")

# For processing a single row (testing):
# single_result <- calculate_loglikelihood(
#   "path/to/datapoints.csv",
#   "path/to/prediction.asc", 
#   "path/to/lambdas.txt"
# )