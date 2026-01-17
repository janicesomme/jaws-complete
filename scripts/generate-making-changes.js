#!/usr/bin/env node

/**
 * generate-making-changes.js
 *
 * Generates plain English MAKING-CHANGES.md from a PRD using Claude API
 *
 * Usage:
 *   node scripts/generate-making-changes.js <path-to-prd.md>
 *   node scripts/generate-making-changes.js jaws-analytics/PRD.md
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

// Configuration
const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;
const MODEL = 'claude-sonnet-4-20250514';

// Validate inputs
if (!ANTHROPIC_API_KEY) {
  console.error('Error: ANTHROPIC_API_KEY environment variable not set');
  console.error('Set it with: export ANTHROPIC_API_KEY=your-key-here');
  process.exit(1);
}

const prdPath = process.argv[2];
if (!prdPath) {
  console.error('Error: No PRD path provided');
  console.error('Usage: node scripts/generate-making-changes.js <path-to-prd.md>');
  process.exit(1);
}

// Resolve paths
const prdFullPath = path.resolve(prdPath);
const prdDir = path.dirname(prdFullPath);
const outputDir = path.join(prdDir, 'owner-manual');
const outputPath = path.join(outputDir, 'MAKING-CHANGES.md');
const promptPath = path.join(__dirname, '..', 'prompts', 'owner-manual', 'making-changes-prompt.md');

console.log('=== MAKING-CHANGES.md Generator ===\n');
console.log('Input PRD:', prdFullPath);
console.log('Output:', outputPath);
console.log('');

// Read files
let prdContent, promptContent;

try {
  if (!fs.existsSync(prdFullPath)) {
    console.error(`Error: PRD file not found: ${prdFullPath}`);
    process.exit(1);
  }
  prdContent = fs.readFileSync(prdFullPath, 'utf8');
  console.log('✓ Read PRD.md');
} catch (error) {
  console.error('Error reading PRD:', error.message);
  process.exit(1);
}

try {
  if (!fs.existsSync(promptPath)) {
    console.error(`Error: Prompt file not found: ${promptPath}`);
    process.exit(1);
  }
  promptContent = fs.readFileSync(promptPath, 'utf8');
  console.log('✓ Read prompt template');
} catch (error) {
  console.error('Error reading prompt:', error.message);
  process.exit(1);
}

// Extract project name from PRD
const projectNameMatch = prdContent.match(/^#\s+(?:PRD:\s*)?(.+)$/m);
const projectName = projectNameMatch ? projectNameMatch[1].trim() : 'Unknown Project';
console.log('✓ Detected project:', projectName);
console.log('');

// Create output directory
try {
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
    console.log('✓ Created owner-manual directory');
  }
} catch (error) {
  console.error('Error creating output directory:', error.message);
  process.exit(1);
}

// Call Claude API
console.log('Calling Claude API to generate change management guide...');
console.log('');

const apiRequest = {
  model: MODEL,
  max_tokens: 4000,
  messages: [
    {
      role: 'user',
      content: `${promptContent}\n\n---\n\n# INPUT PRD\n\n${prdContent}`
    }
  ]
};

const postData = JSON.stringify(apiRequest);

const options = {
  hostname: 'api.anthropic.com',
  port: 443,
  path: '/v1/messages',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(postData),
    'x-api-key': ANTHROPIC_API_KEY,
    'anthropic-version': '2023-06-01'
  }
};

const req = https.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    if (res.statusCode !== 200) {
      console.error('API Error:', res.statusCode);
      console.error(data);
      process.exit(1);
    }

    try {
      const response = JSON.parse(data);

      if (!response.content || !response.content[0] || !response.content[0].text) {
        console.error('Error: Unexpected API response format');
        console.error(JSON.stringify(response, null, 2));
        process.exit(1);
      }

      const generatedContent = response.content[0].text;

      // Save to file
      fs.writeFileSync(outputPath, generatedContent, 'utf8');

      console.log('✓ Generated MAKING-CHANGES.md successfully!');
      console.log('');
      console.log('Output saved to:', outputPath);
      console.log('');
      console.log('=== Preview ===');
      console.log('');

      // Show first 30 lines as preview
      const lines = generatedContent.split('\n');
      const preview = lines.slice(0, 30).join('\n');
      console.log(preview);

      if (lines.length > 30) {
        console.log('\n... (truncated, see full file at output path)');
      }

      console.log('');
      console.log('=== Summary ===');
      console.log('Project:', projectName);
      console.log('Words:', generatedContent.split(/\s+/).length);
      console.log('Lines:', lines.length);

      // Count safe vs risky changes
      const safeChanges = (generatedContent.match(/###\s*✅/g) || []).length;
      const riskyChanges = (generatedContent.match(/###\s*⚠️/g) || []).length;
      console.log('Safe changes documented:', safeChanges);
      console.log('Risky changes documented:', riskyChanges);

      // Verify key sections exist
      const hasSafeSection = generatedContent.includes('Safe Changes');
      const hasRiskySection = generatedContent.includes('Risky Changes');
      const hasQuickReference = generatedContent.includes('Quick Reference') || generatedContent.includes('Common Scenarios');
      const hasRequestProcess = generatedContent.includes('How to Request');

      console.log('');
      console.log('=== Validation ===');
      console.log('Has "Safe Changes" section:', hasSafeSection ? '✓' : '✗');
      console.log('Has "Risky Changes" section:', hasRiskySection ? '✓' : '✗');
      console.log('Has quick reference:', hasQuickReference ? '✓' : '✗');
      console.log('Has request process:', hasRequestProcess ? '✓' : '✗');

      console.log('');
      console.log('Next: Review that safe changes have step-by-step instructions and risky changes have clear warnings!');

    } catch (error) {
      console.error('Error parsing API response:', error.message);
      process.exit(1);
    }
  });
});

req.on('error', (error) => {
  console.error('Request error:', error.message);
  process.exit(1);
});

req.write(postData);
req.end();
