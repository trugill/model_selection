# -----------------------------------------------------------------------------
# Reads a CSV and returns a list with:
#   $header       - the header line (character)
#   $has_species  - TRUE if first column looks like a species/name column
#   $lat_idx      - 1-based index of the latitude column in the CSV
#   $lon_idx      - 1-based index of the longitude column in the CSV
#   $points       - character vector of "lon,lat" strings (or "lat,lon" - we return raw fields)
#   $rows         - the raw data rows split into fields (list of char vectors)
# -----------------------------------------------------------------------------
read_points_csv <- function(infile, verbose = TRUE) {
  lines <- readLines(infile, warn = FALSE)
  if (length(lines) < 2) stop(sprintf("CSV has fewer than 2 lines: %s", infile))
  
  header <- trimws(lines[1])
  header_fields <- strsplit(header, ",", fixed = TRUE)[[1]]
  header_fields_clean <- trimws(tolower(header_fields))
  
  # Find lat and lon columns by name (anywhere in the CSV)
  lat_idx <- which(grepl("^lat", header_fields_clean))[1]
  lon_idx <- which(grepl("^lon", header_fields_clean))[1]
  
  # If not found by name, fall back to Maxent default (species, lon, lat)
  if (is.na(lat_idx) || is.na(lon_idx)) {
    if (length(header_fields) >= 3) {
      lon_idx <- 2L; lat_idx <- 3L
      if (verbose) message("  WARNING: lat/lon columns not found by name; ",
                           "assuming Maxent default (col2=lon, col3=lat)")
    } else if (length(header_fields) == 2) {
      # Two-column file with unrecognized names: assume lat,lon
      lat_idx <- 1L; lon_idx <- 2L
      if (verbose) message("  WARNING: lat/lon not detected; assuming (col1=lat, col2=lon)")
    } else {
      stop("Cannot determine lat/lon columns in CSV")
    }
  }
  
  has_species <- (length(header_fields) >= 3) &&
    !(1 %in% c(lat_idx, lon_idx))
  
  # Parse data rows
  rows <- vector("list", length(lines) - 1)
  keep <- logical(length(lines) - 1)
  for (i in seq_along(rows)) {
    ln <- trimws(lines[i + 1], which = "right")
    if (nchar(ln) == 0) { keep[i] <- FALSE; next }
    fields <- strsplit(ln, ",", fixed = TRUE)[[1]]
    if (length(fields) < max(lat_idx, lon_idx)) { keep[i] <- FALSE; next }
    rows[[i]] <- trimws(fields)
    keep[i] <- TRUE
  }
  rows <- rows[keep]
  
  if (verbose) {
    message(sprintf("  CSV: %d columns [%s]",
                    length(header_fields), paste(header_fields, collapse = ", ")))
    message(sprintf("  Detected: lat_idx=%d, lon_idx=%d, has_species=%s",
                    lat_idx, lon_idx, has_species))
    message(sprintf("  Loaded %d data rows", length(rows)))
  }
  
  list(
    header      = header,
    has_species = has_species,
    lat_idx     = lat_idx,
    lon_idx     = lon_idx,
    rows        = rows
  )
}


