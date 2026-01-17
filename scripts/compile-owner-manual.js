#!/usr/bin/env node

/**
 * compile-owner-manual.js
 *
 * Runs all Owner's Manual generators and compiles output into single DOCX file
 *
 * Usage:
 *   node scripts/compile-owner-manual.js <path-to-prd.md>
 *   node scripts/compile-owner-manual.js jaws-analytics/PRD.md
 */

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

// Configuration
const REQUIRED_ENV_VARS = ['ANTHROPIC_API_KEY'];

// Parse command line arguments
const args = process.argv.slice(2);
let prdPath = null;
let skipGeneration = false;
let compileOnly = false;

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--skip-generation' || args[i] === '-s') {
    skipGeneration = true;
  } else if (args[i] === '--compile-only' || args[i] === '-c') {
    compileOnly = true;
  } else if (!prdPath) {
    prdPath = args[i];
  }
}

if (!prdPath) {
  console.error('Error: No PRD path provided');
  console.error('Usage: node scripts/compile-owner-manual.js [options] <path-to-prd.md>');
  console.error('');
  console.error('Options:');
  console.error('  --skip-generation, -s    Skip generation, only compile existing files');
  console.error('  --compile-only, -c       Compile only (same as --skip-generation)');
  process.exit(1);
}

// Resolve paths
const prdFullPath = path.resolve(prdPath);
const prdDir = path.dirname(prdFullPath);
const outputDir = path.join(prdDir, 'owner-manual');
const scriptsDir = path.join(__dirname);

console.log('╔════════════════════════════════════════════════════════════════╗');
console.log('║         OWNER\'S MANUAL COMPILER                                ║');
console.log('╚════════════════════════════════════════════════════════════════╝');
console.log('');
console.log('Input PRD:', prdFullPath);
console.log('Output Directory:', outputDir);
if (skipGeneration || compileOnly) {
  console.log('Mode: Compile existing files only (skipping generation)');
}
console.log('');

// Verify PRD exists
if (!fs.existsSync(prdFullPath)) {
  console.error(`Error: PRD file not found: ${prdFullPath}`);
  process.exit(1);
}

