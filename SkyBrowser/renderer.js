// Sky Browser Multi-Tab Manager
document.addEventListener('DOMContentLoaded', () => {
  let tabs = [];
  let activeTabId = null;
  let tabCounter = 1;

  const tabStrip = document.getElementById('tab-strip');
  const btnNewTab = document.getElementById('btn-new-tab');
  const viewportContainer = document.getElementById('viewport-container');
  const addressBar = document.getElementById('address-bar');
  const progressBar = document.getElementById('progress-bar');

  const btnBack = document.getElementById('btn-back');
  const btnForward = document.getElementById('btn-forward');
  const btnReload = document.getElementById('btn-reload');
  const btnHome = document.getElementById('btn-home');

  const statusMessage = document.getElementById('status-message');
  const pageTitle = document.getElementById('page-title');

  function formatUrlOrQuery(input) {
    const query = input.trim();
    if (!query) return 'https://www.google.com';

    if (/^https?:\/\//i.test(query)) return query;

    const domainRegex = /^([a-z0-9\-]+\.)+[a-z]{2,}(:\d+)?(\/.*)?$/i;
    if (domainRegex.test(query) || /^localhost(:\d+)?(\/.*)?$/i.test(query)) {
      return 'https://' + query;
    }

    return 'https://www.google.com/search?q=' + encodeURIComponent(query);
  }

  function createTab(url = 'https://www.google.com') {
    const tabId = 'tab-' + Date.now() + '-' + Math.random().toString(36).substr(2, 4);
    const initialUrl = formatUrlOrQuery(url);

    // Create Iframe Viewport
    const iframe = document.createElement('iframe');
    iframe.id = 'frame-' + tabId;
    iframe.className = 'tab-frame';
    iframe.src = initialUrl;
    iframe.setAttribute('allow', 'fullscreen; camera; microphone');
    viewportContainer.appendChild(iframe);

    const tab = {
      id: tabId,
      title: 'New Tab',
      url: initialUrl,
      iframe: iframe
    };

    tabs.push(tab);

    // Track loading progress
    iframe.addEventListener('load', () => {
      try {
        const frameUrl = iframe.contentWindow.location.href;
        if (frameUrl && frameUrl !== 'about:blank') {
          tab.url = frameUrl;
          const frameTitle = iframe.contentDocument ? iframe.contentDocument.title : 'Google';
          tab.title = frameTitle || 'Web Page';
        }
      } catch (e) {
        // Cross-origin fallback title
        tab.title = tab.url.replace(/^https?:\/\//, '').split('/')[0] || 'Google';
      }

      renderTabs();
      if (activeTabId === tabId) {
        syncTabUI(tab);
      }
    });

    switchTab(tabId);
  }

  function switchTab(tabId) {
    activeTabId = tabId;
    const tab = tabs.find(t => t.id === tabId);
    if (!tab) return;

    tabs.forEach(t => {
      t.iframe.classList.remove('active');
    });

    tab.iframe.classList.add('active');
    syncTabUI(tab);
    renderTabs();
  }

  function syncTabUI(tab) {
    if (addressBar && document.activeElement !== addressBar) {
      addressBar.value = tab.url;
    }
    if (pageTitle) pageTitle.innerText = tab.title;
    if (statusMessage) statusMessage.innerText = 'Sky Browser Active';
  }

  function closeTab(tabId, e) {
    if (e) e.stopPropagation();

    const tabIndex = tabs.findIndex(t => t.id === tabId);
    if (tabIndex === -1) return;

    const tabToRemove = tabs[tabIndex];
    tabToRemove.iframe.remove();
    tabs.splice(tabIndex, 1);

    if (tabs.length === 0) {
      createTab('https://www.google.com');
    } else {
      const nextTab = tabs[Math.max(0, tabIndex - 1)];
      switchTab(nextTab.id);
    }
  }

  function renderTabs() {
    tabStrip.innerHTML = '';

    tabs.forEach(tab => {
      const tabEl = document.createElement('div');
      tabEl.className = `tab-item ${tab.id === activeTabId ? 'active' : ''}`;
      tabEl.innerHTML = `
        <span class="tab-title">${tab.title || 'Tab'}</span>
        <span class="tab-close" data-id="${tab.id}">✕</span>
      `;

      tabEl.addEventListener('click', () => switchTab(tab.id));
      tabEl.querySelector('.tab-close').addEventListener('click', (e) => closeTab(tab.id, e));
      tabStrip.appendChild(tabEl);
    });
  }

  // Address Bar Submission
  addressBar?.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      const targetUrl = formatUrlOrQuery(addressBar.value);
      const activeTab = tabs.find(t => t.id === activeTabId);
      if (activeTab) {
        activeTab.url = targetUrl;
        activeTab.iframe.src = targetUrl;
      }
      addressBar.blur();
    }
  });

  addressBar?.addEventListener('focus', () => addressBar.select());

  // Toolbar Actions
  btnNewTab?.addEventListener('click', () => createTab());

  btnBack?.addEventListener('click', () => {
    const activeTab = tabs.find(t => t.id === activeTabId);
    if (activeTab) {
      try { activeTab.iframe.contentWindow.history.back(); } catch (e) {}
    }
  });

  btnForward?.addEventListener('click', () => {
    const activeTab = tabs.find(t => t.id === activeTabId);
    if (activeTab) {
      try { activeTab.iframe.contentWindow.history.forward(); } catch (e) {}
    }
  });

  btnReload?.addEventListener('click', () => {
    const activeTab = tabs.find(t => t.id === activeTabId);
    if (activeTab) {
      activeTab.iframe.src = activeTab.url;
    }
  });

  btnHome?.addEventListener('click', () => {
    const activeTab = tabs.find(t => t.id === activeTabId);
    if (activeTab) {
      activeTab.url = 'https://www.google.com';
      activeTab.iframe.src = 'https://www.google.com';
    }
  });

  // Initialize First Tab
  createTab('https://www.google.com');
});
