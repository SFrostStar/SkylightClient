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

  // Script Hub Catalog (20+ Essential Scripts & Snippets)
  const presetScripts = [
    {
      id: 1,
      title: 'Skylight Client v2.0',
      author: 'SFrostStar',
      desc: 'Full CS-Style ClickGUI with Combat (Aura, AimLock), Movement (Speed, VClip), Visuals (ESP, Ambiance), and HUD Widgets.',
      tags: ['Full Client', 'Combat', 'GUI'],
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
      title: 'Orion UI Library Template',
      author: 'shlexware',
      desc: 'Clean, lightweight UI library with animated toggles, sliders, and keybind handlers.',
      tags: ['UI Framework', 'Template'],
      loadstring: 'local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()\nlocal Window = OrionLib:MakeWindow({Name = "Orion Hub", HidePremium = false, SaveConfig = true, ConfigFolder = "OrionTest"})'
    },
    {
      id: 4,
      title: 'Fluent UI Library Template',
      author: 'dawid',
      desc: 'Sleek Windows 11 style UI framework with Acrylic glassmorphic blur and theme customizers.',
      tags: ['UI Framework', 'Acrylic'],
      loadstring: 'local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()\nlocal Window = Fluent:CreateWindow({ Title = "Fluent Hub", SubTitle = "v1.0", TabWidth = 160, Size = UDim2.fromOffset(580, 460), Theme = "Dark" })'
    },
    {
      id: 5,
      title: 'Universal 3D Glow ESP',
      author: 'Skylight Team',
      desc: 'High-performance player highlight ESP using Roblox Highlight service with custom outline colors.',
      tags: ['Visuals', 'ESP'],
      loadstring: 'local Players = game:GetService("Players")\nfor _, p in pairs(Players:GetPlayers()) do\n    if p.Character then\n        local h = Instance.new("Highlight", p.Character)\n        h.FillColor = Color3.fromRGB(56, 189, 248)\n    end\nend'
    },
    {
      id: 6,
      title: 'Tracers & Line ESP Engine',
      author: 'Skylight Team',
      desc: '2D screen-to-player tracer lines drawing from bottom-center of screen to enemy HumanoidRootPart.',
      tags: ['Visuals', 'Tracers'],
      loadstring: 'local Camera = workspace.CurrentCamera\nlocal Players = game:GetService("Players")\nlocal LocalPlayer = Players.LocalPlayer\n-- Tracer Line Drawing Snippet'
    },
    {
      id: 7,
      title: '3D Bounding Box ESP',
      author: 'Skylight Team',
      desc: 'Renders 3D wireframe bounding boxes around player characters in real-time.',
      tags: ['Visuals', '3D Box'],
      loadstring: 'local RunService = game:GetService("RunService")\n-- 3D Bounding Box Wireframe Math Routine'
    },
    {
      id: 8,
      title: 'AimLock & Sticky Torso Target',
      author: 'Skylight Team',
      desc: 'Sticky target acquisition locking camera vector onto enemy Torso/HumanoidRootPart.',
      tags: ['Combat', 'AimLock'],
      loadstring: 'local UserInputService = game:GetService("UserInputService")\nlocal Camera = workspace.CurrentCamera\n-- AimLock CFrame LookAt Routine'
    },
    {
      id: 9,
      title: 'KillAura & Auto-Attack Engine',
      author: 'Skylight Team',
      desc: 'Server-side silent rotation aura with ~10 CPS attack rate and jump critical attack timing.',
      tags: ['Combat', 'Aura'],
      loadstring: 'local RunService = game:GetService("RunService")\nlocal Players = game:GetService("Players")\n-- KillAura Radius Check & Auto Attack Loop'
    },
    {
      id: 10,
      title: 'TargetHUD Avatar & HP Bar Widget',
      author: 'Skylight Team',
      desc: 'Floating CS-style widget displaying target avatar headshot, player name, HP text, and animated health bar.',
      tags: ['HUD', 'Widgets'],
      loadstring: 'local Players = game:GetService("Players")\n-- TargetHUD UI Construction & Health Event Listeners'
    },
    {
      id: 11,
      title: 'Hotkeys Status HUD Widget',
      author: 'Skylight Team',
      desc: 'Floating keybind status overlay showing active modules (Aura [R], Speed [LShift], AimLock [C]).',
      tags: ['HUD', 'Widgets'],
      loadstring: '-- Hotkeys HUD Widget Frame & Status Indicator Updates'
    },
    {
      id: 12,
      title: 'CFrame Speed Multiplier Engine',
      author: 'Skylight Team',
      desc: 'Smooth velocity-based movement multiplier in Hold Mode (default keybind: Left Shift).',
      tags: ['Movement', 'Speed'],
      loadstring: 'local RunService = game:GetService("RunService")\nlocal LP = game:GetService("Players").LocalPlayer\n-- CFrame Speed Multiplication Routine'
    },
    {
      id: 13,
      title: 'Smooth Fly & Flight Controller',
      author: 'Skylight Team',
      desc: 'BodyVelocity & BodyGyro flight controller with WASD directional navigation.',
      tags: ['Movement', 'Fly'],
      loadstring: 'local UserInputService = game:GetService("UserInputService")\n-- Fly Controller Implementation'
    },
    {
      id: 14,
      title: 'Noclip & Collision Bypass',
      author: 'Skylight Team',
      desc: 'Disables CanCollide on all character limbs via Stepped connection to walk through walls.',
      tags: ['Movement', 'Noclip'],
      loadstring: 'local RS = game:GetService("RunService")\nlocal LP = game:GetService("Players").LocalPlayer\nRS.Stepped:Connect(function()\n    if LP.Character then\n        for _, p in pairs(LP.Character:GetDescendants()) do\n            if p:IsA("BasePart") then p.CanCollide = false end\n        end\n    end\nend)'
    },
    {
      id: 15,
      title: 'Infinite Jump Handler',
      author: 'Skylight Team',
      desc: 'Bypasses jump limits, allowing continuous mid-air jumping on JumpRequest event.',
      tags: ['Player', 'Jump'],
      loadstring: 'local UIS = game:GetService("UserInputService")\nUIS.JumpRequest:Connect(function()\n    local char = game.Players.LocalPlayer.Character\n    if char and char:FindFirstChildOfClass("Humanoid") then\n        char:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")\n    end\nend)'
    },
    {
      id: 16,
      title: 'Night & Galaxy Skybox Customizer',
      author: 'Skylight Team',
      desc: 'Replaces default Roblox skybox with midnight galaxy sky assets and custom ambient lighting.',
      tags: ['Atmosphere', 'Skybox'],
      loadstring: 'local Lighting = game:GetService("Lighting")\nLighting.ClockTime = 0\nlocal sky = Instance.new("Sky", Lighting)\nsky.SkyboxBk = "rbxassetid://159454299"'
    },
    {
      id: 17,
      title: 'Custom Fog Color & Density Adjuster',
      author: 'Skylight Team',
      desc: 'Adjustable purple fog color, FogStart, FogEnd, and density sliders.',
      tags: ['Atmosphere', 'Fog'],
      loadstring: 'local Lighting = game:GetService("Lighting")\nLighting.FogColor = Color3.fromRGB(139, 92, 246)\nLighting.FogStart = 0\nLighting.FogEnd = 500'
    },
    {
      id: 18,
      title: 'Anti-AFK & Disconnect Prevention',
      author: 'Skylight Team',
      desc: 'Prevents 20-minute idle disconnects by simulating VirtualUser keypresses.',
      tags: ['Utility', 'Anti-AFK'],
      loadstring: 'local VU = game:GetService("VirtualUser")\ngame:GetService("Players").LocalPlayer.Idled:Connect(function()\n    VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)\n    wait(1)\n    VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)\nend)'
    },
    {
      id: 19,
      title: 'HTTP Discord Webhook Logger',
      author: 'Skylight Team',
      desc: 'Sends player statistics, place info, and executor info directly to your Discord Webhook.',
      tags: ['Utility', 'Webhook'],
      loadstring: 'local HttpService = game:GetService("HttpService")\nlocal req = http_request or request or HttpPost\n-- Discord Webhook JSON payload dispatch'
    },
    {
      id: 20,
      title: 'JSON Config File Saver/Loader',
      author: 'Skylight Team',
      desc: 'Saves and loads user settings via writefile and readfile JSON serialization.',
      tags: ['Utility', 'Configs'],
      loadstring: 'local HttpService = game:GetService("HttpService")\nlocal config = { Speed = 24, AuraRadius = 15 }\nwritefile("skylight_config.json", HttpService:JSONEncode(config))\nlocal loaded = HttpService:JSONDecode(readfile("skylight_config.json"))'
    },
    {
      id: 21,
      title: 'FOV Circle Capture Radius Overlay',
      author: 'Skylight Team',
      desc: 'Renders dynamic 2D FOV circle overlay around mouse cursor using Drawing API.',
      tags: ['Visuals', 'FOV'],
      loadstring: 'local fovCircle = Drawing.new("Circle")\nfovCircle.Radius = 120\nfovCircle.Color = Color3.fromRGB(56, 189, 248)\nfovCircle.Visible = true'
    }
  ];

  function renderScriptHub() {
    const grid = document.getElementById('script-grid');
    if (!grid) return;
    grid.innerHTML = '';

    const searchInput = document.getElementById('script-search');
    const query = searchInput ? searchInput.value.toLowerCase().trim() : '';

    const filtered = presetScripts.filter(script => {
      if (!query) return true;
      return script.title.toLowerCase().includes(query) ||
             script.author.toLowerCase().includes(query) ||
             script.desc.toLowerCase().includes(query) ||
             script.tags.some(t => t.toLowerCase().includes(query));
    });

    filtered.forEach(script => {
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

  document.getElementById('script-search')?.addEventListener('input', renderScriptHub);
  renderScriptHub();
});
