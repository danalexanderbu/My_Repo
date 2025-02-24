import { RETRY_DELAY } from 'puppeteer';
import puppeteer from 'puppeteer-extra';
import StealthPlugin from 'puppeteer-extra-plugin-stealth';
puppeteer.use(StealthPlugin());

const productSources = {
  jira: "https://www.atlassian.com/software/jira/download-archives",
  bamboo: "https://www.atlassian.com/software/bamboo/download-archives",
  bitbucket: "https://www.atlassian.com/software/bitbucket/download-archives",
  confluence: "https://www.atlassian.com/software/confluence/download-archives",
  artifactory: "https://jfrog.com/download-jfrog-platform",
  gitlab: "https://packages.gitlab.com/app/gitlab/gitlab-ce/search?dist=el%2F9",
  jenkins: "https://archives.jenkins-ci.org/redhat-stable",
  sonarqube: "https://www.sonarsource.com/products/sonarqube/downloads/success-download-community-edition"
};

async function scrapeProduct(product) {
  const url = productSources[product];
  let versionData = null; // ✅ Declare variable before assigning

  const browser = await puppeteer.launch({
    executablePath: '/usr/bin/google-chrome-stable',
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-blink-features=AutomationControlled',
      '--window-size=1280,800'
    ]
  });

  const page = await browser.newPage();
  await page.setUserAgent(
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.75 Safari/537.36'
  );

  await page.goto(url, { waitUntil: 'networkidle2' });

  if (url.includes("atlassian.com")) {
    versionData = await scrapeAtlassian(page, product);
  } else if (url.includes("jfrog.com")) {
    versionData = await scrapeJfrog(page);
  } else if (url.includes("gitlab.com")) {
    versionData = await scrapeGitlab(page);
  } else if (url.includes("jenkins-ci.org")) {
    versionData = await scrapeJenkins(page);
  } else if (url.includes("sonarsource.com")) {
    versionData = await scrapeSonarqube(page);
  }

  await browser.close();

  return versionData ? { version: versionData.version, url: versionData.url } : null;
}

// ✅ Helper functions for each product

async function scrapeAtlassian(page, product) {
  const expanders = await page.$$('a.expander');
  let targetExpander = null;
  let highestVersion = null;

  for (const expander of expanders) {
    const versionText = await page.evaluate(el => el.getAttribute('data-version'), expander);

    if (versionText) {
      const versionNum = parseFloat(versionText);
      if (!highestVersion || versionNum > highestVersion) {
        highestVersion = versionNum;
        targetExpander = expander;
      }
    }
  }

  if (!targetExpander) {
    return null;
  }

  await targetExpander.evaluate(el => el.scrollIntoView({ behavior: 'smooth', block: 'center' }));
  await targetExpander.click();
  await new Promise(r => setTimeout(r, 2000));

  const downloadButtons = await page.$$('a.product-versions.accordion');
  if (downloadButtons.length === 0) {
    return null;
  }

  await downloadButtons[0].evaluate(el => el.scrollIntoView({ behavior: 'smooth', block: 'center' }));
  await downloadButtons[0].click();
  await new Promise(r => setTimeout(r, 2000));

  const fileExtension = (product === "bitbucket" || product === "confluence") ? ".bin" : ".tar.gz";

  return await page.evaluate((fileExtension) => {
    const option = document.querySelector(`select#select-product-version option[data-product-version][value*="${fileExtension}"]`);
    return option
      ? { version: option.getAttribute('data-product-version'), url: option.getAttribute('value') }
      : null;
  }, fileExtension);
}

async function scrapeJfrog(page) {
  return await page.evaluate(() => {
      // Select the `<a>` tag containing the RPM download link
      const rpmLink = document.querySelector("a.ijf-download.download-link[href$='.rpm']");

      if (!rpmLink) return null;

      return {
          version: rpmLink.href.split('/').pop().replace('.rpm', ''),
          url: rpmLink.href // Extracts the RPM URL
      };
  });
}

async function scrapeGitlab(page) {
  return await page.evaluate(() => {
      // Select the first `<a>` tag that contains "x86_64.rpm"
      const rpmLink = document.querySelector("a[href$='x86_64.rpm']");

      if (!rpmLink) return null;

      return {
          version: rpmLink.textContent.trim(), // Extracts "gitlab-ce-17.9.0-ce.0.el9.x86_64.rpm"
          url: `https://packages.gitlab.com${rpmLink.getAttribute('href')}` // Convert relative URL to absolute
      };
  });
}

async function scrapeJenkins(page) {
  return await page.evaluate(() => {
      // Select all `<a>` tags with ".noarch.rpm" in the href
      const rpmLinks = document.querySelectorAll("a[href$='.noarch.rpm']");

      if (rpmLinks.length === 0) return null;

      // Get the last `.noarch.rpm` link
      const lastRpmLink = rpmLinks[rpmLinks.length - 1];

      return {
          version: lastRpmLink.textContent.trim(), // Extracts "jenkins-2.492.1-1.1.noarch.rpm"
          url: lastRpmLink.href // Extracts the full URL
      };
  });
}

async function scrapeSonarqube(page) {
  return await page.evaluate(() => {
    const downloadSelector = "a[href*='binaries.sonarsource.com/Distribution/sonarqube'][href$='.zip']";
    const downloadLink = document.querySelector(downloadSelector);
    return downloadLink
      ? { version: downloadLink.href.split('/').pop().replace('.zip', ''), url: downloadLink.href }
      : null;
  });
}

(async () => {
  const results = await Promise.all(Object.keys(productSources).map(scrapeProduct));

  const formattedResults = results
    .filter(Boolean)
    .reduce((acc, product, index) => {
      acc[Object.keys(productSources)[index]] = product;
      return acc;
    }, {});

  console.log(JSON.stringify(formattedResults, null, 2));
})();
