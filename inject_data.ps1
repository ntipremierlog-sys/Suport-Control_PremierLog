# Set console output encoding to UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$lines = Get-Content "xlsx_output_utf8.txt" -Encoding utf8

$tasks = @()
$currentSheet = ""

foreach ($line in $lines) {
    $trimmedLine = $line.Trim()
    
    if ($trimmedLine -like "*SHEET: Cronograma Geral*") {
        $currentSheet = "Cronograma"
        continue
    } elseif ($trimmedLine -like "*SHEET: Governan*") {
        $currentSheet = "Governança"
        continue
    } elseif ($trimmedLine -like "*SHEET:*") {
        $currentSheet = ""
        continue
    }
    
    if ($currentSheet -eq "Cronograma") {
        if ($trimmedLine -like "A1:*" -or $trimmedLine -like "A2:*" -or $trimmedLine -like "A4:*" -or $trimmedLine -like "A5:*" -or $trimmedLine -clike "*FASE*" -or $trimmedLine -like "==*") {
            continue
        }
        if ($trimmedLine -eq "") { continue }
        
        $parts = $trimmedLine.Split("|")
        if ($parts.Length -ge 7) {
            function Clean-Part($p) {
                if ($p -eq $null) { return "" }
                $clean = $p.Trim()
                $clean = $clean -replace '^[A-Z]\d+:\s*', ''
                return $clean.Trim()
            }
            
            $id = Clean-Part $parts[0]
            $title = Clean-Part $parts[1]
            $phase = Clean-Part $parts[2]
            $assignee = Clean-Part $parts[3]
            $deadlineRaw = Clean-Part $parts[4]
            $statusRaw = Clean-Part $parts[5]
            $priorityRaw = Clean-Part $parts[6]
            
            $obs = ""
            if ($parts.Length -gt 7) { $obs = Clean-Part $parts[7] }
            $js3 = ""
            if ($parts.Length -gt 8) { $js3 = Clean-Part $parts[8] }
            $tags = ""
            if ($parts.Length -gt 9) { $tags = Clean-Part $parts[9] }
            
            if ($id -eq "" -or -not ($id -match "^[Ff]\d+-[0-9a-zA-Z]+$")) { continue }
            
            # Map Date DD/MM/YYYY to YYYY-MM-DD
            $deadline = ""
            if ($deadlineRaw -match "^(\d{2})/(\d{2})/(\d{4})$") {
                $deadline = "$($Matches[3])-$($Matches[2])-$($Matches[1])"
            } else {
                $deadline = "2026-06-03"
            }
            
            # Map Status
            $status = "todo"
            if ($statusRaw -like "*Concl*" -or $statusRaw -like "*Aceite*") {
                $status = "done"
            } elseif ($statusRaw -like "*andamento*") {
                $status = "in_progress"
            }
            
            # Map Priority
            $priority = "M" + [char]233 + "dia"
            $pUpper = $priorityRaw.ToUpper()
            if ($pUpper -like "*URGENTE*" -or $pUpper -like "*ALTA*") {
                $priority = "Alta"
            } elseif ($pUpper -like "*BAIXA*") {
                $priority = "Baixa"
            }
            
            # Map Team
            $team = "Qualidade"
            if ($title -like "*Financeiro*" -or $title -like "* Faturamento*" -or $title -like "*Faturamento *") { 
                $team = "Financeiro" 
            } elseif ($title -like "*Admiss*" -or $title -like "* DP*" -or $title -like "*DP *") { 
                $team = "DP" 
            } elseif ($title -like "* R&S*" -or $title -like "*R&S *") { 
                $team = "R&S" 
            } elseif ($title -like "*Operacional*" -or $title -like "*Contrato Petrobras*") { 
                $team = "Operacional" 
            } elseif ($title -like "*TI*" -or $title -like "* email*" -or $title -like "* e-mail*") { 
                $team = "Tecnologia" 
            } elseif ($assignee -eq "Ronaldo Brito" -or $assignee -like "*GG*") { 
                $team = "Gest" + [char]227 + "o" 
            }
            
            $desc = $obs
            if ($js3 -and $js3 -ne "-") {
                $desc += " [Entreg" + [char]225 + "vel JS3: $js3]"
            }
            
            $tasks += @{
                id = $id
                title = $title
                desc = $desc
                team = $team
                subSector = $phase
                assignee = $assignee
                status = $status
                deadline = $deadline
                priority = $priority
                project = "proj-sgq"
            }
        }
    } elseif ($currentSheet -eq "Governança") {
        if ($trimmedLine -like "A1:*" -or $trimmedLine -like "A2:*" -or $trimmedLine -like "A4:*" -or $trimmedLine -like "==*") {
            continue
        }
        if ($trimmedLine -eq "") { continue }
        
        $parts = $trimmedLine.Split("|")
        if ($parts.Length -ge 6) {
            function Clean-Part2($p) {
                if ($p -eq $null) { return "" }
                $clean = $p.Trim()
                $clean = $clean -replace '^[A-Z]\d+:\s*', ''
                return $clean.Trim()
            }
            
            $ritual = Clean-Part2 $parts[0]
            $freq = Clean-Part2 $parts[1]
            $partic = Clean-Part2 $parts[2]
            $objective = Clean-Part2 $parts[3]
            $resp = Clean-Part2 $parts[4]
            $nextDateRaw = Clean-Part2 $parts[5]
            $statusRaw = ""
            if ($parts.Length -gt 6) { $statusRaw = Clean-Part2 $parts[6] }
            
            # Map Date DD/MM/YYYY to YYYY-MM-DD
            $deadline = ""
            if ($nextDateRaw -match "^(\d{2})/(\d{2})/(\d{4})$") {
                $deadline = "$($Matches[3])-$($Matches[2])-$($Matches[1])"
            } else {
                $deadline = "2026-06-10"
            }
            
            # Map Status
            $status = "todo"
            if ($statusRaw -like "*Concl*") {
                $status = "done"
            } elseif ($statusRaw -like "*andamento*") {
                $status = "in_progress"
            }
            
            # Form ID
            $id = "RIT-" + (Get-Random -Minimum 100 -Maximum 999)
            
            $tasks += @{
                id = $id
                title = $ritual
                desc = "$($objective) (Freq: $($freq), Partic: $($partic), Resp: $($resp))"
                team = "Gest" + [char]227 + "o"
                subSector = "Ritual de Governan" + [char]231 + "a"
                assignee = $resp
                status = $status
                deadline = $deadline
                priority = "Alta"
                project = "proj-sgq"
            }
        }
    }
}

