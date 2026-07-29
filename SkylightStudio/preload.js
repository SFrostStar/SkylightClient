const { contextBridge, ipcRenderer } = require('electron');
const luaparse = require('luaparse');

contextBridge.exposeInMainWorld('electronAPI', {
  minimizeWindow: () => ipcRenderer.send('window-minimize'),
  maximizeWindow: () => ipcRenderer.send('window-maximize'),
  closeWindow: () => ipcRenderer.send('window-close'),
  openFile: () => ipcRenderer.invoke('dialog-open-file'),
  saveFile: (fileData) => ipcRenderer.invoke('save-file', fileData),
  
  // Real Lua/Luau Syntax Parser
  validateLua: (code) => {
    try {
      luaparse.parse(code, { locations: true, luaVersion: '5.1' });
      return { valid: true };
    } catch (err) {
      return {
        valid: false,
        message: err.message,
        line: err.line || 1,
        column: err.column || 0,
        index: err.index || 0
      };
    }
  }
});
