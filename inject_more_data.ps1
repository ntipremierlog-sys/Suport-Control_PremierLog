# Set console output encoding to UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$lines = Get-Content "xlsx_output_utf8.txt" -Encoding utf8

$indicators = @()
$diagnostics = @()
$currentSheet = ""

foreach ($line in $lines) {
    $trimmedLine = $line.Trim()
    
    if ($trimmedLine -like "*SHEET: Indicadores*") {
        $currentSheet = "Indicadores"
        continue
    } elseif ($trimmedLine -like "*SHEET: Diagn*") {
        $currentSheet = "Diagnostico"
        continue
    } elseif ($trimmedLine -like "*SHEET:*") {
        $currentSheet = ""
        continue
    }
    
    if ($currentSheet -eq "Indicadores") {
        if ($trimmedLine -like "A1:*" -or $trimmedLine -like "A2:*" -or $trimmedLine -like "A4:*" -or $trimmedLine -like "==*") {
            continue
        }
        if ($trimmedLine -eq "") { continue }
        
        $parts = $trimmedLine.Split("|")
        if ($parts.Length -ge 5) {
            function Clean-Part3($p) {
                if ($p -eq $null) { return "" }
                $clean = $p.Trim()
                $clean = $clean -replace '^[A-Z]\d+:\s*', ''
                return $clean.Trim()
            }
            $name = Clean-Part3 $parts[0]
            $freq = Clean-Part3 $parts[1]
            $target = Clean-Part3 $parts[2]
            $resp = Clean-Part3 $parts[3]
            $base = Clean-Part3 $parts[4]
            $obs = ""
            if ($parts.Length -gt 5) { $obs = Clean-Part3 $parts[5] }
            
            if ($name -ne "") {
                $indicators += @{
                    name = $name
                    freq = $freq
                    target = $target
                    resp = $resp
                    base = $base
                    obs = $obs
                }
            }
        }
    } elseif ($currentSheet -eq "Diagnostico") {
        if ($trimmedLine -like "A1:*" -or $trimmedLine -like "A2:*" -or $trimmedLine -like "A4:*" -or $trimmedLine -like "==*") {
            continue
        }
        if ($trimmedLine -eq "") { continue }
        
        $parts = $trimmedLine.Split("|")
        if ($parts.Length -ge 5) {
            function Clean-Part4($p) {
                if ($p -eq $null) { return "" }
                $clean = $p.Trim()
                $clean = $clean -replace '^[A-Z]\d+:\s*', ''
                $clean = $clean -replace '\?', ''
                return $clean.Trim()
            }
            $sector = Clean-Part4 $parts[0]
            $disc = Clean-Part4 $parts[1]
            $swot = Clean-Part4 $parts[2]
            $tree = Clean-Part4 $parts[3]
            $workshop = Clean-Part4 $parts[4]
            $status = ""
            if ($parts.Length -gt 5) { $status = Clean-Part4 $parts[5] }
            
            if ($sector -ne "" -and -not ($sector -like "*Nota:*") -and -not ($sector -like "*\?\?*")) {
                $diagnostics += @{
                    sector = $sector
                    disc = $disc
                    swot = $swot
                    tree = $tree
                    workshop = $workshop
                    status = $status
                }
            }
        }
    }
}

# Convert arrays to JS arrays using characters encoding safety
$indicatorsJs = ConvertTo-Json -InputObject $indicators -Depth 5
$diagnosticsJs = ConvertTo-Json -InputObject $diagnostics -Depth 5

Write-Output "Parsed $($indicators.Length) indicators and $($diagnostics.Length) diagnostics."

