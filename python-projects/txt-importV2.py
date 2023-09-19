import os
import pandas as pd

file_location = '/home/danielb/Desktop/Work/Prod/jira_sd_stats.txt'  # Replace this with the path to your text file
output_directory = '/home/danielb/Desktop/Work/Prod/BAT-stats'
output_file = 'jira_sd.xlsx'

# Create the output directory if it doesn't exist
os.makedirs(output_directory, exist_ok=True)

# Read the data as a DataFrame
df = pd.read_csv(file_location, sep='|')

# Save the DataFrame to an Excel file
with pd.ExcelWriter(os.path.join(output_directory, output_file), engine='openpyxl') as writer:
    df.to_excel(writer, index=False, sheet_name='jira_software')