// Extract project name from PRD
let projectName = 'Unknown Project';
try {
  const prdContent = fs.readFileSync(prdFullPath, 'utf8');
  const projectNameMatch = prdContent.match(/^#\s+(?:PRD:\s*)?(.+)$/m);
  if (projectNameMatch) {
    projectName = projectNameMatch[1].trim();
  }
  console.log('✓ Detected project:', projectName);
  console.log('');
} catch (error) {
  console.error('Warning: Could not read PRD to extract project name');
}

// Define all generators in order
const generators = [
  { name: 'WHAT-YOU-HAVE', script: 'generate-what-you-have.js', output: 'WHAT-YOU-HAVE.md' },
  { name: 'HOW-IT-WORKS', script: 'generate-how-it-works.js', output: 'HOW-IT-WORKS.md' },
  { name: 'DAILY-OPERATIONS', script: 'generate-daily-operations.js', output: 'DAILY-OPERATIONS.md' },
  { name: 'WHEN-THINGS-BREAK', script: 'generate-troubleshooting.js', output: 'WHEN-THINGS-BREAK.md' },
  { name: 'MAKING-CHANGES', script: 'generate-making-changes.js', output: 'MAKING-CHANGES.md' },
  { name: 'COSTS', script: 'generate-costs.js', output: 'COSTS.md' },
  { name: 'HANDOVER-CHECKLIST', script: 'generate-handover.js', output: 'HANDOVER-CHECKLIST.md' }
];

// Run all generators
async function runGenerators() {
  // Validate environment only if we're generating
  for (const envVar of REQUIRED_ENV_VARS) {
    if (!process.env[envVar]) {
      console.error(`Error: ${envVar} environment variable not set`);
      console.error(`Set it with: export ${envVar}=your-value-here`);
      console.error('');
      console.error('Tip: Use --compile-only flag to skip generation and just compile existing files');
      process.exit(1);
    }
  }

  console.log('═══════════════════════════════════════════════════════════════');
  console.log('STEP 1: Generating Owner\'s Manual Sections');
  console.log('═══════════════════════════════════════════════════════════════');
  console.log('');

  for (let i = 0; i < generators.length; i++) {
    const generator = generators[i];
    console.log(`[${i + 1}/${generators.length}] Generating ${generator.name}...`);

    const scriptPath = path.join(scriptsDir, generator.script);
    const command = `node "${scriptPath}" "${prdFullPath}"`;

    try {
      const { stdout, stderr } = await execAsync(command);

      // Verify output was created
      const outputPath = path.join(outputDir, generator.output);
      if (!fs.existsSync(outputPath)) {
        throw new Error(`Output file not created: ${outputPath}`);
      }

      console.log(`    ✓ Generated ${generator.output}`);
      console.log('');
    } catch (error) {
      console.error(`    ✗ Failed to generate ${generator.name}`);
      console.error(`    Error: ${error.message}`);
      process.exit(1);
    }
  }

  console.log('✓ All sections generated successfully!');
  console.log('');
}

// Compile to DOCX
async function compileToDOCX() {
  console.log('═══════════════════════════════════════════════════════════════');
  console.log('STEP 2: Compiling to DOCX Format');
  console.log('═══════════════════════════════════════════════════════════════');
  console.log('');

  try {
    // Check if docx library is available
    let docx;
    try {
      docx = require('docx');
    } catch (error) {
      console.log('⚠ docx library not found. Installing...');
      console.log('');

      // Install docx library
      await execAsync('npm install docx', { cwd: path.join(__dirname, '..') });

      console.log('✓ docx library installed');
      console.log('');

      docx = require('docx');
    }

    const { Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType, Table, TableRow, TableCell, BorderStyle, WidthType, convertInchesToTwip, PageBreak, Footer, Header } = docx;

    // Read all markdown files (skip missing ones)
    const sections = [];
    for (const generator of generators) {
      const filePath = path.join(outputDir, generator.output);
      if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, 'utf8');
        sections.push({
          name: generator.name,
          content: content
        });
      } else {
        console.log(`⚠ Skipping missing file: ${generator.output}`);
      }
    }

    if (sections.length === 0) {
      throw new Error('No markdown files found to compile. Run generators first or check output directory.');
    }

    console.log(`✓ Loaded ${sections.length} sections for compilation`);
    console.log('');

    // Convert markdown to DOCX paragraphs
    function markdownToDOCX(markdown) {
      const paragraphs = [];
      const lines = markdown.split('\n');

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i];

        // Skip empty lines (but add spacing)
        if (line.trim() === '') {
          paragraphs.push(new Paragraph({ text: '', spacing: { after: 100 } }));
          continue;
        }

        // H1 heading
        if (line.startsWith('# ')) {
          paragraphs.push(new Paragraph({
            text: line.substring(2),
            heading: HeadingLevel.HEADING_1,
            spacing: { before: 400, after: 200 }
          }));
        }
        // H2 heading
        else if (line.startsWith('## ')) {
          paragraphs.push(new Paragraph({
            text: line.substring(3),
            heading: HeadingLevel.HEADING_2,
            spacing: { before: 300, after: 150 }
          }));
        }
        // H3 heading
        else if (line.startsWith('### ')) {
          paragraphs.push(new Paragraph({
            text: line.substring(4),
            heading: HeadingLevel.HEADING_3,
            spacing: { before: 200, after: 100 }
          }));
        }
        // Bullet list
        else if (line.startsWith('- ') || line.startsWith('* ')) {
          paragraphs.push(new Paragraph({
            text: line.substring(2),
            bullet: { level: 0 },
            spacing: { after: 50 }
          }));
        }
        // Numbered list
        else if (/^\d+\.\s/.test(line)) {
          const text = line.replace(/^\d+\.\s/, '');
          paragraphs.push(new Paragraph({
            text: text,
            numbering: { reference: 'default-numbering', level: 0 },
            spacing: { after: 50 }
          }));
        }
        // Checkbox (unchecked)
        else if (line.startsWith('- [ ] ')) {
          paragraphs.push(new Paragraph({
            text: '☐ ' + line.substring(6),
            spacing: { after: 50 }
          }));
        }
        // Checkbox (checked)
        else if (line.startsWith('- [x] ') || line.startsWith('- [X] ')) {
          paragraphs.push(new Paragraph({
            text: '☑ ' + line.substring(6),
            spacing: { after: 50 }
          }));
        }
        // Bold text (simplified)
        else if (line.includes('**')) {
          const children = [];
          const parts = line.split('**');
          for (let j = 0; j < parts.length; j++) {
            if (j % 2 === 0) {
              // Normal text
              if (parts[j]) {
                children.push(new TextRun(parts[j]));
              }
            } else {
              // Bold text
              children.push(new TextRun({ text: parts[j], bold: true }));
            }
          }
          paragraphs.push(new Paragraph({
            children: children,
            spacing: { after: 100 }
          }));
        }
        // Regular paragraph
        else {
          paragraphs.push(new Paragraph({
            text: line,
            spacing: { after: 100 }
          }));
        }
      }

      return paragraphs;
    }

    // Build document sections
    const docSections = [];

    // Cover page
    docSections.push(
      new Paragraph({
        text: '',
        spacing: { before: convertInchesToTwip(2) }
      }),
      new Paragraph({
        text: 'Owner\'s Manual',
        heading: HeadingLevel.HEADING_1,
        alignment: AlignmentType.CENTER,
        spacing: { after: 400 }
      }),
      new Paragraph({
        text: projectName,
        heading: HeadingLevel.HEADING_2,
        alignment: AlignmentType.CENTER,
        spacing: { after: 200 }
      }),
      new Paragraph({
        text: '',
        spacing: { after: convertInchesToTwip(1) }
      }),
      new Paragraph({
        text: 'Everything you need to understand and operate your system',
        alignment: AlignmentType.CENTER,
        spacing: { after: 400 }
      }),
      new Paragraph({
        text: '',
        spacing: { after: convertInchesToTwip(1) }
      }),
      new Paragraph({
        text: `Generated: ${new Date().toLocaleDateString()}`,
        alignment: AlignmentType.CENTER,
        spacing: { after: 200 }
      }),
      new Paragraph({
        text: '',
        pageBreakBefore: true
      })
    );

    // Table of Contents
    docSections.push(
      new Paragraph({
        text: 'Table of Contents',
        heading: HeadingLevel.HEADING_1,
        spacing: { after: 400 }
      })
    );

    for (let i = 0; i < sections.length; i++) {
      docSections.push(
        new Paragraph({
          text: `${i + 1}. ${sections[i].name.replace(/-/g, ' ')}`,
          spacing: { after: 150 }
        })
      );
    }

    docSections.push(
      new Paragraph({
        text: '',
        pageBreakBefore: true
      })
    );

    // Add each section
    for (let i = 0; i < sections.length; i++) {
      const section = sections[i];

      // Section title
      docSections.push(
        new Paragraph({
          text: `${i + 1}. ${section.name.replace(/-/g, ' ')}`,
          heading: HeadingLevel.HEADING_1,
          spacing: { before: 0, after: 400 }
        })
      );

      // Section content
      const contentParagraphs = markdownToDOCX(section.content);
      docSections.push(...contentParagraphs);

      // Page break before next section (except last)
      if (i < sections.length - 1) {
        docSections.push(
          new Paragraph({
            text: '',
            pageBreakBefore: true
          })
        );
      }
    }

    // Create document
    const doc = new Document({
      sections: [{
        properties: {
          page: {
            pageNumbers: {
              start: 1,
              formatType: 'decimal'
            }
          }
        },
        footers: {
          default: new Footer({
            children: [
              new Paragraph({
                alignment: AlignmentType.CENTER,
                children: [
                  new TextRun({
                    text: `${projectName} - Owner's Manual`,
                    size: 16
                  })
                ]
              })
            ]
          })
        },
        children: docSections
      }]
    });

    // Generate output filename
    const safeProjectName = projectName.replace(/[^a-zA-Z0-9-]/g, '-').replace(/--+/g, '-');
    const outputFilename = `OwnerManual-${safeProjectName}.docx`;
    const outputPath = path.join(outputDir, outputFilename);

    // Save to file
    const buffer = await Packer.toBuffer(doc);
    fs.writeFileSync(outputPath, buffer);

    console.log('✓ Compiled to DOCX successfully!');
    console.log('');
    console.log('Output file:', outputPath);
    console.log('');

    return outputPath;

  } catch (error) {
    console.error('✗ Failed to compile DOCX');
    console.error('Error:', error.message);
    throw error;
  }
}

