const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const games = [
  { name: 'chess',         url: 'https://chess.ariantra.com/' },
  { name: 'subway-surfer', url: 'https://subway-surfer.ariantra.com/' },
  { name: 'dino-mutation', url: 'https://dino-mutation.ariantra.com/' },
  { name: 'dino-race',     url: 'https://dino-race.ariantra.com/' },
  { name: 'space-fight',   url: 'https://space-fight.ariantra.com/' },
  { name: 'neon-challenge',url: 'https://neon-challenge.ariantra.com/' },
  { name: 'cricket',       url: 'https://cricket.ariantra.com/' },
  { name: 'aeroplane',     url: 'https://aeroplane.ariantra.com/' },
  { name: 'snake-realms',  url: 'https://snake-realms.ariantra.com/' },
  { name: 'dino-arena',    url: 'https://dino-world-arena.ariantra.com/' },
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
