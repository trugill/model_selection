This is a simple script I wrote that replicates the model selection (or modsel) function of ENMTools.

I found no place online that had what I was looking for, so I wrote it myself (shoutout to Claude AI).

The intent of this script is to take in a CSV file with 3 columns:
  - The first column is the path to occurrence data / species / points
  - The second column is the path to an ASCII file representing a raster as a raw output of MaxEnt
  - The third column is the path to the LAMBDAS file of the same output as the second column.
    - Together they should look like this:
 
|  |  |  |
| :--- | :--- | :--- |
| C:/ProjectGIS/Species/boomslang.trimmed.csv | C:\ProjectGIS\Models\bio12_bio4\Dispholidus_typus.asc | C:\ProjectGIS\Models\bio12_bio4\Dispholidus_typus.lambdas |
| C:/ProjectGIS/Species/boomslang.trimmed.csv | C:\ProjectGIS\Models\bio12_bio4_X201905\Dispholidus_typus.asc | C:\ProjectGIS\Models\bio12_bio4_X201905\Dispholidus_typus.lambdas |
| C:/ProjectGIS/Species/boomslang.trimmed.csv | C:\ProjectGIS\Models\bio12_ro1\Dispholidus_typus.asc | C:\ProjectGIS\Models\bio12_ro1\Dispholidus_typus.lambdas |
| C:/ProjectGIS/Species/boomslang.trimmed.csv | C:\ProjectGIS\Models\bio12_ro1_bio4\Dispholidus_typus.asc | C:\ProjectGIS\Models\bio12_ro1_bio4\Dispholidus_typus.lambdas |
| C:/ProjectGIS/Species/boomslang.trimmed.csv | C:\ProjectGIS\Models\bio12_ro1_bio4_X201905\Dispholidus_typus.asc | C:\ProjectGIS\Models\bio12_ro1_bio4_X201905\Dispholidus_typus.lambdas |
| C:/ProjectGIS/Species/boomslang.trimmed.csv | C:\ProjectGIS\Models\bio12_ro1_X201905\Dispholidus_typus.asc | C:\ProjectGIS\Models\bio12_ro1_X201905\Dispholidus_typus.lambda |

Also, one of the parameters to the script is the path to the output CSV file. Here, you will see the log-likelihood values, parameters, AIC, and AICc values of all the different MaxEnt Outputs you inputted.

Some results will look like this:

| points\_path | ascii\_file\_path | loglikelihood | parameter\_count | sample\_size | aic\_score | aicc\_score | bic\_score | probsum | valid\_points | total\_points | error\_message |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_bio17\\Phacochoerus\_africanus.asc | -24779.1 | 100 | 1955 | 49758.1 | 49769.0 | 50316.0 | 158323.0 | 1955 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_bio17\_im1\\Phacochoerus\_africanus.asc | -24000.1 | 61 | 1907 | 48122.1 | 48126.2 | 48460.9 | 143398.0 | 1907 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_bio17\_X201902\\Phacochoerus\_africanus.asc | -23891.6 | 105 | 1941 | 47993.2 | 48005.4 | 48578.2 | 109389.0 | 1941 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_bio17\_X201902\_im1\\Phacochoerus\_africanus.asc | -23166.4 | 89 | 1901 | 46510.8 | 46519.6 | 47004.7 | 96884.4 | 1901 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_bio17\_X201905\\Phacochoerus\_africanus.asc | -24517.0 | 107 | 1941 | 49247.9 | 49260.5 | 49844.0 | 150809.0 | 1941 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_bio17\_X201905\_im1\\Phacochoerus\_africanus.asc | -23796.5 | 76 | 1901 | 47745.0 | 47751.4 | 48166.8 | 132476.0 | 1901 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_bio17\_X201905\_X201902\\Phacochoerus\_africanus.asc | -23792.3 | 128 | 1941 | 47840.6 | 47858.8 | 48553.7 | 103151.0 | 1941 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_bio17\_X201905\_X201902\_im1\\Phacochoerus\_africanus.asc | -23061.0 | 118 | 1901 | 46357.9 | 46373.7 | 47012.9 | 90663.7 | 1901 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_bio17\_X201906\\Phacochoerus\_africanus.asc | -24443.9 | 82 | 1941 | 49051.7 | 49059.0 | 49508.5 | 144487.0 | 1941 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_bio17\_X201906\_im1\\Phacochoerus\_africanus.asc | -23734.2 | 65 | 1901 | 47598.4 | 47603.0 | 47959.1 | 128695.0 | 1901 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_bio17\_X201906\_X201902\\Phacochoerus\_africanus.asc | -23757.6 | 118 | 1941 | 47751.2 | 47766.6 | 48408.6 | 100963.0 | 1941 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_bio17\_X201906\_X201902\_im1\\Phacochoerus\_africanus.asc | -23015.7 | 112 | 1901 | 46255.3 | 46269.5 | 46876.9 | 88507.1 | 1901 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_im1\\Phacochoerus\_africanus.asc | -24368.1 | 41 | 1907 | 48818.2 | 48820.0 | 49045.9 | 172890.0 | 1907 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_X201902\\Phacochoerus\_africanus.asc | -24024.3 | 77 | 1941 | 48202.7 | 48209.1 | 48631.7 | 115509.0 | 1941 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_X201902\_im1\\Phacochoerus\_africanus.asc | -23289.5 | 90 | 1901 | 46759.0 | 46768.1 | 47258.5 | 101519.0 | 1901 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_X201905\\Phacochoerus\_africanus.asc | -24802.7 | 104 | 1941 | 49813.4 | 49825.3 | 50392.8 | 174269.0 | 1941 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_X201905\_im1\\Phacochoerus\_africanus.asc | -24168.6 | 80 | 1901 | 48497.1 | 48504.2 | 48941.1 | 161671.0 | 1901 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_X201905\_X201902\\Phacochoerus\_africanus.asc | -23892.5 | 104 | 1941 | 47992.9 | 48004.8 | 48572.3 | 107534.0 | 1941 | 1961 | nan |
| C:/ProjectGIS/Phacochoerus\_africanus/CSV/Phacochoerus\_africanus.trimmed.csv | C:\\ProjectGIS\\Phacochoerus\_africanus\\Models\\bio11\_X201905\_X201902\_im1\\Phacochoerus\_africanus.asc | -23170.1 | 101 | 1901 | 46542.2 | 46553.7 | 47102.8 | 95061.8 | 1901 | 1961 | nan |

Example usage is as follows:

results <- process_csv_loglikelihood_with_aicc("input_file.csv", "output_results.csv")

Also, it does not exactly line up with ENMTools all the time. The actual ENMTools software sometimes returns a different sample size due to false negatives (some points are valid but it still counts as invalid).
For the most part, it works excellently.
results <- process_csv_loglikelihood_with_aicc("input_file.csv", "output_results.csv")