// Main execution
async function main() {
  try {
    // Check which files exist before generation
    const existingFiles = [];
    const missingFiles = [];

    for (const generator of generators) {
      const outputPath = path.join(outputDir, generator.output);
      if (fs.existsSync(outputPath)) {
        existingFiles.push(generator.output);
      } else {
        missingFiles.push(generator.output);
      }
    }

    console.log('═══════════════════════════════════════════════════════════════');
    console.log('File Status Check');
    console.log('═══════════════════════════════════════════════════════════════');
    console.log('');
    console.log(`Existing files: ${existingFiles.length}/${generators.length}`);
    existingFiles.forEach(f => console.log(`  ✓ ${f}`));
    if (missingFiles.length > 0) {
      console.log(`Missing files: ${missingFiles.length}/${generators.length}`);
      missingFiles.forEach(f => console.log(`  ✗ ${f}`));
    }
    console.log('');

    // Run generation or skip
    if (skipGeneration || compileOnly) {
      if (missingFiles.length > 0) {
        console.log('⚠ Warning: Some files are missing but generation is skipped');
        console.log('⚠ The compiled DOCX will only include existing sections');
        console.log('');
      } else {
        console.log('✓ All files exist, proceeding to compilation');
        console.log('');
      }
    } else {
      await runGenerators();
    }

    const docxPath = await compileToDOCX();

    console.log('═══════════════════════════════════════════════════════════════');
    console.log('COMPILATION COMPLETE!');
    console.log('═══════════════════════════════════════════════════════════════');
    console.log('');
    console.log('✓ All 7 sections generated');
    console.log('✓ Compiled to professional DOCX format');
    console.log('✓ Includes table of contents');
    console.log('✓ Professional formatting with headers and spacing');
    console.log('✓ Cover page with project name');
    console.log('✓ Page numbers in footer');
    console.log('');
    console.log('📄 Owner\'s Manual:', path.basename(docxPath));
    console.log('');
    console.log('Next Steps:');
    console.log('1. Open the DOCX file in Microsoft Word or Google Docs');
    console.log('2. Review all 7 sections for accuracy');
    console.log('3. Share with your client');
    console.log('');

  } catch (error) {
    console.error('');
    console.error('═══════════════════════════════════════════════════════════════');
    console.error('COMPILATION FAILED');
    console.error('═══════════════════════════════════════════════════════════════');
    console.error('');
    console.error('Error:', error.message);
    process.exit(1);
  }
}

main();
