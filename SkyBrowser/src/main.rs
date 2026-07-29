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

    let user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36";

    // Injected Top Navigation Toolbar (⚡ Sky, ⬅️ Back, ➡️ Forward, 🔄 Reload, 🏠 Home, 🔍 Omnibox)
    let init_toolbar_script = r#"
        (function() {
            function injectSkyToolbar() {
                if (window.self !== window.top) return;
                if (document.getElementById('sky-native-bar')) return;

                const style = document.createElement('style');
                style.id = 'sky-bar-style';
                style.innerHTML = `
                    #sky-native-bar {
                        position: fixed !important;
                        top: 0 !important;
                        left: 0 !important;
                        width: 100vw !important;
                        height: 38px !important;
                        background: #0f111a !important;
                        border-bottom: 1px solid rgba(255, 255, 255, 0.12) !important;
                        display: flex !important;
                        align-items: center !important;
                        padding: 0 10px !important;
                        gap: 8px !important;
                        z-index: 2147483647 !important;
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif !important;
                        color: #f1f5f9 !important;
                        box-shadow: 0 2px 10px rgba(0,0,0,0.5) !important;
                        user-select: none !important;
                    }
                    html {
                        margin-top: 38px !important;
                    }
                    .sky-btn {
                        background: rgba(255,255,255,0.06) !important;
                        border: 1px solid rgba(255,255,255,0.12) !important;
                        color: #94a3b8 !important;
                        width: 26px !important;
                        height: 26px !important;
                        border-radius: 6px !important;
                        display: flex !important;
                        align-items: center !important;
                        justify-content: center !important;
                        cursor: pointer !important;
                        font-size: 12px !important;
                        transition: all 0.15s ease !important;
                    }
                    .sky-btn:hover {
                        background: #38bdf8 !important;
                        color: #0c0d14 !important;
                    }
                    .sky-input {
                        flex: 1 !important;
                        background: #181b28 !important;
                        border: 1px solid rgba(255,255,255,0.12) !important;
                        border-radius: 6px !important;
                        color: #f1f5f9 !important;
                        padding: 0 10px !important;
                        height: 26px !important;
                        font-size: 12px !important;
                        outline: none !important;
                    }
                    .sky-input:focus {
                        border-color: #38bdf8 !important;
                        box-shadow: 0 0 0 2px rgba(56, 189, 248, 0.25) !important;
                    }
                    .sky-logo {
                        font-weight: 700 !important;
                        font-size: 12px !important;
                        color: #38bdf8 !important;
                        margin-right: 4px !important;
                    }
                `;
                if (document.head) document.head.appendChild(style);

                const bar = document.createElement('div');
                bar.id = 'sky-native-bar';
                bar.innerHTML = `
                    <span class="sky-logo">⚡ Sky</span>
                    <button class="sky-btn" id="sky-back" title="Back">⬅️</button>
                    <button class="sky-btn" id="sky-forward" title="Forward">➡️</button>
                    <button class="sky-btn" id="sky-reload" title="Reload">🔄</button>
                    <button class="sky-btn" id="sky-home" title="Home">🏠</button>
                    <input type="text" class="sky-input" id="sky-url-input" value="${window.location.href}">
                `;
                
                if (document.body) {
                    document.body.prepend(bar);
                } else {
                    document.addEventListener('DOMContentLoaded', () => document.body.prepend(bar));
                }

                document.getElementById('sky-back').onclick = () => window.history.back();
                document.getElementById('sky-forward').onclick = () => window.history.forward();
                document.getElementById('sky-reload').onclick = () => window.location.reload();
                document.getElementById('sky-home').onclick = () => window.location.href = 'https://www.google.com';

                const input = document.getElementById('sky-url-input');
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
                document.addEventListener('DOMContentLoaded', injectSkyToolbar);
            } else {
                injectSkyToolbar();
            }
        })();
    "#;

    let _webview = WebViewBuilder::new()
        .with_user_agent(user_agent)
        .with_initialization_script(init_toolbar_script)
        .with_url("https://www.google.com")
        .build(&window)?;

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;

        match event {
            Event::NewEvents(StartCause::Init) => println!("[Sky Rust] Native Browser active with injected toolbar."),
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                ..
            } => *control_flow = ControlFlow::Exit,
            _ => (),
        }
    });
}
