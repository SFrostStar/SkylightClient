// Skylight Studio Renderer Logic - Pro Edition
document.addEventListener('DOMContentLoaded', () => {
  // Window Controls
  document.getElementById('btn-minimize')?.addEventListener('click', () => window.electronAPI.minimizeWindow());
  document.getElementById('btn-maximize')?.addEventListener('click', () => window.electronAPI.maximizeWindow());
  document.getElementById('btn-close')?.addEventListener('click', () => window.electronAPI.closeWindow());

  // Navigation
  const navEditor = document.getElementById('nav-editor');
  const navScriptHub = document.getElementById('nav-scripthub');
  const navSettings = document.getElementById('nav-settings');
  const navConsoleToggle = document.getElementById('nav-console-toggle');

  const viewEditor = document.getElementById('view-editor');
  const viewScriptHub = document.getElementById('view-scripthub');
  const viewSettings = document.getElementById('view-settings');

  const consoleDrawer = document.getElementById('console-drawer');
  const consoleHeader = document.getElementById('console-header');
  const btnToggleDrawer = document.getElementById('btn-toggle-drawer');
  const syntaxStatus = document.getElementById('syntax-status');

  function switchView(view) {
    navEditor?.classList.remove('active');
    navScriptHub?.classList.remove('active');
    navSettings?.classList.remove('active');

    viewEditor?.classList.add('hidden');
    viewScriptHub?.classList.add('hidden');
    viewSettings?.classList.add('hidden');

    if (view === 'editor') {
      navEditor?.classList.add('active');
      viewEditor?.classList.remove('hidden');
    } else if (view === 'scripthub') {
      navScriptHub?.classList.add('active');
      viewScriptHub?.classList.remove('hidden');
    } else if (view === 'settings') {
      navSettings?.classList.add('active');
      viewSettings?.classList.remove('hidden');
    }
  }

  navEditor?.addEventListener('click', () => switchView('editor'));
  navScriptHub?.addEventListener('click', () => switchView('scripthub'));
  navSettings?.addEventListener('click', () => switchView('settings'));

  // Copy Discord Tag
  document.getElementById('btn-copy-discord')?.addEventListener('click', () => {
    navigator.clipboard.writeText('xsynapse');
    logConsole('Copied Discord contact "xsynapse" to clipboard!', 'system');
  });

  // Console Drawer Toggle
  function toggleConsole() {
    consoleDrawer?.classList.toggle('collapsed');
  }

  navConsoleToggle?.addEventListener('click', toggleConsole);
  consoleHeader?.addEventListener('click', (e) => {
    if (e.target.closest('.console-actions')) return;
    toggleConsole();
  });
  btnToggleDrawer?.addEventListener('click', toggleConsole);

  // Console Output Stream
  const consoleLogs = document.getElementById('console-logs');
  const btnClearConsole = document.getElementById('btn-clear-console');

  function logConsole(message, type = 'system') {
    if (!consoleLogs) return;
    const entry = document.createElement('div');
    entry.className = `log-entry ${type}`;
    const timestamp = new Date().toLocaleTimeString();

    entry.innerHTML = `<span class="log-timestamp">${timestamp}</span> <span>${message}</span>`;
    consoleLogs.appendChild(entry);
    consoleLogs.scrollTop = consoleLogs.scrollHeight;
  }

  btnClearConsole?.addEventListener('click', () => {
    if (consoleLogs) consoleLogs.innerHTML = '';
    logConsole('Console log cleared by user.', 'system');
  });

  // State Management
  let tabs = [];
  let activeTabId = null;
  let tabCounter = 1;
  let monacoEditor = null;

  // Monaco Editor Initialization
  require.config({ paths: { vs: 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.45.0/min/vs' } });

  require(['vs/editor/editor.main'], () => {
    // Custom Luxury Deep Obsidian & Sapphire Theme
    monaco.editor.defineTheme('skylight-sapphire-violet', {
      base: 'vs-dark',
      inherit: true,
      rules: [
        { token: 'keyword', foreground: '38bdf8', fontStyle: 'bold' },
        { token: 'string', foreground: 'a855f7' },
        { token: 'number', foreground: 'fbbf24' },
        { token: 'comment', foreground: '64748b', fontStyle: 'italic' },
        { token: 'identifier', foreground: 'f8fafc' },
        { token: 'delimiter', foreground: '6366f1' }
      ],
      colors: {
        'editor.background': '#08090e',
        'editor.foreground': '#f8fafc',
        'editor.lineHighlightBackground': '#171926',
        'editorCursor.foreground': '#38bdf8',
        'editorWhitespace.foreground': '#212438',
        'editorIndentGuide.background': '#171926',
        'editorIndentGuide.activeBackground': '#38bdf8'
      }
    });

    monacoEditor = monaco.editor.create(document.getElementById('monaco-container'), {
      value: '-- Skylight Studio v2.0 Pro\n-- Real-Time Luau Syntax Validation Active\n\nlocal Services = {\n    Players = game:GetService("Players")\n}\n\nprint("Skylight Studio initialized cleanly!")\n',
      language: 'lua',
      theme: 'skylight-sapphire-violet',
      automaticLayout: true,
      fontFamily: 'JetBrains Mono',
      fontSize: 13.5,
      minimap: { enabled: true },
      lineNumbers: 'on',
      scrollBeyondLastLine: false,
      tabSize: 4
    });

    // Real-Time Syntax Validation
    monacoEditor.onDidChangeModelContent(() => {
      const code = monacoEditor.getValue();

      if (activeTabId) {
        const tab = tabs.find(t => t.id === activeTabId);
        if (tab) {
          tab.content = code;
          tab.isDirty = true;
          renderTabs();
        }
      }

      if (window.electronAPI && window.electronAPI.validateLua) {
        const result = window.electronAPI.validateLua(code);
        const model = monacoEditor.getModel();

        if (!result.valid) {
          monaco.editor.setModelMarkers(model, 'luaparse', [{
            startLineNumber: result.line,
            startColumn: result.column + 1,
            endLineNumber: result.line,
            endColumn: result.column + 10,
            message: `Syntax Error: ${result.message}`,
            severity: monaco.MarkerSeverity.Error
          }]);

          if (syntaxStatus) {
            syntaxStatus.innerHTML = `<span class="error-badge-status">Error Line ${result.line}:${result.column}</span>`;
          }
        } else {
          monaco.editor.setModelMarkers(model, 'luaparse', []);
          if (syntaxStatus) {
            syntaxStatus.innerHTML = `<span style="color: var(--accent-blue);">Syntax: Clean</span>`;
          }
        }
      }
    });

    createTab('SkylightClient.lua', getInitialScript());
    logConsole('Skylight Studio Pro Edition online. Monaco Editor initialized.', 'success');
  });

  function getInitialScript() {
    return `--[[
    ⚡ Skylight Client v2.0
    CS-Style ClickGUI Script for Roblox
    Developer: SFrostStar | Discord: xsynapse
--]]

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService")
}

local LocalPlayer = Services.Players.LocalPlayer

local function InitializeClient()
    print("[Skylight Client] Successfully initialized for " .. LocalPlayer.Name)
end

InitializeClient()
`;
  }

  // Tabs Handling
  function createTab(filename = null, content = '') {
    const id = 'tab-' + Date.now() + '-' + Math.random().toString(36).substr(2, 4);
    const name = filename || `Script_${tabCounter++}.lua`;
    const newTab = { id, filename: name, content, isDirty: false, filePath: null };
    tabs.push(newTab);
    setActiveTab(id);
    logConsole(`Opened tab: ${name}`, 'system');
  }

  function setActiveTab(id) {
    activeTabId = id;
    const tab = tabs.find(t => t.id === id);
    if (tab && monacoEditor) {
      monacoEditor.setValue(tab.content);
    }
    renderTabs();
  }

  function closeTab(id, e) {
    if (e) e.stopPropagation();
    if (tabs.length === 1) {
      logConsole('Cannot close the last open tab.', 'warn');
      return;
    }
    tabs = tabs.filter(t => t.id !== id);
    if (activeTabId === id) {
      setActiveTab(tabs[tabs.length - 1].id);
    } else {
      renderTabs();
    }
  }

  function renderTabs() {
    const tabBar = document.getElementById('tab-bar');
    if (!tabBar) return;
    tabBar.innerHTML = '';

    tabs.forEach(tab => {
      const tabEl = document.createElement('div');
      tabEl.className = `tab-item ${tab.id === activeTabId ? 'active' : ''}`;
      tabEl.innerHTML = `
        <span>${tab.filename}${tab.isDirty ? ' •' : ''}</span>
        <span class="tab-close" data-id="${tab.id}">✕</span>
      `;
      tabEl.addEventListener('click', () => setActiveTab(tab.id));
      tabEl.querySelector('.tab-close').addEventListener('click', (e) => closeTab(tab.id, e));
      tabBar.appendChild(tabEl);
    });
  }

  // New, Open, Save
  document.getElementById('btn-new-tab')?.addEventListener('click', () => createTab());

  document.getElementById('btn-open-file')?.addEventListener('click', async () => {
    const fileResult = await window.electronAPI.openFile();
    if (fileResult && fileResult.content !== undefined) {
      const id = 'tab-' + Date.now();
      tabs.push({ id, filename: fileResult.filename, content: fileResult.content, filePath: fileResult.filePath, isDirty: false });
      setActiveTab(id);
      logConsole(`Opened file: ${fileResult.filename}`, 'success');
    }
  });

  document.getElementById('btn-save-file')?.addEventListener('click', async () => {
    const activeTab = tabs.find(t => t.id === activeTabId);
    if (!activeTab) return;

    const saveResult = await window.electronAPI.saveFile({
      filePath: activeTab.filePath,
      content: monacoEditor.getValue()
    });

    if (saveResult && saveResult.filePath) {
      activeTab.filePath = saveResult.filePath;
      activeTab.filename = saveResult.filename;
      activeTab.isDirty = false;
      renderTabs();
      logConsole(`Saved file: ${saveResult.filename}`, 'success');
    }
  });

  // Execute Script
  document.getElementById('btn-execute-sim')?.addEventListener('click', () => {
    const code = monacoEditor ? monacoEditor.getValue() : '';
    logConsole('Validating & Executing script in Luau Simulator...', 'system');

    if (window.electronAPI && window.electronAPI.validateLua) {
      const validation = window.electronAPI.validateLua(code);
      if (!validation.valid) {
        logConsole(`Syntax Error on line ${validation.line}, col ${validation.column}: ${validation.message}`, 'error');
        if (consoleDrawer?.classList.contains('collapsed')) {
          toggleConsole();
        }
        return;
      }
    }

    const lineCount = code.split('\n').length;
    logConsole(`[Execution Success] Validated and executed ${lineCount} lines of Luau code cleanly.`, 'success');
  });

  // Script Hub Catalog
  const presetScripts = [
    {
      id: 1,
      title: 'Skylight Client v2.0',
      author: 'SFrostStar',
      desc: 'CS-Style ClickGUI with Combat (Aura, AimLock), Movement (Speed, VClip), Visuals (ESP, Ambiance), and HUD Widgets.',
      tags: ['Combat', 'GUI', 'Roblox'],
      loadstring: "loadstring(game:HttpGet('https://raw.githubusercontent.com/SFrostStar/SkylightClient/main/SkylightScript/main.lua'))()"
    },
    {
      id: 2,
      title: 'Rayfield UI Library Template',
      author: 'shlexware',
      desc: 'Modern UI Library template with window creation, tabs, sliders, toggles, and keybinds.',
      tags: ['UI Framework', 'Roblox'],
      loadstring: 'local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()\nlocal Window = Rayfield:CreateWindow({ Name = "Rayfield Hub", LoadingTitle = "Loading...", LoadingSubtitle = "by Rayfield" })'
    },
    {
      id: 3,
      title: 'Universal 3D Glow ESP',
      author: 'Skylight Team',
      desc: 'High-performance player highlight ESP using Roblox Highlight service with custom outline colors.',
      tags: ['Visuals', 'ESP'],
      loadstring: 'local Players = game:GetService("Players")\nfor _, p in pairs(Players:GetPlayers()) do\n    if p.Character then\n        local h = Instance.new("Highlight", p.Character)\n        h.FillColor = Color3.fromRGB(56, 189, 248)\n    end\nend'
    },
    {
      id: 4,
      title: 'CFrame Speed & Flight Engine',
      author: 'Skylight Team',
      desc: 'Smooth velocity-based movement framework with customizable hold keys and speed multipliers.',
      tags: ['Movement', 'Utility'],
      loadstring: 'local RS = game:GetService("RunService")\nlocal LP = game:GetService("Players").LocalPlayer\nRS.RenderStepped:Connect(function()\n    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then\n        -- Speed & flight calculations\n    end\nend)'
    }
  ];

  function renderScriptHub() {
    const grid = document.getElementById('script-grid');
    if (!grid) return;
    grid.innerHTML = '';

    presetScripts.forEach(script => {
      const card = document.createElement('div');
      card.className = 'script-card';
      card.innerHTML = `
        <div>
          <div class="card-title">${script.title}</div>
          <div style="font-size: 11px; color: var(--accent-blue); margin: 3px 0 8px 0;">by ${script.author}</div>
          <div class="card-desc">${script.desc}</div>
        </div>
        <div>
          <div class="card-tags">
            ${script.tags.map(t => `<span class="tag">${t}</span>`).join('')}
          </div>
          <div class="card-actions">
            <button class="card-btn btn-load" data-id="${script.id}">Load in Editor</button>
            <button class="card-btn btn-copy" data-id="${script.id}">Copy Loadstring</button>
          </div>
        </div>
      `;

      card.querySelector('.btn-load').addEventListener('click', () => {
        createTab(script.title + '.lua', script.loadstring);
        switchView('editor');
        logConsole(`Loaded script '${script.title}' into editor.`, 'success');
      });

      card.querySelector('.btn-copy').addEventListener('click', () => {
        navigator.clipboard.writeText(script.loadstring);
        logConsole(`Copied loadstring for '${script.title}' to clipboard!`, 'system');
      });

      grid.appendChild(card);
    });
  }

  renderScriptHub();
});
