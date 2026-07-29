const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const path = require('path');
const fs = require('fs');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1240,
    height: 820,
    minWidth: 920,
    minHeight: 620,
    frame: false,
    titleBarStyle: 'hidden',
    backgroundColor: '#08090e',
    icon: path.join(__dirname, 'icon.svg'),
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: false
    }
  });

  mainWindow.loadFile('index.html');

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

// Window controls IPC
ipcMain.on('window-minimize', () => {
  if (mainWindow) mainWindow.minimize();
});

ipcMain.on('window-maximize', () => {
  if (mainWindow) {
    if (mainWindow.isMaximized()) {
      mainWindow.unmaximize();
    } else {
      mainWindow.maximize();
    }
  }
});

ipcMain.on('window-close', () => {
  if (mainWindow) mainWindow.close();
});

// File System IPC
ipcMain.handle('dialog-open-file', async () => {
  const { canceled, filePaths } = await dialog.showOpenDialog(mainWindow, {
    properties: ['openFile'],
    filters: [
      { name: 'Lua Scripts', extensions: ['lua', 'txt'] },
      { name: 'All Files', extensions: ['*'] }
    ]
  });

  if (canceled || filePaths.length === 0) return null;

  try {
    const filePath = filePaths[0];
    const content = fs.readFileSync(filePath, 'utf-8');
    return { filePath, filename: path.basename(filePath), content };
  } catch (err) {
    return { error: err.message };
  }
});

ipcMain.handle('save-file', async (event, { filePath, content }) => {
  try {
    let targetPath = filePath;
    if (!targetPath) {
      const { canceled, filePath: savedPath } = await dialog.showSaveDialog(mainWindow, {
        title: 'Save Lua Script',
        defaultPath: 'script.lua',
        filters: [{ name: 'Lua Scripts', extensions: ['lua'] }]
      });
      if (canceled || !savedPath) return null;
      targetPath = savedPath;
    }

    fs.writeFileSync(targetPath, content, 'utf-8');
    return { filePath: targetPath, filename: path.basename(targetPath) };
  } catch (err) {
    return { error: err.message };
  }
});
