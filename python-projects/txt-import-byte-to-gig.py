import pandas as pd

def bytes_to_gb(size_in_bytes):
    return size_in_bytes / (1024*1024*1024)

with open('/home/danielb/Desktop/Work/Prod/jira_software_stats.txt', 'r') as file:
    file.readline()
    file.readline()
    
    # Read the data using a pipe delimiter
    df = pd.read_csv(file, sep='|', names=['project_name', 'project_key', 'issue_count'], skipinitialspace=True)
    
df.to_excel('/home/danielb/Desktop/Work/Prod/BAT-Stats/jira_software.xlsx', index=False, header=['project_name', 'project_key', 'issue_count'], engine='openpyxl', sheet_name='Jira Software')