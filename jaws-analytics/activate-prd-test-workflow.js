#!/usr/bin/env node
/**
 * Activate PRD Analyzer Test Wrapper workflow
 *
 * This script directly updates the n8n SQLite database to activate the workflow.
 * Run this after importing workflows via CLI.
 */

const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3');

// Find n8n database location
const n8nHome = process.env.N8N_USER_FOLDER || path.join(require('os').homedir(), '.n8n');
const dbPath = path.join(n8nHome, 'database.sqlite');

if (!fs.existsSync(dbPath)) {
  console.error(`ERROR: n8n database not found at ${dbPath}`);
  console.error('Make sure n8n is installed and has been run at least once.');
  process.exit(1);
}

console.log(`Found n8n database: ${dbPath}`);

// Open database
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('ERROR: Could not open database:', err.message);
    process.exit(1);
  }
});

// Activate the workflow
db.run(
  `UPDATE workflow_entity SET active = 1 WHERE name = 'PRD Analyzer Test Wrapper'`,
  function(err) {
    if (err) {
      console.error('ERROR: Could not activate workflow:', err.message);
      db.close();
      process.exit(1);
    }

    if (this.changes === 0) {
      console.log('WARNING: No workflow found with name "PRD Analyzer Test Wrapper"');
      console.log('Make sure you have imported the workflow first:');
      console.log('  n8n import:workflow --input=workflows/prd-analyzer-test.json');
    } else {
      console.log(`✓ Successfully activated "PRD Analyzer Test Wrapper" workflow`);
      console.log('\nIMPORTANT: Restart n8n for changes to take effect:');
      console.log('  1. Stop n8n (Ctrl+C if running)');
      console.log('  2. Start n8n: n8n start');
    }

    db.close();
  }
);