# JS open/close/switch code to inject
# String literals use escape sequences to guarantee ASCII safety (e.g. \u00ed = í)
$jsTabsCode = @"
    function switchDrawerTab(tabName) {
      const buttons = document.querySelectorAll('.drawer-tab-btn');
      buttons.forEach(btn => {
        btn.classList.remove('active');
        btn.style.color = 'var(--text-muted)';
        btn.style.borderBottomColor = 'transparent';
        btn.style.fontWeight = '600';
      });

      const activeBtn = document.getElementById('tab-btn-' + tabName);
      if (activeBtn) {
        activeBtn.classList.add('active');
        activeBtn.style.color = 'var(--primary)';
        activeBtn.style.borderBottomColor = 'var(--primary)';
        activeBtn.style.fontWeight = '700';
      }

      document.getElementById('drawer-tab-content-tasks').classList.add('hidden');
      document.getElementById('drawer-tab-content-indicators').classList.add('hidden');
      document.getElementById('drawer-tab-content-diagnostics').classList.add('hidden');

      document.getElementById('drawer-tab-content-' + tabName).classList.remove('hidden');
    }

    // Abrir o Painel Lateral Deslizante (Slide-over Drawer)
    function openProjectDrawer(projectId) {
      const proj = state.projects.find(p => p.id === projectId);
      if (!proj) return;

      state.currentSelectedProject = proj;

      // Definir textos no drawer
      document.getElementById('drawer-project-title').textContent = proj.name;
      document.getElementById('drawer-project-desc').textContent = proj.description || 'Sem escopo cadastrado.';
      document.getElementById('drawer-project-team').textContent = proj.subSector ? proj.team + ' (' + proj.subSector + ')' : proj.team;
      document.getElementById('drawer-project-status').textContent = proj.status;
      document.getElementById('drawer-project-start').textContent = formatDate(proj.startDate);
      document.getElementById('drawer-project-deadline').textContent = formatDate(proj.deadline);
      document.getElementById('drawer-project-progress-pct').textContent = proj.progress + '%';
      
      const fill = document.getElementById('drawer-project-progress-fill');
      fill.className = 'progress-bar-fill fill-' + getTeamSlug(proj.team);
      fill.style.width = proj.progress + '%';

      // Renderizar tarefas vinculadas a este projeto
      const tasksList = document.getElementById('drawer-project-tasks-list');
      tasksList.innerHTML = '';
      
      const linkedTasks = state.tasks.filter(t => t.project === projectId);
      if (linkedTasks.length === 0) {
        tasksList.innerHTML = '<p style="font-size:0.8rem; color:var(--text-muted); text-align:center; padding:1rem;">Nenhuma tarefa vinculada a este projeto.</p>';
      } else {
        linkedTasks.forEach(task => {
          tasksList.innerHTML += '<div class="drawer-task-item"><div class="drawer-task-info"><span class="drawer-task-title">' + task.title + '</span><span class="drawer-task-meta">Prazo: ' + formatDate(task.deadline) + ' | Resp: ' + task.assignee + '</span></div><span class="badge status-badge status-badge-' + task.status + '">' + formatStatus(task.status) + '</span></div>';
        });
      }

      // Configuracao de abas extras para o projeto SGQ
      const tabIndicators = document.getElementById('tab-btn-indicators');
      const tabDiagnostics = document.getElementById('tab-btn-diagnostics');
      
      if (projectId === 'proj-sgq') {
        if (tabIndicators) tabIndicators.style.display = 'block';
        if (tabDiagnostics) tabDiagnostics.style.display = 'block';
        
        // Renderizar indicadores
        const indList = document.getElementById('drawer-project-indicators-list');
        if (indList && typeof state.indicators !== 'undefined') {
          let indicatorsHtml = '';
          state.indicators.forEach(ind => {
            indicatorsHtml += '<div style="background: var(--bg-primary); padding: 0.85rem; border-radius: var(--radius-md); border: 1px solid var(--border-color); display: flex; flex-direction: column; gap: 0.4rem;"><div style="display: flex; justify-content: space-between; align-items: flex-start; gap: 1rem;"><span style="font-weight: 700; font-size: 0.85rem; color: var(--text-main);">' + ind.name + '</span><span style="font-size: 0.72rem; font-weight: 600; padding: 0.15rem 0.4rem; border-radius: 4px; background: var(--primary-light); color: var(--primary); text-transform: uppercase;">' + ind.freq + '</span></div><div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.5rem; font-size: 0.78rem; border-top: 1px solid var(--border-color); padding-top: 0.4rem; margin-top: 0.2rem;"><div><span style="color: var(--text-muted);">Meta:</span> <strong style="color: var(--text-main);">' + ind.target + '</strong></div><div><span style="color: var(--text-muted);">Resp:</span> <strong style="color: var(--text-main);">' + ind.resp + '</strong></div></div>' + (ind.base !== '-' ? '<div style="font-size: 0.78rem;"><span style="color: var(--text-muted);">Linha de Base:</span> <strong style="color: var(--text-main);">' + ind.base + '</strong></div>' : '') + (ind.obs ? '<div style="font-size: 0.75rem; color: var(--text-muted); font-style: italic; margin-top: 0.15rem;"><i data-lucide="info" style="width: 12px; height: 12px; display: inline-block; vertical-align: middle; margin-right: 0.15rem;"></i>' + ind.obs + '</div>' : '') + '</div>';
          });
          indList.innerHTML = indicatorsHtml;
        }

        // Renderizar diagnostico
        const diagList = document.getElementById('drawer-project-diagnostics-list');
        if (diagList && typeof state.diagnostics !== 'undefined') {
          let diagHtml = '<table class="data-table" style="width: 100%; min-width: 500px; font-size: 0.78rem;"><thead><tr><th style="padding: 0.5rem;">Setor / Respons\u00e1vel</th><th style="padding: 0.5rem; text-align: center;">DISC</th><th style="padding: 0.5rem; text-align: center;">SWOT</th><th style="padding: 0.5rem; text-align: center;">Processos</th><th style="padding: 0.5rem; text-align: center;">Workshop</th><th style="padding: 0.5rem; text-align: center;">Status Geral</th></tr></thead><tbody>';
          state.diagnostics.forEach(d => {
            const getBadge = (val) => {
              if (val === 'Conclu\u00eddo') return '<span style="color: var(--success); font-weight: 700;">\u2713 Sim</span>';
              if (val === 'Parcial') return '<span style="color: var(--warning); font-weight: 700;">\u26a0\ufe0f Parcial</span>';
              if (val === '-') return '<span style="color: var(--text-muted);">-</span>';
              if (val === 'Quase completo') return '<span style="color: var(--success); font-weight: 700; background: var(--success-light); padding: 0.1rem 0.3rem; border-radius: 4px;">Quase completo</span>';
              if (val === 'Em andamento') return '<span style="color: var(--warning); font-weight: 700; background: var(--warning-light); padding: 0.1rem 0.3rem; border-radius: 4px;">Em andamento</span>';
              return '<span style="font-weight: 600;">' + val + '</span>';
            };
            diagHtml += '<tr><td style="padding: 0.5rem; font-weight: 600;">' + d.sector + '</td><td style="padding: 0.5rem; text-align: center;">' + getBadge(d.disc) + '</td><td style="padding: 0.5rem; text-align: center;">' + getBadge(d.swot) + '</td><td style="padding: 0.5rem; text-align: center;">' + getBadge(d.tree) + '</td><td style="padding: 0.5rem; text-align: center;">' + getBadge(d.workshop) + '</td><td style="padding: 0.5rem; text-align: center;">' + getBadge(d.status) + '</td></tr>';
          });
          diagHtml += '</tbody></table>';
          diagList.innerHTML = diagHtml;
        }
      } else {
        if (tabIndicators) tabIndicators.style.display = 'none';
        if (tabDiagnostics) tabDiagnostics.style.display = 'none';
      }

      switchDrawerTab('tasks');

      // Animando a abertura
      document.getElementById('project-drawer-overlay').classList.add('active');
      document.getElementById('project-drawer').classList.add('active');

      safeCreateIcons();
    }

    function closeProjectDrawer() {
      document.getElementById('project-drawer-overlay').classList.remove('active');
      document.getElementById('project-drawer').classList.remove('active');
      state.currentSelectedProject = null;
    }
