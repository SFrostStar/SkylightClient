use tao::{
    event::{Event, StartCause, WindowEvent},
    event_loop::{ControlFlow, EventLoop},
    window::WindowBuilder,
};
use wry::WebViewBuilder;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let event_loop = EventLoop::new();
    let window = WindowBuilder::new()
        .with_title("Sky")
        .with_inner_size(tao::dpi::LogicalSize::new(1100.0, 720.0))
        .with_min_inner_size(tao::dpi::LogicalSize::new(800.0, 500.0))
        .build(&event_loop)?;

    let current_dir = std::env::current_dir()?;
    let index_path = current_dir.join("index.html");
    let file_url = format!("file://{}", index_path.to_string_lossy());
    
    let user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36";

    let _webview = WebViewBuilder::new(&window)
        .with_user_agent(user_agent)
        .with_url(&file_url)
        .build()?;

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;

        match event {
            Event::NewEvents(StartCause::Init) => println!("[Sky Rust] Multi-Tab Native Browser started cleanly via local protocol."),
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                ..
            } => *control_flow = ControlFlow::Exit,
            _ => (),
        }
    });
}
