import axios from 'axios';
import 'dotenv/config';
import * as fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Setup __dirname for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const metadataDir = path.join(__dirname, 'metadata2');
const outputDir = path.join(__dirname, 'images2');

// Ensure output directory exists
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

async function downloadImage(url, outputPath) {
  const response = await axios({
    method: 'get',
    url: url,
    responseType: 'stream',
  });

  const writer = fs.createWriteStream(outputPath);

  return new Promise((resolve, reject) => {
    response.data.pipe(writer);
    writer.on('finish', resolve);
    writer.on('error', reject);
  });
}

async function processFiles() {
  const files = fs.readdirSync(metadataDir);
  console.log(`Found ${files.length} metadata files.`);

  for (let i = 0; i < files.length; i++) {
    const jsonFile = files[i];
    const jsonPath = path.join(metadataDir, jsonFile);

    try {
      const raw = fs.readFileSync(jsonPath, 'utf-8');
      const json = JSON.parse(raw);
      const imageUrl = json.image_url;

      if (imageUrl) {
        const baseName = path.basename(jsonFile, path.extname(jsonFile));
        const ext = path.extname(imageUrl).split('?')[0] || '.jpg';
        const imagePath = path.join(outputDir, `${baseName}${ext}`);

        await downloadImage(imageUrl, imagePath);
        console.log(`[${i + 1}/${files.length}] Saved: ${imagePath}`);
      } else {
        console.warn(`[${i + 1}/${files.length}] No image_url in ${jsonFile}`);
      }
    } catch (err) {
      console.error(`Error processing ${jsonFile}:`, err.message);
    }
  }

  console.log('✅ Done.');
}

processFiles();