"@

$htmlDrawerTabs = @"
      <!-- Project Tabs and Content -->
      <div id="drawer-project-tabs-container" style="margin-top: 1.5rem; margin-bottom: 1rem;">
        <div style="display: flex; border-bottom: 1px solid var(--border-color); gap: 1rem; margin-bottom: 1rem;">
          <button class="drawer-tab-btn active" onclick="switchDrawerTab('tasks')" id="tab-btn-tasks" style="padding: 0.5rem 0.25rem; font-size: 0.82rem; font-weight: 700; color: var(--primary); border-bottom: 2px solid var(--primary); cursor: pointer; transition: all 0.2s;">Tarefas Vinculadas</button>
          <button class="drawer-tab-btn" onclick="switchDrawerTab('indicators')" id="tab-btn-indicators" style="padding: 0.5rem 0.25rem; font-size: 0.82rem; font-weight: 600; color: var(--text-muted); border-bottom: 2px solid transparent; cursor: pointer; transition: all 0.2s; display: none;">Indicadores (KPIs)</button>
          <button class="drawer-tab-btn" onclick="switchDrawerTab('diagnostics')" id="tab-btn-diagnostics" style="padding: 0.5rem 0.25rem; font-size: 0.82rem; font-weight: 600; color: var(--text-muted); border-bottom: 2px solid transparent; cursor: pointer; transition: all 0.2s; display: none;">Diagn&oacute;stico Setorial</button>
        </div>
      </div>

      <div id="drawer-tab-content-tasks">
        <div class="drawer-task-list" id="drawer-project-tasks-list">
          <!-- Loaded dynamically based on the project selection -->
        </div>
      </div>

      <div id="drawer-tab-content-indicators" class="hidden">
        <div id="drawer-project-indicators-list" style="display: flex; flex-direction: column; gap: 0.75rem; max-height: 400px; overflow-y: auto; padding-right: 0.25rem;">
          <!-- Loaded dynamically for SGQ project -->
        </div>
      </div>

      <div id="drawer-tab-content-diagnostics" class="hidden">
        <div id="drawer-project-diagnostics-list" style="display: flex; flex-direction: column; gap: 0.75rem; overflow-x: auto; max-height: 400px; overflow-y: auto; padding-right: 0.25rem;">
          <!-- Loaded dynamically for SGQ project -->
        </div>
      </div>
