// Skylight Studio Renderer Logic
document.addEventListener('DOMContentLoaded', () => {
  // Window Controls
  document.getElementById('btn-minimize')?.addEventListener('click', () => window.electronAPI.minimizeWindow());
  document.getElementById('btn-maximize')?.addEventListener('click', () => window.electronAPI.maximizeWindow());
  document.getElementById('btn-close')?.addEventListener('click', () => window.electronAPI.closeWindow());

  // View Navigation
  const navEditor = document.getElementById('nav-editor');
  const navScriptHub = document.getElementById('nav-scripthub');
  const viewEditor = document.getElementById('view-editor');
  const viewScriptHub = document.getElementById('view-scripthub');

  function switchView(view) {
    if (view === 'editor') {
      navEditor.classList.add('active');
      navScriptHub.classList.remove('active');
      viewEditor.classList.remove('hidden');
      viewScriptHub.classList.add('hidden');
    } else if (view === 'scripthub') {
      navScriptHub.classList.add('active');
      navEditor.classList.remove('active');
      viewScriptHub.classList.remove('hidden');
      viewEditor.classList.add('hidden');
    }
  }

  navEditor?.addEventListener('click', () => switchView('editor'));
  navScriptHub?.addEventListener('click', () => switchView('scripthub'));

  // Console Log Manager
  const consoleLogs = document.getElementById('console-logs');
  const btnClearConsole = document.getElementById('btn-clear-console');

  function logConsole(message, type = 'system') {
    if (!consoleLogs) return;
    const entry = document.createElement('div');
    entry.className = `log-entry ${type}`;
    const timestamp = new Date().toLocaleTimeString();
    entry.innerText = `[${timestamp}] ${message}`;
    consoleLogs.appendChild(entry);
    consoleLogs.scrollTop = consoleLogs.scrollHeight;
  }

  btnClearConsole?.addEventListener('click', () => {
    if (consoleLogs) consoleLogs.innerHTML = '';
    logConsole('Console cleared.', 'system');
  });

  // Tab Manager State
  let tabs = [];
  let activeTabId = null;
  let tabCounter = 1;
  let monacoEditor = null;

  // Initialize Monaco Editor
  require.config({ paths: { vs: 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.45.0/min/vs' } });

  require(['vs/editor/editor.main'], () => {
    // Custom Dark Purple Monaco Theme
    monaco.editor.defineTheme('skylight-purple', {
      base: 'vs-dark',
      inherit: true,
      rules: [
        { token: 'keyword', foreground: 'c084fc', fontStyle: 'bold' },
        { token: 'string', foreground: '86efac' },
        { token: 'number', foreground: 'fde047' },
        { token: 'comment', foreground: '6b7280', fontStyle: 'italic' },
        { token: 'identifier', foreground: 'f3f4f6' },
        { token: 'delimiter', foreground: 'a855f7' }
      ],
      colors: {
        'editor.background': '#0b0b12',
        'editor.foreground': '#f3f4f6',
        'editor.lineHighlightBackground': '#1b1b2e',
        'editorCursor.foreground': '#c084fc',
        'editorWhitespace.foreground': '#262640',
        'editorIndentGuide.background': '#1b1b2e',
        'editorIndentGuide.activeBackground': '#8a2be2'
      }
    });

    monacoEditor = monaco.editor.create(document.getElementById('monaco-container'), {
      value: '-- Skylight Studio v1.0\n-- Write or load your Roblox Luau scripts here!\n\nprint("Hello from Skylight Studio!")\n',
      language: 'lua',
      theme: 'skylight-purple',
      automaticLayout: true,
      fontFamily: 'JetBrains Mono',
      fontSize: 13,
      minimap: { enabled: true },
      lineNumbers: 'on',
      scrollBeyondLastLine: false,
      tabSize: 4
    });

    // Handle Editor Content Change
    monacoEditor.onDidChangeModelContent(() => {
      if (activeTabId) {
        const tab = tabs.find(t => t.id === activeTabId);
        if (tab) {
          tab.content = monacoEditor.getValue();
          tab.isDirty = true;
          renderTabs();
        }
      }
    });

    // Create Initial Tab
    createTab('SkylightClient.lua', getInitialScript());
    logConsole('Monaco Editor loaded successfully.', 'success');
  });

  function getInitialScript() {
    return `--[[
    Skylight Client v2.0
    Created by SFrostStar
--]]

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService")
}

local LocalPlayer = Services.Players.LocalPlayer

print("[Skylight Client v2.0] Loaded successfully for " .. LocalPlayer.Name)
`;
  }

  // Tab Operations
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

  // Actions: New, Open, Save
  document.getElementById('btn-new-tab')?.addEventListener('click', () => createTab());

  document.getElementById('btn-open-file')?.addEventListener('click', async () => {
    const fileResult = await window.electronAPI.openFile();
    if (fileResult && fileResult.content !== undefined) {
      const activeTab = tabs.find(t => t.id === activeTabId);
      if (activeTab && !activeTab.isDirty && activeTab.content === '') {
        activeTab.filename = fileResult.filename;
        activeTab.content = fileResult.content;
        activeTab.filePath = fileResult.filePath;
        activeTab.isDirty = false;
        setActiveTab(activeTab.id);
      } else {
        const id = 'tab-' + Date.now();
        tabs.push({ id, filename: fileResult.filename, content: fileResult.content, filePath: fileResult.filePath, isDirty: false });
        setActiveTab(id);
      }
      logConsole(`Loaded file: ${fileResult.filename}`, 'success');
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

  // Execute Simulator Button
  document.getElementById('btn-execute-sim')?.addEventListener('click', () => {
    const code = monacoEditor ? monacoEditor.getValue() : '';
    logConsole('Executing Luau Script in Simulator Environment...', 'system');

    // Perform basic Luau Syntax Check simulation
    if (code.includes('error(') || code.includes('function()') && !code.includes('end')) {
      logConsole('Syntax Validation Warning: Unclosed block detected or explicit error call.', 'warn');
    } else {
      const lines = code.split('\n').length;
      logConsole(`[Simulated Execution] Successfully parsed and executed ${lines} lines of code.`, 'success');
    }
  });

  // Script Hub Data & Rendering
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
      desc: 'Clean, modern UI Library template with window creation, tabs, buttons, sliders, and keybind toggles.',
      tags: ['UI Library', 'Template'],
      loadstring: 'local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()\nlocal Window = Rayfield:CreateWindow({ Name = "Rayfield Hub", LoadingTitle = "Loading...", LoadingSubtitle = "by Rayfield" })'
    },
    {
      id: 3,
      title: 'Universal 3D Glow ESP',
      author: 'Skylight Team',
      desc: 'High-performance player highlight ESP using Roblox Highlight service with customizable fill & outline colors.',
      tags: ['Visuals', 'ESP'],
      loadstring: 'local Players = game:GetService("Players")\nfor _, p in pairs(Players:GetPlayers()) do\n    if p.Character then\n        local h = Instance.new("Highlight", p.Character)\n        h.FillColor = Color3.fromRGB(147, 51, 234)\n    end\nend'
    },
    {
      id: 4,
      title: 'CFrame Speed & Flight Engine',
      author: 'Skylight Team',
      desc: 'Smooth velocity-based movement framework with customizable hold keys and speed multipliers.',
      tags: ['Movement', 'Utility'],
      loadstring: 'local RS = game:GetService("RunService")\nlocal LP = game:GetService("Players").LocalPlayer\nRS.RenderStepped:Connect(function()\n    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then\n        -- Velocity calculation\n    end\nend)'
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
          <div style="font-size: 11px; color: var(--text-dark); margin: 2px 0 8px 0;">by ${script.author}</div>
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
        logConsole(`Copied loadstring for '${script.title}' to clipboard!`, 'info');
      });

      grid.appendChild(card);
    });
  }

  renderScriptHub();
});