compute_AIC <- function(datafile, csv_info, lambdasfile, verbose = TRUE) {
  
  loglikelihood <- 0
  
  # ---- Count parameters ----
  lambda_lines <- readLines(lambdasfile, warn = FALSE)
  nparams <- 0
  for (ln in lambda_lines) {
    parts <- strsplit(ln, ",", fixed = TRUE)[[1]]
    if (length(parts) < 2) next
    weight <- sub("\\s+", "", parts[2])
    if (!identical(weight, "0.0")) nparams <- nparams + 1
  }
  nparams <- nparams - 4
  
  # ---- Parse ASCII raster ----
  asc_lines <- readLines(datafile, warn = FALSE)
  fileparams <- list()
  data_lines <- character(0)
  
  for (ln in asc_lines) {
    if (grepl("^\\s*[0-9-]", ln)) {
      data_lines <- c(data_lines, trimws(ln, which = "right"))
    } else {
      parts <- strsplit(trimws(ln), "\\s+")[[1]]
      if (length(parts) >= 2) {
        fileparams[[tolower(parts[1])]] <- parts[2]
      }
    }
  }
  
  xll      <- as.numeric(fileparams[["xllcorner"]])
  yll      <- as.numeric(fileparams[["yllcorner"]])
  cellsize <- as.numeric(fileparams[["cellsize"]])
  ncols    <- as.integer(fileparams[["ncols"]])
  nrows    <- as.integer(fileparams[["nrows"]])
  
  if (verbose) {
    message(sprintf("  Raster geometry: xll=%g, yll=%g, cellsize=%g, ncols=%s, nrows=%s",
                    xll, yll, cellsize,
                    ifelse(is.na(ncols), "?", ncols),
                    ifelse(is.na(nrows), "?", nrows)))
    message(sprintf("  Data rows found: %d", length(data_lines)))
  }
  
  # Row 0 = bottom of map
  env_data <- rev(data_lines)
  
  # Pre-split every raster row for efficiency (huge speedup vs. splitting per point)
  env_cells <- lapply(env_data, function(r) {
    v <- strsplit(r, "\\s+")[[1]]
    suppressWarnings(as.numeric(v[v != ""]))
  })
  
  # Compute probsum in one pass
  probsum <- sum(sapply(env_cells, function(v) {
    ok <- !is.na(v) & v != -9999
    sum(v[ok])
  }))
  if (verbose) message(sprintf("  probsum = %g", probsum))
  
  # ---- Compute log-likelihood ----
  npoints <- 0
  points_processed <- 0
  points_out_of_bounds <- 0
  points_no_data <- 0
  
  for (fields in csv_info$rows) {
    points_processed <- points_processed + 1
    
    thisx <- suppressWarnings(as.numeric(fields[csv_info$lon_idx]))
    thisy <- suppressWarnings(as.numeric(fields[csv_info$lat_idx]))
    
    if (is.na(thisx) || is.na(thisy)) {
      if (verbose && points_processed <= 5) {
        message(sprintf("  Point %d: non-numeric coords in [%s]",
                        points_processed, paste(fields, collapse = ",")))
      }
      next
    }
    
    if (verbose && points_processed <= 3) {
      message(sprintf("  Point %d: x(lon)=%g, y(lat)=%g",
                      points_processed, thisx, thisy))
    }
    
    row <- as.integer(floor((thisy - yll) / cellsize))
    col <- as.integer(floor((thisx - xll) / cellsize))
    
    if (verbose && points_processed <= 3) {
      message(sprintf("    -> row=%d, col=%d (env rows: %d)",
                      row, col, length(env_cells)))
    }
    
    if (row < 0 || row >= length(env_cells)) {
      points_out_of_bounds <- points_out_of_bounds + 1
      next
    }
    cells <- env_cells[[row + 1]]
    if (col < 0 || col >= length(cells)) {
      points_out_of_bounds <- points_out_of_bounds + 1
      next
    }
    
    layer_value <- cells[col + 1]
    
    if (!is.na(layer_value) && layer_value > 0) {
      loglikelihood <- loglikelihood + log(layer_value / probsum)
      npoints <- npoints + 1
    } else {
      points_no_data <- points_no_data + 1
    }
  }
  
  if (verbose) {
    message(sprintf("  === Summary: processed=%d, matched=%d, out-of-bounds=%d, no-data/zero=%d ===",
                    points_processed, npoints, points_out_of_bounds, points_no_data))
  }
  
  if (nparams >= npoints - 1) {
    AICscore  <- "x"; AICcscore <- "x"; BICscore  <- "x"
  } else {
    AICscore  <- 2 * nparams - 2 * loglikelihood
    AICcscore <- AICscore + (2 * nparams * (nparams + 1) / (npoints - nparams - 1))
    BICscore  <- nparams * log(npoints) - 2 * loglikelihood
  }
  
  list(
    loglikelihood = loglikelihood,
    nparams       = nparams,
    npoints       = npoints,
    AIC           = AICscore,
    AICc          = AICcscore,
    BIC           = BICscore
  )
}


modsel_extract_data <- function(ascfile, csv_info, lambdasfile, outcon,
                                csvfile_label, verbose = TRUE) {
  message(sprintf("\nExtracting data from %s using %s...", ascfile, csvfile_label))
  res <- compute_AIC(ascfile, csv_info, lambdasfile, verbose = verbose)
  outline <- paste(
    csvfile_label, ascfile,
    res$loglikelihood, res$nparams, res$npoints,
    res$AIC, res$AICc, res$BIC,
    sep = ","
  )
  writeLines(outline, con = outcon)
}


modsel_execute <- function(modselfile, verbose = TRUE) {
  if (!file.exists(modselfile)) stop(sprintf("Control file not found: %s", modselfile))
  outfile <- sub("\\.csv$", "_model_selection.csv", modselfile, ignore.case = TRUE)
  if (identical(outfile, modselfile)) outfile <- paste0(modselfile, "_model_selection.csv")
  outcon <- file(outfile, open = "w")
  on.exit(close(outcon), add = TRUE)
  writeLines(
    "Points,ASCII file,Log Likelihood,Parameters,Sample Size,AIC score,AICc score,BIC score",
    con = outcon
  )
  control_lines <- readLines(modselfile, warn = FALSE)
  
  # Cache parsed CSVs so we don't re-parse the same points file for every model
  csv_cache <- list()
  
  for (raw in control_lines) {
    line <- trimws(raw, which = "right")
    line <- gsub("\"", "", line, fixed = TRUE)
    if (nchar(line) == 0) next
    fields <- strsplit(line, ",", fixed = TRUE)[[1]]
    if (length(fields) < 3) { message(sprintf("Skipping malformed line: %s", raw)); next }
    points_csv   <- fields[1]
    ascii_file   <- fields[2]
    lambdas_file <- fields[3]
    
    ready_to_go <- TRUE
    if (!file.exists(points_csv))   { message(sprintf("Can't find %s!", points_csv));   ready_to_go <- FALSE }
    if (!file.exists(ascii_file))   { message(sprintf("Can't find %s!", ascii_file));   ready_to_go <- FALSE }
    if (!file.exists(lambdas_file)) { message(sprintf("Can't find %s!", lambdas_file)); ready_to_go <- FALSE }
    
    if (ready_to_go) {
      if (is.null(csv_cache[[points_csv]])) {
        csv_cache[[points_csv]] <- read_points_csv(points_csv, verbose = verbose)
      }
      modsel_extract_data(ascii_file, csv_cache[[points_csv]], lambdas_file,
                          outcon, csvfile_label = points_csv, verbose = verbose)
    }
  }
  message("\nFinished!")
  invisible(outfile)
}

# Read the README.md! 
# TO RUN:
# modsel_execute("Path/To/Your/CSV.csv")

modsel_execute("C:/NewProjectGISTemp/Phacochoerus_africanus/CSV/modelSelection.csv")

