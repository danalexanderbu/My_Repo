import pandas as pd
import math
import os
### This script converts the csv file into multiple Excel files, one for each project.###
# Function to convert bytes into a human-readable format
def convert_size(size_bytes):
    if size_bytes == 0:
        return "0B"
    size_name = ("B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB")
    i = int(math.floor(math.log(size_bytes, 1024)))
    p = math.pow(1024, i)
    s = round(size_bytes / p, 2)
    return "{} {}".format(s, size_name[i])

# Read the csv file
df = pd.read_csv('/home/sithlord/Desktop/Work/Prod/bb_audit/log.csv')

# Output directory for Excel files
output_dir = '/home/sithlord/Desktop/Work/Prod/bb_audit/output/'
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Maximum rows per Excel sheet
MAX_ROWS = 1048570  # Leaving a few rows for potential margin

# For each project in the dataframe
for project in df['Project Key'].unique():
    # Filter rows for the current project
    project_data = df[df['Project Key'] == project]
    
    # Create a new Excel writer object for this project
    with pd.ExcelWriter(os.path.join(output_dir, f'{project.replace(":", "_")}.xlsx')) as writer:
        for repo in project_data['Repository Slug'].unique():
            # Filter rows for the current repo
            repo_data = project_data[project_data['Repository Slug'] == repo]
            
            # Add a column for total file size per branch
            branch_totals = repo_data.groupby('Branch')['File Size'].sum().reset_index()
            branch_totals['File Name'] = 'Total size'
            branch_totals['File Type'] = 'Total'
            branch_totals['File Path'] = 'Total'
            branch_totals['Repository Slug'] = 'Total'
            branch_totals['File Size'] = branch_totals['File Size'].apply(convert_size)
            repo_data = pd.concat([repo_data, branch_totals])
            
            # Split the data and save in different sheets if it exceeds the max rows
            num_parts = -(-len(repo_data) // MAX_ROWS)  # Ceiling division
            for i in range(num_parts):
                subset_data = repo_data.iloc[i * MAX_ROWS : (i + 1) * MAX_ROWS]
                sheet_name = f"{repo[:28]}_part{i+1}" if num_parts > 1 else repo[:31]
                subset_data.to_excel(writer, sheet_name=sheet_name, index=False)
