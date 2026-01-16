/**
 * Test script for PRD Analyzer Test Wrapper (webhook endpoint)
 *
 * This tests the /webhook-test/analyze-prd endpoint that wraps
 * the PRD Analyzer sub-workflow.
 *
 * Prerequisites:
 * - n8n running on localhost:5678
 * - PRD Analyzer workflow imported and active
 * - PRD Analyzer Test Wrapper workflow imported and active
 *
 * Usage: node test-prd-analyzer-api.js
 */

const testPrdContent = `# PRD: Test Analytics Project

## Introduction

Build a test analytics system.

**Client:** Test Client Corp

## Goals

- Goal 1: Automate reporting
- Goal 2: Track metrics
- Goal 3: Generate insights

## Technical Stack

- **Analytics Engine:** n8n workflow
- **Database:** Supabase PostgreSQL
- **AI:** Claude API

## User Stories

### US-001: Create Dashboard
**Description:** Build a dashboard to display metrics

**Acceptance Criteria:**
- [x] Display key metrics
- [x] Add charts
- [ ] Export to PDF
- [ ] Add filters

### US-002: Data Collection
**Description:** Collect data from sources

**Acceptance Criteria:**
- [x] Connect to database
- [ ] Parse log files
- [SKIPPED] Legacy system integration

═══════════════════════════════════════════════════════════════════════════════
PHASE 1: Foundation                                    [CHECKPOINT: FOUNDATION]
═══════════════════════════════════════════════════════════════════════════════

More content here...

═══════════════════════════════════════════════════════════════════════════════
PHASE 2: Analytics Engine                                [CHECKPOINT: ANALYTICS]
═══════════════════════════════════════════════════════════════════════════════
`;

async function testPrdAnalyzer() {
  console.log('Testing PRD Analyzer via webhook endpoint...\n');

  try {
    const response = await fetch('http://localhost:5678/webhook-test/analyze-prd', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        prd_content: testPrdContent
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`Error: HTTP ${response.status}`);
      console.error(errorText);
      return;
    }

    const result = await response.json();

    console.log('✅ PRD Analyzer Response:\n');
    console.log(JSON.stringify(result, null, 2));

    // Validate expected fields
    console.log('\n📊 Validation Results:');
    console.log(`- Project Name: ${result.project_name || 'MISSING'}`);
    console.log(`- Client Name: ${result.client_name || 'MISSING'}`);
    console.log(`- Total User Stories: ${result.total_user_stories || 0}`);
    console.log(`- Completed Tasks: ${result.tasks_completed || 0}`);
    console.log(`- Incomplete Tasks: ${result.tasks_incomplete || 0}`);
    console.log(`- Skipped Tasks: ${result.tasks_skipped || 0}`);
    console.log(`- Total Tasks: ${result.tasks_total || 0}`);
    console.log(`- Completion Rate: ${result.completion_rate || 0}%`);
    console.log(`- Phases Count: ${result.phases ? result.phases.length : 0}`);
    console.log(`- Goals Count: ${result.goals ? result.goals.length : 0}`);
    console.log(`- Tech Stack Count: ${result.tech_stack ? result.tech_stack.length : 0}`);

    // Verify extraction accuracy
    console.log('\n🔍 Expected vs Actual:');

    const checks = [
      { name: 'Project Name', expected: 'Test Analytics Project', actual: result.project_name },
      { name: 'Client Name', expected: 'Test Client Corp', actual: result.client_name },
      { name: 'User Stories', expected: 2, actual: result.total_user_stories },
      { name: 'Completed Tasks', expected: 3, actual: result.tasks_completed },
      { name: 'Incomplete Tasks', expected: 3, actual: result.tasks_incomplete },
      { name: 'Skipped Tasks', expected: 1, actual: result.tasks_skipped },
      { name: 'Phases', expected: 2, actual: result.phases ? result.phases.length : 0 },
      { name: 'Goals', expected: 3, actual: result.goals ? result.goals.length : 0 },
      { name: 'Tech Stack', expected: 3, actual: result.tech_stack ? result.tech_stack.length : 0 }
    ];

    let passed = 0;
    let failed = 0;

    checks.forEach(check => {
      const match = check.actual === check.expected;
      const status = match ? '✅' : '❌';
      console.log(`${status} ${check.name}: Expected ${check.expected}, Got ${check.actual}`);
      if (match) passed++;
      else failed++;
    });

    console.log(`\n📈 Test Results: ${passed}/${checks.length} passed`);

    if (failed === 0) {
      console.log('\n🎉 All tests passed! PRD Analyzer is working correctly.');
      process.exit(0);
    } else {
      console.log(`\n⚠️  ${failed} test(s) failed. Review the output above.`);
      process.exit(1);
    }

  } catch (error) {
    console.error('❌ Test failed with error:');
    console.error(error.message);
    console.error('\nMake sure:');
    console.error('1. n8n is running on localhost:5678');
    console.error('2. PRD Analyzer workflow is imported and active');
    console.error('3. PRD Analyzer Test Wrapper workflow is imported and active');
    process.exit(1);
  }
}

// Run the test
testPrdAnalyzer();
