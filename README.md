# ⚡ Skylight Client & Skylight Studio v2.0

![Lua](https://img.shields.io/badge/Language-Lua%2FLuau-blue.svg)
![Roblox](https://img.shields.io/badge/Platform-Roblox-00A2FF.svg)
![Electron](https://img.shields.io/badge/Studio-Electron-47848F.svg)
![Version](https://img.shields.io/badge/Version-v2.0_Pro-purple.svg)

> **Editor for testing if script have any problems or not, featuring a high-performance CS-Style ClickGUI for Roblox and a desktop Luau Studio.**

---

## 📌 Repository Overview

This repository contains two primary components:

1. **`SkylightScript/`**: Modern CS-Style ClickGUI Script for Roblox executors featuring Combat modules, Movement enhancements, Atmosphere customizers, and real-time HUD widgets.
2. **`SkylightStudio/`**: Desktop Editor & Script Hub for testing if Roblox Lua/Luau scripts have any syntax errors, problems, or formatting issues before running them.

---

## 🚀 Quick Execution (Roblox Executor Loadstring)

Copy and paste the following line into your Roblox executor:

```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/SFrostStar/SkylightClient/main/SkylightScript/main.lua'))()
```

---

## 💻 Skylight Studio (Desktop Luau Editor & Testbench)

**Editor for testing if script have any problems or not.**

### ✨ Studio Features
- **Real-Time Luau Syntax Validation**: Live `luaparse` AST syntax checking. Underlines syntax errors with red markers in Monaco Editor and outputs exact error lines to the diagnostics console.
- **Monaco Editor Engine**: VS-Code editor core with custom `Deep Obsidian & Electric Sapphire` theme, syntax highlighting, and minimap.
- **20+ Preset Script Hub**: Built-in catalog of 20+ preset Roblox scripts (Rayfield, Orion, Fluent, ESP, KillAura, AimLock, Speed, Fly, Webhook loggers) with 1-click loading & loadstring copying.
- **Multi-Tab Management**: Open, edit, create, and save multiple `.lua` files.
- **Diagnostics Console**: Real-time log stream with timestamps, system warnings, syntax errors, and clear controls.

### 🏃 Quick Start (Run Studio Locally)

```bash
cd SkylightStudio
npm install
npm start
```

---

## ✨ Skylight Client v2.0 Features

### ⚔️ Combat
- **Aura (KillAura)**: Silent server-side rotation with ~10 CPS attack rate and jump critical timing.
- **AimLock**: Sticky target acquisition locked to target torso (Default bind: `C`).
- **Team Check**: Ignores teammates in team-based games.

### ⚡ Movement
- **Speed**: CFrame movement multiplier in Hold Mode (Default bind: `LShift`).
- **VClip UP & DOWN**: Vertical teleportation with continuous WASD momentum.

### 👁️ Visuals & Atmosphere
- **ESP (3D Glow)**: Always-on-top player highlight.
- **Tracers**: Clean screen-to-player tracer lines.
- **3D Box**: 3D bounding box surrounding players.
- **AimLock FOV Circle**: Adjustable capture radius circle overlay.
- **Purple Ambiance**: Custom screen tint and atmospheric lighting.
- **Night / Galaxy Sky**: Custom starry skybox with midnight atmosphere.

### 👤 Player & HUD Widgets
- **Infinite Jump**: Jump freely in mid-air.
- **Hotkeys HUD Widget**: Floating CS-style widget displaying active keybinds.
- **TargetHUD Widget**: Real-time avatar headshot, player name, HP text, and animated health bar.

---

## 👨‍💻 Credits & Contact

- **Lead Developer**: SFrostStar (A1wertykss)
- **Discord Contact**: `xsynapse`
- **GitHub Repository**: [SFrostStar/SkylightClient](https://github.com/SFrostStar/SkylightClient)
