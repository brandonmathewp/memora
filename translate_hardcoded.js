const fs = require('fs');
const path = require('path');
const { translate } = require('@vitalets/google-translate-api');

// ===== CONFIGURATION =====
const TARGET_LANG = 'en';   // Change to your target language
const REPORT_FILE = 'i18n_report.txt';
const BASE_DIR = process.cwd();
// =========================

async function parseReport() {
    const content = fs.readFileSync(REPORT_FILE, 'utf8');
    const entries = [];
    // Updated regex: matches | N | "string" | `path:line` | key |
    // Captures: original string, file path (without backticks), line number
    const regex = /\|\s*\d+\s*\|\s*"([^"]+)"\s*\|\s*`([^`]+):(\d+)`/g;
    let match;
    while ((match = regex.exec(content)) !== null) {
        const original = match[1];
        const filePathRaw = match[2].trim();
        const lineNum = parseInt(match[3], 10);
        // Convert to absolute path
        const filePath = path.isAbsolute(filePathRaw) ? filePathRaw : path.join(BASE_DIR, filePathRaw);
        // Skip placeholder like "sk-..."
        if (original === 'sk-...' || original === '') continue;
        entries.push({ filePath, lineNum, original });
    }
    return entries;
}

async function replaceInFile(filePath, lineNum, original, translated) {
    if (!fs.existsSync(filePath)) {
        console.warn(`File not found: ${filePath}`);
        return false;
    }
    const lines = fs.readFileSync(filePath, 'utf8').split('\n');
    if (lineNum - 1 >= lines.length) return false;
    let oldLine = lines[lineNum - 1];
    // Replace double-quoted string first, then single-quoted
    let newLine = oldLine.replace(`"${original}"`, `"${translated}"`);
    if (newLine === oldLine) {
        newLine = oldLine.replace(`'${original}'`, `'${translated}'`);
    }
    if (newLine === oldLine) {
        console.warn(`Could not replace "${original}" in ${filePath}:${lineNum}`);
        return false;
    }
    lines[lineNum - 1] = newLine;
    fs.writeFileSync(filePath, lines.join('\n'), 'utf8');
    console.log(`✓ ${path.basename(filePath)}:${lineNum} | "${original}" → "${translated}"`);
    return true;
}

async function main() {
    console.log('📖 Parsing i18n report...');
    const entries = await parseReport();
    if (entries.length === 0) {
        console.log('No strings found to translate.');
        return;
    }
    console.log(`Found ${entries.length} strings. Translating to ${TARGET_LANG}...\n`);
    for (const entry of entries) {
        try {
            const res = await translate(entry.original, { to: TARGET_LANG });
            const translated = res.text;
            await replaceInFile(entry.filePath, entry.lineNum, entry.original, translated);
            await new Promise(r => setTimeout(r, 200)); // rate limit
        } catch (err) {
            console.error(`Failed to translate "${entry.original}":`, err.message);
        }
    }
    console.log('\n✅ Translation completed.');
}

main().catch(console.error);
