const fs = require('fs');

const html = fs.readFileSync('index.html', 'utf8');
const scripts = [...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)];

for (let index = 0; index < scripts.length; index += 1) {
  const source = scripts[index][1];
  try {
    new Function(source);
  } catch (error) {
    console.error(`Inline script ${index + 1} has invalid JavaScript: ${error.message}`);
    process.exit(1);
  }
}

console.log(`PASS: ${scripts.length} inline scripts parsed successfully.`);
