// Sky Browser Renderer Logic
document.addEventListener('DOMContentLoaded', () => {
  // Window Controls
  document.getElementById('btn-minimize')?.addEventListener('click', () => window.skyAPI?.minimizeWindow());
  document.getElementById('btn-maximize')?.addEventListener('click', () => window.skyAPI?.maximizeWindow());
  document.getElementById('btn-close')?.addEventListener('click', () => window.skyAPI?.closeWindow());

  const webview = document.getElementById('sky-webview');
  const addressBar = document.getElementById('address-bar');
  const enginePicker = document.getElementById('engine-picker');
  const sslBadge = document.getElementById('ssl-badge');
  const progressBar = document.getElementById('progress-bar');
  const statusMessage = document.getElementById('status-message');
  const pageTitle = document.getElementById('page-title');

  const btnBack = document.getElementById('btn-back');
  const btnForward = document.getElementById('btn-forward');
  const btnReload = document.getElementById('btn-reload');
  const btnHome = document.getElementById('btn-home');

  // Search Engine Template URLs
  const searchEngines = {
    google: 'https://www.google.com/search?q=',
    yandex: 'https://yandex.ru/search/?text=',
    duckduckgo: 'https://duckduckgo.com/?q=',
    bing: 'https://www.bing.com/search?q=',
    ecosia: 'https://www.ecosia.org/search?q='
  };

  // URL / Search Query Parser
  function formatUrlOrQuery(input) {
    const query = input.trim();
    if (!query) return 'https://www.google.com';

    // Already a valid URL with protocol
    if (/^https?:\/\//i.test(query)) {
      return query;
    }

    // Looks like a domain (e.g., github.com, roblox.com/home, localhost:3000)
    const domainRegex = /^([a-z0-9\-]+\.)+[a-z]{2,}(:\d+)?(\/.*)?$/i;
    if (domainRegex.test(query) || /^localhost(:\d+)?(\/.*)?$/i.test(query)) {
      return 'https://' + query;
    }

    // Otherwise, perform search with selected search engine
    const selectedEngine = enginePicker?.value || 'google';
    const baseUrl = searchEngines[selectedEngine] || searchEngines.google;
    return baseUrl + encodeURIComponent(query);
  }

  function navigateTo(url) {
    if (!webview) return;
    try {
      webview.src = url;
    } catch (e) {
      console.error('Navigation error:', e);
    }
  }

  // Address Bar Submission (Press Enter)
  addressBar?.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      const targetUrl = formatUrlOrQuery(addressBar.value);
      navigateTo(targetUrl);
      addressBar.blur();
    }
  });

  // Select all text when address bar is focused
  addressBar?.addEventListener('focus', () => addressBar.select());

  // Navigation Button Handlers
  btnBack?.addEventListener('click', () => {
    if (webview && webview.canGoBack()) webview.goBack();
  });

  btnForward?.addEventListener('click', () => {
    if (webview && webview.canGoForward()) webview.goForward();
  });

  btnReload?.addEventListener('click', () => {
    if (webview) webview.reload();
  });

  btnHome?.addEventListener('click', () => {
    navigateTo('https://www.google.com');
  });

  // Webview Event Listeners
  if (webview) {
    webview.addEventListener('did-start-loading', () => {
      if (progressBar) {
        progressBar.style.width = '30%';
        progressBar.classList.add('loading');
      }
      if (statusMessage) statusMessage.innerText = 'Loading...';
    });

    webview.addEventListener('did-finish-load', () => {
      if (progressBar) {
        progressBar.style.width = '100%';
        setTimeout(() => {
          progressBar.classList.remove('loading');
          progressBar.style.width = '0%';
        }, 200);
      }

      const currentUrl = webview.getURL();
      if (addressBar && document.activeElement !== addressBar) {
        addressBar.value = currentUrl;
      }

      // Update SSL Badge Indicator
      if (sslBadge) {
        if (currentUrl.startsWith('https://')) {
          sslBadge.className = 'ssl-indicator';
          sslBadge.title = 'Connection is secure (HTTPS)';
        } else {
          sslBadge.className = 'ssl-indicator insecure';
          sslBadge.title = 'Not secure (HTTP)';
        }
      }

      // Update Nav Buttons Enabled state
      if (btnBack) btnBack.disabled = !webview.canGoBack();
      if (btnForward) btnForward.disabled = !webview.canGoForward();

      if (statusMessage) statusMessage.innerText = 'Sky Browser Ready';
    });

    webview.addEventListener('page-title-updated', (e) => {
      if (pageTitle) pageTitle.innerText = e.title;
    });

    webview.addEventListener('did-fail-load', (e) => {
      if (e.errorCode !== -3) { // Ignore aborted loads
        if (statusMessage) statusMessage.innerText = `Failed to load: ${e.errorDescription}`;
      }
    });
  }
});
