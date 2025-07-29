import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Read data from all three models
slider_df = pd.read_csv('slider_degroot.csv', index_col=0)
count_df = pd.read_csv('count_version.csv', index_col=0)
dyadic_df = pd.read_csv('dyadic_with_influence.csv', index_col=0)

# Create subplots
fig, axes = plt.subplots(2, figsize=(15, 12))
fig.suptitle('Comparison of Social Influence Models', fontsize=16)

# Plot 1: Slider DeGroot Model
axes[0, 0].set_title('Slider DeGroot Model')
for col in slider_df.columns:
    axes[0, 0].plot(slider_df.index, slider_df[col], marker='o', label=col)
axes[0, 0].set_xlabel('Trial')
axes[0, 0].set_ylabel('Belief (Proportion)')
axes[0, 0].legend()
axes[0, 0].grid(True, alpha=0.3)

# Plot 2: Count Version Model
axes[0, 1].set_title('Count Version Model')
for col in count_df.columns:
    axes[0, 1].plot(count_df.index, count_df[col], marker='s', label=col)
axes[0, 1].set_xlabel('Trial')
axes[0, 1].set_ylabel('Belief (Proportion)')
axes[0, 1].legend()
axes[0, 1].grid(True, alpha=0.3)


plt.tight_layout()
plt.savefig('model_comparison.png', dpi=300, bbox_inches='tight')
plt.show()

# Print summary statistics
print("=== Model Comparison Summary ===")
print(f"Slider DeGroot - Final convergence range: {slider_df.iloc[-1].min():.3f} - {slider_df.iloc[-1].max():.3f}")
print(f"Count Version - Final convergence range: {count_df.iloc[-1].min():.3f} - {count_df.iloc[-1].max():.3f}")
print(f"Dyadic - Final range: {dyadic_df.iloc[-1].min():.3f} - {dyadic_df.iloc[-1].max():.3f}")
