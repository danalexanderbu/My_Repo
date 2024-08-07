# for files that exceed excel row limit
# Load necessary assemblies
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

# Create new Excel object
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false

# Create a new workbook
$workbook = $excel.Workbooks.Add()

# Load the CSV data
$csvData = Import-Csv -Path 'C:\path\to\your\csvfile.csv'

# Sort the data by project_key
$sortedData = $csvData | Sort-Object project_key

# Initialize variables
$currentKey = $null
$worksheet = $null

# Loop through each row in the sorted data
foreach ($row in $sortedData) {
    if ($currentKey -ne $row.project_key) {
        # The project key has changed, so create a new worksheet
        $currentKey = $row.project_key
        $worksheet = $workbook.Worksheets.Add()
        $worksheet.Name = $currentKey

        # Write the header row
        $headerRow = $csvData[0].PSObject.Properties.Name
        $worksheet.Cells.Item(1, $_) = $headerRow[$_ - 1] for (1..$headerRow.Count)
        $currentRow = 2
    }

    # Write the data row
    $dataRow = $row.PSObject.Properties.Value
    $worksheet.Cells.Item($currentRow, $_) = $dataRow[$_ - 1] for (1..$dataRow.Count)
    $currentRow++
}

# Save the workbook and quit Excel
$workbook.SaveAs('C:\path\to\your\excelfile.xlsx', 51) # 51 = xlsx file format
$excel.Quit()

# Clean up
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

# Output completion message
Write-Output "Conversion completed successfully."
