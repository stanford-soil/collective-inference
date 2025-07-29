import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import subprocess
import sys

def run_model(script_name):
    """Run a model script and return success status"""
    try:
        result = subprocess.run([sys.executable, script_name], 
                              capture_output=True, text=True, cwd='.')
        if result.returncode == 0:
            print(f"✓ {script_name} executed successfully")
            return True
        else:
            print(f"✗ Error running {script_name}: {result.stderr}")
            return False
    except Exception as e:
        print(f"✗ Exception running {script_name}: {e}")
        return False

# Run both models
print("Running representation version models...")
degroot_success = run_model('representation_version_degroot.py')
count_success = run_model('representation_version_count.py')

# Create visualization
fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 10))
fig.suptitle('Representation Version Models: Beliefs and Information Percentages', fontsize=16)

if degroot_success:
    try:
        degroot_data = pd.read_csv('representation_version_degroot.csv', index_col=0)
        
        # Plot degroot beliefs
        belief_cols = [col for col in degroot_data.columns if 'belief' in col]
        for col in belief_cols:
            ax1.plot(degroot_data.index, degroot_data[col], marker='o', label=col.replace('_belief', ''))
        ax1.set_title('DeGroot Model: Beliefs Over Trials')
        ax1.set_xlabel('Trial')
        ax1.set_ylabel('Belief (Probability)')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # Plot degroot info percentages
        info_cols = [col for col in degroot_data.columns if 'info_pct' in col]
        for col in info_cols:
            ax2.plot(degroot_data.index, degroot_data[col], marker='s', label=col.replace('_info_pct', ''))
        ax2.set_title('DeGroot Model: Information Percentage Over Trials')
        ax2.set_xlabel('Trial')
        ax2.set_ylabel('Information Percentage')
        ax2.legend()
        ax2.grid(True, alpha=0.3)
        
    except Exception as e:
        print(f"Error plotting degroot data: {e}")

if count_success:
    try:
        count_data = pd.read_csv('representation_version_count.csv', index_col=0)
        
        # Plot count beliefs  
        belief_cols = [col for col in count_data.columns if 'belief' in col]
        for col in belief_cols:
            ax3.plot(count_data.index, count_data[col], marker='o', label=col.replace('_belief', ''))
        ax3.set_title('Count Model: Beliefs Over Trials')
        ax3.set_xlabel('Trial')
        ax3.set_ylabel('Belief (Probability)')
        ax3.legend()
        ax3.grid(True, alpha=0.3)
        
        # Plot count info percentages
        info_cols = [col for col in count_data.columns if 'info_pct' in col]
        for col in info_cols:
            ax4.plot(count_data.index, count_data[col], marker='s', label=col.replace('_info_pct', ''))
        ax4.set_title('Count Model: Information Percentage Over Trials')
        ax4.set_xlabel('Trial')
        ax4.set_ylabel('Information Percentage') 
        ax4.legend()
        ax4.grid(True, alpha=0.3)
        
    except Exception as e:
        print(f"Error plotting count data: {e}")

plt.tight_layout()
plt.savefig('representation_models_comparison.png', dpi=300, bbox_inches='tight')
plt.show()

print("\n" + "="*50)
print("REPRESENTATION MODELS SUMMARY")
print("="*50)

if degroot_success and count_success:
    print("Both models executed successfully!")
    print("\nKey differences between models:")
    print("- DeGroot: Information percentage accumulates through weighted averaging")
    print("- Count: Information percentage based on total observations considered")
    print("\nFiles created:")
    print("- representation_version_degroot.py")
    print("- representation_version_count.py") 
    print("- representation_version_degroot.csv")
    print("- representation_version_count.csv")
    print("- representation_models_comparison.png")
else:
    print("Some models failed to execute - check error messages above")