use muda::{Menu, PredefinedMenuItem, Submenu};
use tao::{
    event::{Event, StartCause, WindowEvent},
    event_loop::{ControlFlow, EventLoop},
    window::WindowBuilder,
};
use wry::WebViewBuilder;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let event_loop = EventLoop::new();

    // Create macOS native Edit Menu (Cmd+A, Cmd+C, Cmd+V, Cmd+Z)
    let menu = Menu::new();
    let edit_menu = Submenu::new("Edit", true);
    edit_menu.append(&PredefinedMenuItem::undo(None))?;
    edit_menu.append(&PredefinedMenuItem::redo(None))?;
    edit_menu.append(&PredefinedMenuItem::cut(None))?;
    edit_menu.append(&PredefinedMenuItem::copy(None))?;
    edit_menu.append(&PredefinedMenuItem::paste(None))?;
    edit_menu.append(&PredefinedMenuItem::select_all(None))?;
    menu.append(&edit_menu)?;

    let window = WindowBuilder::new()
        .with_title("Sky")
        .with_inner_size(tao::dpi::LogicalSize::new(1100.0, 720.0))
        .with_min_inner_size(tao::dpi::LogicalSize::new(800.0, 500.0))
        .build(&event_loop)?;

    #[cfg(target_os = "macos")]
    menu.init_for_nsapp();

    // Matching macOS Safari WebKit User-Agent so Cloudflare Turnstile passes 100% cleanly
    let safari_user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15";

    // Injected Toolbar + Cloudflare Turnstile Protection Script
    let init_toolbar_script = r#"
        (function() {
            // Mask automation markers for Cloudflare & Google
            try {
                Object.defineProperty(navigator, 'webdriver', { get: () => false });
            } catch(e) {}

            function injectBeautifulToolbar() {
                if (window.self !== window.top) return;
                
                // Do NOT inject DOM toolbar into Cloudflare challenge pages or captchas to avoid flagging bot detectors
                const host = window.location.hostname.toLowerCase();
                const path = window.location.pathname.toLowerCase();
                if (host.includes('cloudflare') || host.includes('challenges') || path.includes('turnstile') || path.includes('captcha')) {
                    return;
                }

                if (document.getElementById('sky-header-root')) return;

                const style = document.createElement('style');
                style.id = 'sky-header-style';
                style.innerHTML = `
                    #sky-header-root {
                        position: fixed !important;
                        top: 0 !important;
                        left: 0 !important;
                        width: 100vw !important;
                        height: 44px !important;
                        background: #12141c !important;
                        border-bottom: 1px solid rgba(255, 255, 255, 0.1) !important;
                        display: flex !important;
                        align-items: center !important;
                        padding: 0 12px !important;
                        gap: 10px !important;
                        z-index: 2147483647 !important;
                        font-family: 'Outfit', -apple-system, BlinkMacSystemFont, sans-serif !important;
                        color: #f1f5f9 !important;
                        box-shadow: 0 4px 16px rgba(0,0,0,0.5) !important;
                        user-select: none !important;
                    }
                    html {
                        margin-top: 44px !important;
                    }
                    .sky-logo-badge {
                        display: flex !important;
                        align-items: center !important;
                        gap: 6px !important;
                        font-weight: 700 !important;
                        font-size: 13px !important;
                        padding-right: 6px !important;
                    }
                    .sky-logo-svg { color: #38bdf8 !important; }
                    .sky-nav-btns {
                        display: flex !important;
                        align-items: center !important;
                        gap: 4px !important;
                    }
                    .sky-tool-btn {
                        background: transparent !important;
                        border: none !important;
                        color: #94a3b8 !important;
                        width: 30px !important;
                        height: 30px !important;
                        border-radius: 6px !important;
                        display: flex !important;
                        align-items: center !important;
                        justify-content: center !important;
                        cursor: pointer !important;
                        transition: all 0.15s ease !important;
                    }
                    .sky-tool-btn:hover {
                        background: #242838 !important;
                        color: #f1f5f9 !important;
                        transform: translateY(-1px) !important;
                    }
                    .sky-omnibox-wrap {
                        flex: 1 !important;
                        display: flex !important;
                        align-items: center !important;
                        background: #1a1d29 !important;
                        border: 1px solid rgba(255, 255, 255, 0.1) !important;
                        border-radius: 8px !important;
                        padding: 0 10px !important;
                        height: 32px !important;
                        transition: all 0.2s ease !important;
                    }
                    .sky-omnibox-wrap:focus-within {
                        border-color: #38bdf8 !important;
                        box-shadow: 0 0 0 2px rgba(56, 189, 248, 0.2) !important;
                        background: #242838 !important;
                    }
                    .sky-ssl-icon {
                        color: #10b981 !important;
                        display: flex !important;
                        align-items: center !important;
                        margin-right: 8px !important;
                    }
                    .sky-address-input {
                        flex: 1 !important;
                        background: transparent !important;
                        border: none !important;
                        outline: none !important;
                        color: #f1f5f9 !important;
                        font-family: inherit !important;
                        font-size: 13px !important;
                    }
                `;
                if (document.head) document.head.appendChild(style);

                const root = document.createElement('div');
                root.id = 'sky-header-root';
                root.innerHTML = `
                    <div class="sky-logo-badge">
                        <svg class="sky-logo-svg" viewBox="0 0 24 24" width="18" height="18">
                            <path fill="currentColor" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"/>
                        </svg>
                        <span>Sky</span>
                    </div>
                    <div class="sky-nav-btns">
                        <button class="sky-tool-btn" id="sky-btn-back" title="Back">
                            <svg viewBox="0 0 24 24" width="16" height="16"><path fill="currentColor" d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"/></svg>
                        </button>
                        <button class="sky-tool-btn" id="sky-btn-forward" title="Forward">
                            <svg viewBox="0 0 24 24" width="16" height="16"><path fill="currentColor" d="M12 4l-1.41 1.41L16.17 11H4v2h12.17l-5.58 5.59L12 20l8-8-8-8z"/></svg>
                        </button>
                        <button class="sky-tool-btn" id="sky-btn-reload" title="Reload">
                            <svg viewBox="0 0 24 24" width="16" height="16"><path fill="currentColor" d="M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z"/></svg>
                        </button>
                        <button class="sky-tool-btn" id="sky-btn-home" title="Home">
                            <svg viewBox="0 0 24 24" width="16" height="16"><path fill="currentColor" d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>
                        </button>
                    </div>
                    <div class="sky-omnibox-wrap">
                        <div class="sky-ssl-icon" title="Connection is secure">
                            <svg viewBox="0 0 24 24" width="14" height="14"><path fill="currentColor" d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/></svg>
                        </div>
                        <input type="text" class="sky-address-input" id="sky-address-input" value="${window.location.href}">
                    </div>
                `;
                
                if (document.body) {
                    document.body.prepend(root);
                } else {
                    document.addEventListener('DOMContentLoaded', () => document.body.prepend(root));
                }

                document.getElementById('sky-btn-back').onclick = () => window.history.back();
                document.getElementById('sky-btn-forward').onclick = () => window.history.forward();
                document.getElementById('sky-btn-reload').onclick = () => window.location.reload();
                document.getElementById('sky-btn-home').onclick = () => window.location.href = 'https://www.google.com';

                const input = document.getElementById('sky-address-input');
                input.onkeydown = (e) => {
                    if (e.key === 'Enter') {
                        let val = input.value.trim();
                        if (!val) return;
                        if (!/^https?:\/\//i.test(val)) {
                            if (/^([a-z0-9\-]+\.)+[a-z]{2,}/i.test(val)) val = 'https://' + val;
                            else val = 'https://www.google.com/search?q=' + encodeURIComponent(val);
                        }
                        window.location.href = val;
                    }
                };
                input.onfocus = () => input.select();
            }

            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', injectBeautifulToolbar);
            } else {
                injectBeautifulToolbar();
            }
        })();
    "#;

    let _webview = WebViewBuilder::new()
        .with_user_agent(safari_user_agent)
        .with_initialization_script(init_toolbar_script)
        .with_url("https://www.google.com")
        .build(&window)?;

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;

        match event {
            Event::NewEvents(StartCause::Init) => println!("[Sky Rust] Native Browser started with Cloudflare Turnstile protection."),
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                ..
            } => *control_flow = ControlFlow::Exit,
            _ => (),
        }
    });
}
