const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  minimizeWindow: () => ipcRenderer.send('window-minimize'),
  maximizeWindow: () => ipcRenderer.send('window-maximize'),
  closeWindow: () => ipcRenderer.send('window-close'),
  openFile: () => ipcRenderer.invoke('dialog-open-file'),
  saveFile: (fileData) => ipcRenderer.invoke('save-file', fileData)
});