# Group tasks for roadmaps
$roadmaps = @{
    'Financeiro' = @()
    'Operacional' = @()
    'R&S' = @()
    'DP' = @()
    'Qualidade' = @()
    'Tecnologia' = @()
}

foreach ($t in $tasks) {
    if ($t.id -like "F*") { # Only sheet 1 tasks are steps
        $stepTeam = $t.team
        if ($stepTeam -eq ("Gest" + [char]227 + "o")) { $stepTeam = "Qualidade" }
        
        if ($roadmaps.ContainsKey($stepTeam)) {
            $flowName = $t.subSector
            if ($flowName -eq "Fase 1") { $flowName = "Fase 1 - Prepara" + [char]231 + [char]227 + "o" }
            elseif ($flowName -eq "Fase 2") { $flowName = "Fase 2 - Implanta" + [char]231 + [char]227 + "o" }
            elseif ($flowName -eq "Fase 3") { $flowName = "Fase 3 - Implementa" + [char]231 + [char]227 + "o" }
            elseif ($flowName -eq "Fase 4") { $flowName = "Fase 4 - Monitoramento e Encerramento" }
            
            $stepStatus = "A iniciar"
            if ($t.status -eq "done") { $stepStatus = "Conclu" + [char]237 + "do" }
            elseif ($t.status -eq "in_progress") { $stepStatus = "Em andamento" }
            
            $roadmaps[$stepTeam] += @{
                id = "step-" + $t.id
                title = $t.title
                fluxo = $flowName
                status = $stepStatus
            }
        }
    }
}

# Build JS Code strings
$tasksJs = ConvertTo-Json -InputObject $tasks -Depth 5
$projectsJs = @"
[
      {
        id: "proj-sgq",
        name: "Implanta\u00e7\u00e3o do SGQ | ISO 9001:2015",
        team: "Qualidade",
        progress: 24,
        startDate: "2026-05-11",
        deadline: "2026-11-10",
        status: "Em Execu\u00e7\u00e3o",
        description: "Plano de Implanta\u00e7\u00e3o do Sistema de Gest\u00e3o da Qualidade (SGQ) na Premier Logistics, sob coordena\u00e7\u00e3o da Consultoria JS3 e da Analista SGQ Ligiane Castro."
      }
    ]
"@

$roadmapsJs = ConvertTo-Json -InputObject $roadmaps -Depth 5

# Function to inject into file
function Inject-Data-To-File($filePath) {
    Write-Output "Injecting data into: $filePath"
    $content = Get-Content $filePath -Raw -Encoding utf8
    
    # Replace initialTasks
    $content = $content -replace '(?s)const initialTasks = \[.*?\];', "const initialTasks = $tasksJs;"
    # Replace initialProjects
    $content = $content -replace '(?s)const initialProjects = \[.*?\];', "const initialProjects = $projectsJs;"
    # Replace initialRoadmaps
    $content = $content -replace '(?s)const initialRoadmaps = \{.*?\};', "const initialRoadmaps = $roadmapsJs;"
    # Replace DATA_VERSION to force cache reset
    $content = $content -replace "const DATA_VERSION = '2026-06-03-v\d+';", "const DATA_VERSION = '2026-06-03-v6';"
    
    # Save back to file using UTF-8 without BOM
    $utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($filePath, $content, $utf8NoBOM)
}

Inject-Data-To-File "index.html"
Inject-Data-To-File "dashboard_premier_logistics.html"
Inject-Data-To-File "premier_logistics_platform.html"

Write-Output "Injection Complete!"
