This is a simple script I wrote that replicates the model selection (or modsel) function of ENMTools.

I found no place online that had what I was looking for, so I wrote it myself (shoutout to Claude AI).

The intent of this script is to take in a CSV file with 3 columns:
  - The first column is the path to occurrence data / species / points
  - The second column is the path to an ASCII file representing a raster as a raw output of MaxEnt
  - The third column is the path to the LAMBDAS file of the same output as the second column.
    - Together they should look like this:
 
  C:/ProjectGIS/Species/boomslang.trimmed.csv	C:\ProjectGIS\Models\bio12_bio4\Dispholidus_typus.asc	C:\ProjectGIS\Models\bio12_bio4\Dispholidus_typus.lambdas
  C:/ProjectGIS/Species/boomslang.trimmed.csv	C:\ProjectGIS\Models\bio12_bio4_X201905\Dispholidus_typus.asc	C:\ProjectGIS\Models\bio12_bio4_X201905\Dispholidus_typus.lambdas
  C:/ProjectGIS/Species/boomslang.trimmed.csv	C:\ProjectGIS\Models\bio12_ro1\Dispholidus_typus.asc	C:\ProjectGIS\Models\bio12_ro1\Dispholidus_typus.lambdas
  C:/ProjectGIS/Species/boomslang.trimmed.csv	C:\ProjectGIS\Models\bio12_ro1_bio4\Dispholidus_typus.asc	C:\ProjectGIS\Models\bio12_ro1_bio4\Dispholidus_typus.lambdas
  C:/ProjectGIS/Species/boomslang.trimmed.csv	C:\ProjectGIS\Models\bio12_ro1_bio4_X201905\Dispholidus_typus.asc	C:\ProjectGIS\Models\bio12_ro1_bio4_X201905\Dispholidus_typus.lambdas
  C:/ProjectGIS/Species/boomslang.trimmed.csv	C:\ProjectGIS\Models\bio12_ro1_X201905\Dispholidus_typus.asc	C:\ProjectGIS\Models\bio12_ro1_X201905\Dispholidus_typus.lambda

Also, one of the parameters to the script is the path to the output CSV file. Here, you will see the log-likelihood values, parameters, AIC, and AICc values of all the different MaxEnt Outputs you inputted.

Some results will look like this:

| row_number | datapoints_path | raster_path | lambdas_path | loglikelihood | valid_points | total_points | probsum | error_message | n_parameters | aic | aicc |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | C:/ProjectGIS/Species/warthog.trimmed.csv | C:\ProjectGIS\Models\bio12_bio4\warthog.asc | C:\ProjectGIS\Models\bio12_bio4\warthog.lambdas | -21407.99656 | 1826 | 1830 | 60023.81453 | | 97 | 43009.99312 | 43020.99543 |
| 2 | C:/ProjectGIS/Species/warthog.trimmed.csv | C:\ProjectGIS\Models\bio12_ro1\warthog.asc | C:\ProjectGIS\Models\bio12_ro1\warthog.lambdas | -21593.41924 | 1825 | 1830 | 66279.15518 | | 53 | 43292.83847 | 43296.07054 |
| 3 | C:/ProjectGIS/Species/warthog.trimmed.csv | C:\ProjectGIS\Models\bio12_ro1_bio4\warthog.asc | C:\ProjectGIS\Models\bio12_ro1_bio4\warthog.lambdas | -21337.05061 | 1825 | 1830 | 57787.52735 | | 98 | 42870.10123 | 42881.34341 |
| 4 | C:/ProjectGIS/Species/warthog.trimmed.csv | C:\ProjectGIS\Models\bio4_X201905\warthog.asc | C:\ProjectGIS\Models\bio4_X201905\warthog.lambdas | -21793.18445 | 1812 | 1830 | 82241.26201 | | 120 | 43826.36889 | 43843.54216 |
| 5 | C:/ProjectGIS/Species/warthog.trimmed.csv | C:\ProjectGIS\Models\ro1_bio4\warthog.asc | C:\ProjectGIS\Models\ro1_bio4\warthog.lambdas | -21897.48619 | 1825 | 1830 | 79339.75507 | | 108 | 44010.97237 | 44024.69265 |
| 6 | C:/ProjectGIS/Species/warthog.trimmed.csv | C:\ProjectGIS\Models\ro1_bio4_X201905\warthog.asc | C:\ProjectGIS\Models\ro1_bio4_X201905\warthog.lambdas | -21659.37148 | 1812 | 1830 | 75474.35743 | | 125 | 43568.74295 | 43587.42623 |
| 7 | C:/ProjectGIS/Species/warthog.trimmed.csv | C:\ProjectGIS\Models\ro1_X201905\warthog.asc | C:\ProjectGIS\Models\ro1_X201905\warthog.lambdas | -22493.56777 | 1814 | 1830 | 118005.5876 | | 86 | 45159.13555 | 45167.80028 |

Example usage is as follows:

results <- process_csv_loglikelihood_with_aicc("input_file.csv", "output_results.csv")

Also, it does not exactly line up with ENMTools all the time. The actual ENMTools software sometimes returns a different sample size due to false negatives (some points are valid but it still counts as invalid).
For the most part, it works excellently.
results <- process_csv_loglikelihood_with_aicc("input_file.csv", "output_results.csv")
