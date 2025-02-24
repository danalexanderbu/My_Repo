use iced::{
    executor,
    widget::{button, column, text, checkbox},
    window, Application, Command, Element, Length, Settings, Size, Theme,
};
use std::collections::HashSet;
use std::process::{Command as ShellCommand, Stdio};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
struct ProductVersion {
    version: String,
    url: String,
}

#[derive(Debug, Deserialize)]
struct ScriptOutput {
    jira: Option<ProductVersion>,
    bamboo: Option<ProductVersion>,
    bitbucket: Option<ProductVersion>,
    confluence: Option<ProductVersion>,
    artifactory: Option<ProductVersion>,
    gitlab: Option<ProductVersion>,
    jenkins: Option<ProductVersion>,
    sonarqube: Option<ProductVersion>,
}

#[derive(Debug, Clone)]
enum Message {
    ToggleUrl(String),  // Select/deselect a download URL
    DownloadSelected,   // Start downloading selected files
}

struct MyApp {
    output: Option<ScriptOutput>,
    error_message: Option<String>,
    selected_urls: HashSet<String>,
}

impl Application for MyApp {
    type Executor = executor::Default;
    type Message = Message;
    type Theme = Theme;
    type Flags = ();

    fn new(_flags: ()) -> (Self, Command<Self::Message>) {
        let mut app = MyApp {
            output: None,
            error_message: None,
            selected_urls: HashSet::new(),
        };

        match run_node_script("/home/dburke/Documents/My_Repo/rust-project/download_util/scraper/scraper.mjs") {
            Ok(data) => {
                app.output = Some(data);
            }
            Err(e) => {
                app.error_message = Some(e);
            }
        }

        (app, Command::none())
    }

    fn title(&self) -> String {
        String::from("📥 Download Manager")
    }

    fn update(&mut self, message: Message) -> Command<Self::Message> {
        match message {
            Message::ToggleUrl(url) => {
                if self.selected_urls.contains(&url) {
                    self.selected_urls.remove(&url);
                } else {
                    self.selected_urls.insert(url);
                }
            }
            Message::DownloadSelected => {
                if self.selected_urls.is_empty() {
                    println!("⚠ No files selected for download.");
                } else {
                    for url in &self.selected_urls {
                        println!("⬇ Downloading: {}", url);

                        let _ = ShellCommand::new("wget")
                            .arg(url)
                            .stdout(Stdio::inherit())
                            .stderr(Stdio::inherit())
                            .spawn();
                    }
                }
            }
        }
        Command::none()
    }

    fn view(&self) -> Element<Self::Message> {
        let mut col = column![]
            .spacing(20)
            .padding(30)
            .width(Length::Fill);

        if let Some(err) = &self.error_message {
            col = col.push(text(format!("❌ Error: {}", err)));
        } else if let Some(output) = &self.output {
            col = col.push(text("📦 Latest Software Versions").size(30));

            col = self.display_latest_version("JIRA", &output.jira, col);
            col = self.display_latest_version("BAMBOO", &output.bamboo, col);
            col = self.display_latest_version("BITBUCKET", &output.bitbucket, col);
            col = self.display_latest_version("CONFLUENCE", &output.confluence, col);
            col = self.display_latest_version("ARTIFACTORY", &output.artifactory, col);
            col = self.display_latest_version("GITLAB", &output.gitlab, col);
            col = self.display_latest_version("JENKINS", &output.jenkins, col);
            col = self.display_latest_version("SONARQUBE", &output.sonarqube, col);

            // ✅ Download Button
            col = col.push(
                button("⬇ Download Selected")
                    .on_press(Message::DownloadSelected),
            );

        } else {
            col = col.push(text("No data yet.").size(24));
        }

        col.into()
    }

    fn theme(&self) -> Self::Theme {
        Theme::Dark
    }
}

fn main() -> iced::Result {
    MyApp::run(Settings {
        window: window::Settings {
            size: Size::new(800.0, 600.0),
            resizable: true,
            decorations: true,
            ..Default::default()
        },
        ..Settings::default()
    })
}

impl MyApp {
    fn display_latest_version<'a>(
        &self,
        title: &str,
        product: &'a Option<ProductVersion>,
        col: iced::widget::Column<'a, Message>,
    ) -> iced::widget::Column<'a, Message> {
        let mut col = col.push(text(format!("{}:", title)).size(24));

        if let Some(pv) = product {
            let file_extension = match title {
                "BITBUCKET" | "CONFLUENCE" => ".bin",
                "ARTIFACTORY" | "GITLAB" | "JENKINS" => ".rpm",
                "SONARQUBE" => ".zip",
                _ => ".tar.gz",
            };
            let file_name = format!("{}-{}{}", title.to_lowercase(), pv.version, file_extension);

            let is_selected = self.selected_urls.contains(&pv.url);

            col = col.push(
                checkbox(format!("{} ({})", file_name, pv.version), is_selected)
                    .on_toggle(move |_is_checked| Message::ToggleUrl(pv.url.clone())),
            );
        } else {
            col = col.push(text("⚠ No version found").size(16));
        }

        col
    }
}

fn run_node_script(script_path: &str) -> Result<ScriptOutput, String> {
    let output = ShellCommand::new("node")
        .arg(script_path)
        .output()
        .map_err(|e| format!("Failed to spawn node process: {}", e))?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    let parsed: ScriptOutput = serde_json::from_str(&stdout)
        .map_err(|e| format!("Failed to parse JSON: {}\nRaw Output: {}", e, stdout))?;

    Ok(parsed)
}
