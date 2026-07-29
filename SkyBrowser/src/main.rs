use muda::{Menu, PredefinedMenuItem, Submenu};
use tao::{
    event::{Event, StartCause, WindowEvent},
    event_loop::{ControlFlow, EventLoop},
    window::WindowBuilder,
};
use wry::{http::Response, WebViewBuilder};

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

    let _webview = WebViewBuilder::new()
        .with_user_agent(user_agent)
        .with_custom_protocol("sky".into(), move |_id, _request| {
            let index_bytes = include_bytes!("../index.html");
            Response::builder()
                .header("Content-Type", "text/html; charset=utf-8")
                .body(index_bytes.to_vec().into())
                .unwrap()
        })
        .with_url("sky://app/index.html")
        .build(&window)?;

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;

        match event {
            Event::NewEvents(StartCause::Init) => println!("[Sky Rust] Native Browser started with sky:// custom protocol UI."),
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                ..
            } => *control_flow = ControlFlow::Exit,
            _ => (),
        }
    });
}