"@

# Helper function to update files
function Inject-More-Data-To-File($filePath) {
    Write-Output "Updating file: $filePath"
    $content = Get-Content $filePath -Raw -Encoding utf8
    
    # 1. Inject initialIndicators & initialDiagnostics after initialRoadmaps
    $content = $content -replace '(?s)(const initialRoadmaps = \{.*?\};)', "`$1 const initialIndicators = $indicatorsJs; const initialDiagnostics = $diagnosticsJs;"
    
    # 2. Inject HTML Drawer Tabs in #project-drawer
    $targetHtml = '(?s)<div>\s*<span class="drawer-section-title">Tarefas Vinculadas</span>\s*<div class="drawer-task-list" id="drawer-project-tasks-list">\s*<!-- Loaded dynamically based on the project selection -->\s*</div>'
    $content = $content -replace $targetHtml, $htmlDrawerTabs
    
    # 3. Inject JS state initialization for indicators & diagnostics
    $targetStateInit = '(?s)const state = \{\s*currentUser: null,\s*tasks: cachedTasks \|\| \[\.\.\.initialTasks\],\s*projects: cachedProjects \|\| \[\.\.\.initialProjects\],\s*roadmaps: cachedRoadmaps \|\| JSON\.parse\(JSON\.stringify\(initialRoadmaps\)\)[^,\n]*?,'
    $newStateInit = @"
    let cachedIndicators = null;
    try {
      const ind = safeStorage.getItem('premier_indicators');
      if (ind) cachedIndicators = JSON.parse(ind);
    } catch(e) {}
    
    let cachedDiagnostics = null;
    try {
      const diag = safeStorage.getItem('premier_diagnostics');
      if (diag) cachedDiagnostics = JSON.parse(diag);
    } catch(e) {}

    const state = {
      currentUser: null,
      tasks: cachedTasks || [...initialTasks],
      projects: cachedProjects || [...initialProjects],
      roadmaps: cachedRoadmaps || JSON.parse(JSON.stringify(initialRoadmaps)), // Deep copy
      indicators: cachedIndicators || [...initialIndicators],
      diagnostics: cachedDiagnostics || [...initialDiagnostics],
"@
    $content = $content -replace $targetStateInit, $newStateInit
    
    # 4. Inject saveStateToStorage persistence
    $targetSave = '(?s)safeStorage\.setItem\(''premier_roadmaps'', JSON\.stringify\(state\.roadmaps\)\);\s*safeStorage\.setItem\(''premier_notifications'', JSON\.stringify\(state\.notifications\)\);'
    $newSave = "safeStorage.setItem('premier_roadmaps', JSON.stringify(state.roadmaps)); safeStorage.setItem('premier_indicators', JSON.stringify(state.indicators)); safeStorage.setItem('premier_diagnostics', JSON.stringify(state.diagnostics)); safeStorage.setItem('premier_notifications', JSON.stringify(state.notifications));"
    $content = $content -replace $targetSave, $newSave

    # 5. Inject cache clearing removeItems
    $targetClear = '(?s)safeStorage\.removeItem\(''premier_roadmaps''\);\s*safeStorage\.removeItem\(''premier_notifications''\);'
    $newClear = "safeStorage.removeItem('premier_roadmaps'); safeStorage.removeItem('premier_indicators'); safeStorage.removeItem('premier_diagnostics'); safeStorage.removeItem('premier_notifications');"
    $content = $content -replace $targetClear, $newClear

    # 6. Inject openProjectDrawer, closeProjectDrawer and switchDrawerTab
    $targetDrawerJs = '(?s)// Abrir o Painel Lateral Deslizante \(Slide-over Drawer\)\s*function openProjectDrawer\(projectId\) \{.*?\}\s*function closeProjectDrawer\(\) \{.*?\s*state\.currentSelectedProject = null;\s*\}'
    $content = $content -replace $targetDrawerJs, $jsTabsCode
    
    # 7. Bump DATA_VERSION to v7 to reset cache
    $content = $content -replace "const DATA_VERSION = '2026-06-03-v6';", "const DATA_VERSION = '2026-06-03-v7';"
    
    # Save back
    $utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($filePath, $content, $utf8NoBOM)
}

Inject-More-Data-To-File "index.html"
Inject-More-Data-To-File "dashboard_premier_logistics.html"
Inject-More-Data-To-File "premier_logistics_platform.html"

Write-Output "Extra spreadsheet injection completed!"
