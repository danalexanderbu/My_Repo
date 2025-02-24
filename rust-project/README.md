Multi-Product Downloader & Artifactory Uploader
A cross-platform GUI application written in Rust that leverages Node.js web scraping (using Puppeteer and Puppeteer-extra) to retrieve download URLs for multiple software products (e.g., Jira, Confluence, Bitbucket, Bamboo, GitLab, Jenkins, Artifactory, SonarQube). The application displays these URLs as download buttons, allowing you to download the selected files and automatically push them to an Artifactory repository.

Features
Multi-Product Support:
Scrapes download pages for various software products:

Atlassian: Jira, Confluence, Bitbucket, Bamboo
Others: GitLab, Jenkins, Artifactory, SonarQube
Node.js Scraping:
Uses Puppeteer and puppeteer-extra for robust web scraping, including handling sites that may block headless browsers.

Rust GUI:
Built with iced, the application presents a clean, cross-platform graphical user interface.

Download & Upload:
When a download button is clicked, the file is downloaded and then pushed to an Artifactory repository using Rust’s HTTP client (reqwest).

Concurrent Processing:
The application can run the Node.js scraper as a separate process for each product, improving overall speed.
