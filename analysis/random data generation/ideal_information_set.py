import pandas as pd
import numpy as np

# Define steps and calculations
steps = np.linspace(0, 100, num=10)
N1 = np.round(steps).astype(int)
remaining = 100 - N1
N2 = np.round(remaining / 3).astype(int)
N3 = np.round(remaining / 3).astype(int)
N4 = remaining - N2 - N3

# Create the DataFrame
df = pd.DataFrame({'N1': N1, 'N2': N2, 'N3': N3, 'N4': N4})

# Calculate the total sum row-wise (not used but leaving for consistency)
df['Total_Sum'] = df.sum(axis=1)

# Remove the top and bottom rows
df_cropped = df.iloc[1:-1]

# Define increments for Total_information
increments = np.linspace(5, 35, num=6)

# Initialize an empty DataFrame to store results
df_final = pd.DataFrame()

# Loop to copy and assign Total_information values
for i in increments:
    df_temp = df_cropped.copy()
    df_temp['Total_information'] = i  # Assign the increment value to all rows
    df_temp['true_probability'] = 0.7  # Assign true_probability to 0.7
    df_final = pd.concat([df_final, df_temp])

# Copy the entire data frame and change true_probability to 0.3
df_temp_2 = df_final.copy()
df_temp_2['true_probability'] = 0.3

# Combine the original and new data frames
df_final = pd.concat([df_final, df_temp_2], ignore_index=True)


df_final.to_csv('output_dataframe.csv', index=False)

