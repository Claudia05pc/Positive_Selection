import subprocess
import pandas as pd
import statsmodels.stats.multitest as ssm

# -------------------------------
# Step 0: Create pvalues.txt from all *pvalue.txt files
# -------------------------------
# Extract the 2nd line and specific columns, then clean up "- "
subprocess.run("for file in *pvalue.txt; do sed -n '2p' \"$file\" | awk '{print FILENAME, $1, $3}'; done > pvalues.txt", 
               shell=True, check=True)
subprocess.run("sed -i 's/- //' pvalues.txt", shell=True, check=True)

print("pvalues.txt created from all *pvalue.txt files.")

# -------------------------------
# Step 1: Load the original p-values
# -------------------------------
file_path = 'pvalues.txt'
columns = ['filename', 'orthoname', 'pvalue']

df = pd.read_csv(file_path, sep=' ', header=None, names=columns)
print("\nOriginal DataFrame:")
print(df)

# -------------------------------
# Step 2: Multiple testing correction
# -------------------------------
method = "fdr_bh"  # Options: "bonferroni", "sidak", "holm-sidak", "fdr_bh", etc.

pval = df["pvalue"]
rej, pval_adj, alphasidak, alphacBonf = ssm.multipletests(pval, method=method)

# Add adjusted p-values and rejection info
df["pval_adj"] = pval_adj
df["rejected"] = rej

# -------------------------------
# Step 3: Save results
# -------------------------------
output_file_path = 'padjusted_fdr_bh.csv'
df.to_csv(output_file_path, index=False)

print(f"\nAdjusted DataFrame saved to '{output_file_path}':")
print(df)
