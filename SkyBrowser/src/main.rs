use tao::{
    event::{Event, StartCause, WindowEvent},
    event_loop::{ControlFlow, EventLoop},
    menu::{MenuBar, MenuItem},
    window::WindowBuilder,
};
use wry::WebViewBuilder;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let event_loop = EventLoop::new();

    // Create macOS native Edit MenuBar to support Cmd+A, Cmd+C, Cmd+V without crashes
    let mut menu_bar = MenuBar::new();
    let mut edit_menu = MenuBar::new();
    edit_menu.add_native_item(MenuItem::Undo);
    edit_menu.add_native_item(MenuItem::Redo);
    edit_menu.add_native_item(MenuItem::Cut);
    edit_menu.add_native_item(MenuItem::Copy);
    edit_menu.add_native_item(MenuItem::Paste);
    edit_menu.add_native_item(MenuItem::SelectAll);
    menu_bar.add_submenu("Edit", true, edit_menu);

    let window = WindowBuilder::new()
        .with_title("Sky")
        .with_menu(menu_bar)
        .with_inner_size(tao::dpi::LogicalSize::new(1100.0, 720.0))
        .with_min_inner_size(tao::dpi::LogicalSize::new(800.0, 500.0))
        .build(&event_loop)?;

    let user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36";

    let _webview = WebViewBuilder::new(&window)
        .with_user_agent(user_agent)
        .with_url("https://www.google.com")
        .build()?;

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;

        match event {
            Event::NewEvents(StartCause::Init) => println!("[Sky Rust] Native Browser started with Cmd+A support."),
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                ..
            } => *control_flow = ControlFlow::Exit,
            _ => (),
        }
    });
}
