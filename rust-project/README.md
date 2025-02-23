Multi-Product Downloader & Artifactory Uploader
A cross-platform GUI application written in Rust that leverages Node.js web scraping (using Puppeteer and Puppeteer-extra) to retrieve download URLs for multiple software products (e.g., Jira, Confluence, Bitbucket, Bamboo, GitLab, Jenkins, Artifactory, SonarQube). The application displays these URLs as download buttons, allowing you to download the selected files and automatically push them to an Artifactory repository.

Features
Multi-Product Support:
Scrapes download pages for various software products:

Atlassian: Jira, Confluence, Bitbucket, Bamboo
Others: GitLab, Jenkins, Artifactory, SonarQube, etc.
Node.js Scraping:
Uses Puppeteer and puppeteer-extra for robust web scraping, including handling sites that may block headless browsers.

Rust GUI:
Built with iced, the application presents a clean, cross-platform graphical user interface.

Download & Upload:
When a download button is clicked, the file is downloaded and then pushed to an Artifactory repository using Rust’s HTTP client (reqwest).

Concurrent Processing:
The application can run the Node.js scraper as a separate process for each product, improving overall speed.

Prerequisites
Rust & Cargo:
Install via rustup. Verify with:

bash
Copy
rustc --version
cargo --version
Node.js:
Install Node.js (v14 or higher recommended) along with npm. Verify with:

bash
Copy
node --version
npm --version
Artifactory Repository:
An Artifactory endpoint along with required credentials for file uploads.

Dependencies for Node.js Scraper:
Your scraper requires puppeteer and puppeteer-extra.
Install them with:

bash
Copy
npm install puppeteer puppeteer-extra
Folder Structure
A sample folder structure for this project might look like:

graphql
Copy
download_util/
├── Cargo.toml                # Rust project configuration
├── src/
│   └── main.rs               # Main Rust GUI application (using iced)
├── scraper/
│   ├── scraper.mjs           # Node.js web scraper using Puppeteer/Puppeteer-extra
│   └── package.json          # Node.js dependencies (puppeteer, puppeteer-extra, etc.)
├── downloads.csv             # (Optional) CSV for storing download URLs
├── README.md                 # This README file
└── assets/                  # Additional assets (icons, images, etc.)
src/main.rs:
Contains the iced-based GUI code. It spawns the Node.js scraper as a separate process, displays download buttons based on the scraped URLs, and triggers downloads and Artifactory uploads when buttons are clicked.

scraper/scraper.mjs:
A Node.js script that uses Puppeteer (and puppeteer-extra) to scrape download URLs from the websites for various products. The script outputs JSON that is consumed by the Rust GUI.

scraper/package.json:
Defines the Node.js dependencies needed for the scraper.

Installation
1. Set Up Rust
If you haven't already, install Rust using rustup.

2. Set Up Node.js Scraper
In the scraper/ directory, create a package.json file with your required dependencies. For example:

json
Copy
{
  "name": "scraper",
  "version": "1.0.0",
  "dependencies": {
    "puppeteer": "^21.0.0",
    "puppeteer-extra": "^3.3.4",
    "puppeteer-extra-plugin-stealth": "^2.11.0"
  }
}
Then install dependencies:

bash
Copy
cd scraper
npm install
Test your scraper by running:

bash
Copy
node scraper.mjs
It should output a JSON array of download items.

3. Build and Run the Rust Application
From the project root, build and run the Rust application:

bash
Copy
cargo run
This will compile your Rust code and open the GUI window.

Usage
Scrape Downloads:
In the GUI, click the "Scrape Downloads" button to trigger the Node.js scraper. The scraper runs as a separate process, and its output (download URLs) is parsed and displayed as a series of download buttons.

Download & Upload:
Click on a download button corresponding to a particular software version. The Rust application will download the file (using reqwest) and push it to your Artifactory repository via its REST API.

Monitoring:
Status messages and progress are displayed in the terminal and/or GUI.

Pushing Files to Artifactory
You can implement the upload logic in Rust using the reqwest crate. For example, after downloading a file, you might call a function that sends a multipart POST request to Artifactory. Refer to Artifactory's REST API documentation for details on authentication and required parameters.

Future Improvements
Progress Indicators:
Add a progress bar for downloads and uploads.

Error Handling:
Enhance error reporting and retries for network operations.

Configuration:
Use environment variables or a configuration file for Artifactory credentials and other settings.

Asynchronous Processing:
Move from blocking to asynchronous downloads and uploads for improved performance.

Expanded Scraping:
Refine the scraping logic to support more products or more complex page structures.

