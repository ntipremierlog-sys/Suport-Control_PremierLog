Add-Type -AssemblyName System.IO.Compression.FileSystem

try {
    $xlsxFile = Get-ChildItem -Filter "SGQ*.xlsx" | Select-Object -First 1
    $zip = [System.IO.Compression.ZipFile]::OpenRead($xlsxFile.FullName)
    
    # Load shared strings
    $sharedStringsEntry = $zip.Entries | Where-Object { $_.FullName -eq "xl/sharedStrings.xml" }
    $sharedStrings = @()
    if ($sharedStringsEntry) {
        $stream = $sharedStringsEntry.Open()
        $xml = [xml](New-Object System.IO.StreamReader($stream)).ReadToEnd()
        $stream.Close()
        
        $siNodes = $xml.GetElementsByTagName("si")
        foreach ($si in $siNodes) {
            # Find all <t> elements under this <si>
            $tNodes = $si.GetElementsByTagName("t")
            $text = ""
            foreach ($t in $tNodes) {
                $text += $t.InnerText
            }
            $sharedStrings += $text
        }
    }
    
    Write-Output "Shared Strings Count: $($sharedStrings.Count)"
    
    # Helper to parse a sheet file
    function Parse-Sheet($sheetPath, $sheetName) {
        $sheetEntry = $zip.Entries | Where-Object { $_.FullName -eq $sheetPath }
        if (-not $sheetEntry) { return }
        
        Write-Output "`n=================================================="
        Write-Output "SHEET: $sheetName ($sheetPath)"
        Write-Output "=================================================="
        
        $stream = $sheetEntry.Open()
        $xml = [xml](New-Object System.IO.StreamReader($stream)).ReadToEnd()
        $stream.Close()
        
        # Get all rows
        $rows = $xml.GetElementsByTagName("row")
        foreach ($row in $rows) {
            $rowData = @()
            $cells = $row.GetElementsByTagName("c")
            $hasData = $false
            foreach ($c in $cells) {
                $ref = $c.GetAttribute("r")
                $type = $c.GetAttribute("t")
                
                $vNode = $c.GetElementsByTagName("v")
                $val = ""
                if ($vNode.Count -gt 0) {
                    $val = $vNode[0].InnerText
                }
                
                $cellText = ""
                if ($type -eq "s" -and $val -ne "") {
                    $idx = [int]$val
                    $cellText = $sharedStrings[$idx]
                } elseif ($val -ne "") {
                    $cellText = $val
                }
                
                if ($cellText -ne "") {
                    $rowData += ($ref + ": " + $cellText)
                    $hasData = $true
                }
            }
            if ($hasData) {
                Write-Output ($rowData -join " | ")
            }
        }
    }
    
    # Parse all sheets
    Parse-Sheet "xl/worksheets/sheet1.xml" "Cronograma Geral"
    Parse-Sheet "xl/worksheets/sheet2.xml" "Governança e Rituais"
    Parse-Sheet "xl/worksheets/sheet3.xml" "Indicadores do Projeto"
    Parse-Sheet "xl/worksheets/sheet4.xml" "Diagnóstico Setorial"
    
} catch {
    Write-Error $_
} finally {
    if ($zip) { $zip.Dispose() }
}
