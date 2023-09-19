import os
import re
import csv
from tqdm import tqdm

# Load usernames from a CSV file. 
# Usernames from the first column (Username) and the display names from the third column (DisplayName) 
# are loaded into separate sets. The first four columns (up to Email) are added to a data set for broader matching.
def load_usernames_from_csv(csv_path):
    data_set = set()
    display_names_set = set()
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.reader(f)
        next(reader)  # Skip the header row.
        for row in reader:
            data_set.update(row[:4])  # Load the first four columns into the data set
            display_names_set.add(row[2])  # Add display names (third column) to its respective set
    return data_set, display_names_set

# Define paths and constants
csv_path = "/home/sithlord/Downloads/DoD SAFE-JXbo6AfuDzd3H6T5/users.csv"
root_directory = "/home/sithlord/Downloads/Log-group"
name_replacement = "REDACTED"

# This regex pattern is used to identify file types (csv, log, xml) that we want to process.
filename_pattern = re.compile(r"\.(csv|log|xml)(\.[1-9])?(?:\d{4}-\d{2}-\d{2})?$")

# Load the usernames into a set for faster lookup.
usernames_set, display_names_set = load_usernames_from_csv(csv_path)

# Regular expression pattern for IPv4 addresses.
ipv4_pattern = r"(\W?|^)([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})(\W?|$)"
ipv4_compiled = re.compile(ipv4_pattern)

# Function to replace matched IPv4 addresses.
def ipv4_replacer(match):
    return match.group(1) + "***.***.***.***" + match.group(3)

# Regular expression pattern for AWS-specific IPv4 addresses.
aws_ipv4_pattern = r"ip-\d{1,3}-\d{1,3}-\d{1,3}-\d{1,3}"
aws_ipv4_compiled = re.compile(aws_ipv4_pattern)
aws_ipv4_replacement = "***-***-***-***"

# Redaction function
def redact_line(line):
    # Convert to lowercase for case-insensitive matching
    lower_line = line.lower()
    
    # Redact any matching usernames.
    for username in usernames_set:
        lower_username = username.lower()
        if lower_username in lower_line:
            line = line.replace(username, name_replacement)
            
    # Redact patterns like lowerFirstName, lowerLastName, firstName, and lastName
    for display_name in display_names_set:
        split_name = display_name.lower().split()
        # Assuming the display name only contains first and last names
        if len(split_name) == 2:
            first_name, last_name = split_name
            # Create patterns for both lowercase and regular-case variants
            combined_lower_name = f"lowerfirstname={first_name},lowerlastname={last_name}"
            combined_regular_name = f"firstname={first_name.capitalize()},lastname={last_name.capitalize()}"
            
            # Check and redact if any pattern matches
            if combined_lower_name in lower_line:
                line = line.replace(f"lowerFirstName={first_name.capitalize()},lowerLastName={last_name.capitalize()}", name_replacement)
            
            if combined_regular_name in line:
                line = line.replace(combined_regular_name, name_replacement)
    
    # Redact any matching IP addresses.
    line = ipv4_compiled.sub(ipv4_replacer, line)
    line = aws_ipv4_compiled.sub(aws_ipv4_replacement, line)
    return line

# Process each file in the directory.
for subdir, dirs, files in os.walk(root_directory):
    for filename in tqdm(files, desc="Processing files"):
        # Only process matching file types.
        if filename_pattern.search(filename):
            with open(os.path.join(subdir, filename), "r", encoding="utf-8") as input_file, \
                 open(os.path.join(subdir, f"redacted_{filename}"), "w", encoding="utf-8") as output_file:
                # Read each line, redact sensitive info, and write to new file
                for line in input_file:
                    output_file.write(redact_line(line) + '\n')
                
            # Delete original file after redaction.
            os.remove(os.path.join(subdir, filename))
