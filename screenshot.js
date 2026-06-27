const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const games = [
  { name: 'chess',         url: 'https://ag-chess.netlify.app/' },
  { name: 'subway-surfer', url: 'https://a-subway-surfer.netlify.app/' },
  { name: 'dino-mutation', url: 'https://a-dino-mutation.netlify.app/' },
  { name: 'dino-race',     url: 'https://a-dino-race.netlify.app/' },
  { name: 'space-fight',   url: 'https://agilan-spacefight.netlify.app/' },
  { name: 'neon-challenge',url: 'https://agilan-neon-challenge.netlify.app/' },
  { name: 'cricket',       url: 'https://atharvcricket.netlify.app/' },
  { name: 'aeroplane',     url: 'https://m-aeroplane.netlify.app/' },
  { name: 'snake-realms',  url: 'https://snakerealms.netlify.app/' },
  { name: 'dino-arena',    url: 'https://dino-world-arena.netlify.app/' },
];

const outDir = path.join(__dirname, 'thumbnails');
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir);

(async () => {
  const browser = await puppeteer.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 720 });

  for (const game of games) {
    console.log(`Screenshotting ${game.name}...`);
    try {
      await page.goto(game.url, { waitUntil: 'networkidle2', timeout: 20000 });
      await new Promise(r => setTimeout(r, 5000));
      await page.screenshot({
        path: path.join(outDir, `${game.name}.jpg`),
        type: 'jpeg',
        quality: 85,
        clip: { x: 0, y: 0, width: 1280, height: 720 }
      });
      console.log(`  ✓ ${game.name}`);
    } catch (e) {
      console.log(`  ✗ ${game.name} failed: ${e.message}`);
    }
  }

  await browser.close();
  console.log('\nDone. Thumbnails saved to /thumbnails/');
})();
