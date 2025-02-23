import puppeteer from 'puppeteer';

const products = ["jira", "bamboo"];

async function scrapeProduct(product) {
  const url = `https://www.atlassian.com/software/${product}/download-archives`;
  console.log(`\n===== Scraping ${product.toUpperCase()} from ${url} =====`);

  const browser = await puppeteer.launch({
    executablePath: '/usr/bin/google-chrome-stable',
    headless: false,
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

  // For simplicity, we'll assume that each product page uses a similar structure
  // and that we want to extract up to 5 download URLs.
  const allVersions = [];
  const processedIndexes = new Set();

  for (let i = 0; i < 10; i++) {
    if (allVersions.length >= 5) {
      console.log(`🎯 Reached limit of 5 URLs for ${product.toUpperCase()}.`);
      break;
    }

    console.log(`\n🔄 [${product.toUpperCase()}] Iteration #${i + 1} => Navigating to page fresh...`);
    await page.goto(url, { waitUntil: 'networkidle2' });

    // Find the expander for "10.x" (you may need to adapt if layout differs)
    const expanders = await page.$$('a.expander');
    let targetExpander = null;
    for (const expanderHandle of expanders) {
      const dv = await page.evaluate(el => el.getAttribute('data-version'), expanderHandle);
      // For demonstration, we assume we only want versions that start with "10."
      if (dv && dv.startsWith('10.')) {
        targetExpander = expanderHandle;
        break;
      }
    }
    if (!targetExpander) {
      console.log(`⚠️ No expander found for data-version="10.x" on ${product.toUpperCase()}. Stopping...`);
      break;
    }

    // Click the expander
    await targetExpander.evaluate(el => el.scrollIntoView({ behavior: 'smooth', block: 'center' }));
    await new Promise(r => setTimeout(r, 2000));
    console.log(`🖱️ Clicking the ${product.toUpperCase()} expander...`);
    await targetExpander.click();
    await new Promise(r => setTimeout(r, 3000));

    // Find all Download buttons on the page
    const downloadButtons = await page.$$('a.product-versions.accordion');
    console.log(`🔍 Found ${downloadButtons.length} Download buttons on iteration #${i + 1} for ${product.toUpperCase()}`);

    if (downloadButtons.length === 0) {
      console.log(`⚠️ No download buttons found for ${product.toUpperCase()}. Stopping...`);
      break;
    }

    const buttonIndex = i; // each iteration tries a new button
    if (buttonIndex >= downloadButtons.length) {
      console.log(`⚠️ Button index ${buttonIndex} >= total buttons ${downloadButtons.length} for ${product.toUpperCase()}. Stopping...`);
      break;
    }
    if (processedIndexes.has(buttonIndex)) {
      console.log(`ℹ️ Already processed button #${buttonIndex} for ${product.toUpperCase()}. Stopping...`);
      break;
    }
    processedIndexes.add(buttonIndex);

    // Scroll & click that button
    const btn = downloadButtons[buttonIndex];
    await btn.evaluate(el => el.scrollIntoView({ behavior: 'smooth', block: 'center' }));
    await new Promise(r => setTimeout(r, 2000));
    console.log(`📥 Clicking Download button #${buttonIndex + 1} for ${product.toUpperCase()}...`);
    try {
      await btn.click();
    } catch (err) {
      console.log(`❌ Could not click button #${buttonIndex + 1} for ${product.toUpperCase()}: ${err.message}`);
      continue;
    }

    // Wait for .tar.gz to load
    await new Promise(r => setTimeout(r, 3000));
    try {
      await page.waitForSelector(
        'select#select-product-version option[data-product-version][value*=".tar.gz"]',
        { timeout: 20000 }
      );

      const versionData = await page.evaluate(() => {
        const option = document.querySelector(
          'select#select-product-version option[data-product-version][value*=".tar.gz"]'
        );
        if (option) {
          return {
            version: option.getAttribute('data-product-version'),
            url: option.getAttribute('value')
          };
        }
        return null;
      });

      if (versionData) {
        if (!allVersions.some(item => item.url === versionData.url)) {
          console.log(`✅ Found ${product.toUpperCase()} sub-version: ${versionData.version}`);
          console.log(`🔗 URL: ${versionData.url}`);
          allVersions.push(versionData);
        } else {
          console.log(`ℹ️ Duplicate version ${versionData.version} found for ${product.toUpperCase()}. Skipping...`);
        }
      } else {
        console.log(`⚠️ No .tar.gz found for button #${buttonIndex + 1} for ${product.toUpperCase()}`);
      }
    } catch (err) {
      console.log(`❌ Timed out waiting for .tar.gz on ${product.toUpperCase()}: ${err.message}`);
    }

    // Reload the page for the next iteration
    console.log(`🔄 Reloading page for next iteration for ${product.toUpperCase()}...`);
    await page.reload({ waitUntil: 'networkidle2' });
  }

  console.log(`\n🎯 Final .tar.gz versions found for ${product.toUpperCase()}:`);
  console.table(allVersions);

  await browser.close();

  return allVersions;
}

const atlassians = ["bitbucket", "confluence"];

async function scrapeAtlassian(atlassian) {
  const url = `https://www.atlassian.com/software/${atlassian}/download-archives`;
  console.log(`\n===== Scraping ${atlassian.toUpperCase()} from ${url} =====`);

  const browser = await puppeteer.launch({
    executablePath: '/usr/bin/google-chrome-stable',
    headless: false,
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

  // For simplicity, we'll assume that each atlassian page uses a similar structure
  // and that we want to extract up to 5 download URLs.
  const allVersions = [];
  const processedIndexes = new Set();

  for (let i = 0; i < 10; i++) {
    if (allVersions.length >= 5) {
      console.log(`🎯 Reached limit of 5 URLs for ${atlassian.toUpperCase()}.`);
      break;
    }

    console.log(`\n🔄 [${atlassian.toUpperCase()}] Iteration #${i + 1} => Navigating to page fresh...`);
    await page.goto(url, { waitUntil: 'networkidle2' });

    // Find the expander for "10.x" (you may need to adapt if layout differs)
    const expanders = await page.$$('a.expander');
    let targetExpander = null;
    for (const expanderHandle of expanders) {
      const dv = await page.evaluate(el => el.getAttribute('data-version'), expanderHandle);
      // For demonstration, we assume we only want versions that start with "10."
      if (dv && dv.startsWith('9.0')) {
        targetExpander = expanderHandle;
        break;
      }
    }
    if (!targetExpander) {
      console.log(`⚠️ No expander found for data-version="10.x" on ${atlassian.toUpperCase()}. Stopping...`);
      break;
    }

    // Click the expander
    await targetExpander.evaluate(el => el.scrollIntoView({ behavior: 'smooth', block: 'center' }));
    await new Promise(r => setTimeout(r, 2000));
    console.log(`🖱️ Clicking the ${atlassian.toUpperCase()} expander...`);
    await targetExpander.click();
    await new Promise(r => setTimeout(r, 3000));

    // Find all Download buttons on the page
    const downloadButtons = await page.$$('a.product-versions.accordion');
    console.log(`🔍 Found ${downloadButtons.length} Download buttons on iteration #${i + 1} for ${atlassian.toUpperCase()}`);

    if (downloadButtons.length === 0) {
      console.log(`⚠️ No download buttons found for ${atlassian.toUpperCase()}. Stopping...`);
      break;
    }

    const buttonIndex = i; // each iteration tries a new button
    if (buttonIndex >= downloadButtons.length) {
      console.log(`⚠️ Button index ${buttonIndex} >= total buttons ${downloadButtons.length} for ${atlassian.toUpperCase()}. Stopping...`);
      break;
    }
    if (processedIndexes.has(buttonIndex)) {
      console.log(`ℹ️ Already processed button #${buttonIndex} for ${atlassian.toUpperCase()}. Stopping...`);
      break;
    }
    processedIndexes.add(buttonIndex);

    // Scroll & click that button
    const btn = downloadButtons[buttonIndex];
    await btn.evaluate(el => el.scrollIntoView({ behavior: 'smooth', block: 'center' }));
    await new Promise(r => setTimeout(r, 2000));
    console.log(`📥 Clicking Download button #${buttonIndex + 1} for ${atlassian.toUpperCase()}...`);
    try {
      await btn.click();
    } catch (err) {
      console.log(`❌ Could not click button #${buttonIndex + 1} for ${atlassian.toUpperCase()}: ${err.message}`);
      continue;
    }

    // Wait for x64.bin to load
    await new Promise(r => setTimeout(r, 3000));
    try {
      await page.waitForSelector(
        'select#select-product-version option[data-product-version][value*="x64.bin"]',
        { timeout: 20000 }
      );

      const versionData = await page.evaluate(() => {
        const option = document.querySelector(
          'select#select-product-version option[data-product-version][value*="x64.bin"]'
        );
        if (option) {
          return {
            version: option.getAttribute('data-product-version'),
            url: option.getAttribute('value')
          };
        }
        return null;
      });

      if (versionData) {
        if (!allVersions.some(item => item.url === versionData.url)) {
          console.log(`✅ Found ${atlassian.toUpperCase()} sub-version: ${versionData.version}`);
          console.log(`🔗 URL: ${versionData.url}`);
          allVersions.push(versionData);
        } else {
          console.log(`ℹ️ Duplicate version ${versionData.version} found for ${atlassian.toUpperCase()}. Skipping...`);
        }
      } else {
        console.log(`⚠️ No x64.bin found for button #${buttonIndex + 1} for ${atlassian.toUpperCase()}`);
      }
    } catch (err) {
      console.log(`❌ Timed out waiting for x64.bin on ${atlassian.toUpperCase()}: ${err.message}`);
    }

    // Reload the page for the next iteration
    console.log(`🔄 Reloading page for next iteration for ${atlassian.toUpperCase()}...`);
    await page.reload({ waitUntil: 'networkidle2' });
  }

  console.log(`\n🎯 Final x64.bin versions found for ${atlassian.toUpperCase()}:`);
  console.table(allVersions);

  await browser.close();

  return allVersions;
}

(async () => {
    try {
      const productResults = products.map(prod => scrapeProduct(prod));
      const atlassianResults = atlassians.map(atlassian => scrapeAtlassian(atlassian));

      // Wait for all scrapers to finish concurrently
      const results = await Promise.all([...productResults, ...atlassianResults]);
      console.log("\n===== Final Results =====");
      console.table(results);
    } catch (err) {
      console.error("Error running scrapers:", err);
    }
  })();
