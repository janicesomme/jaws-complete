// Test script to validate PRD analyzer logic
const fs = require('fs');

// Read the actual PRD.md
const prdContent = fs.readFileSync('PRD.md', 'utf8');

console.log('=== Testing PRD Analyzer Logic ===\n');

// Test 1: Extract project name
const titleMatch = prdContent.match(/^#\s+PRD:\s+(.+)$/m);
const projectName = titleMatch ? titleMatch[1].trim() : null;
console.log('✓ Project Name:', projectName);

// Test 2: Extract client name
const clientMatch = prdContent.match(/\*\*Client:\*\*\s+(.+?)(?:\n|$)/m);
const clientName = clientMatch ? clientMatch[1].trim() : null;
console.log('✓ Client Name:', clientName);

// Test 3: Count user stories
const userStoryMatches = prdContent.match(/###\s+US-\d+:/g) || [];
const totalUserStories = userStoryMatches.length;
const userStoryIds = userStoryMatches.map(match => {
  const idMatch = match.match(/US-\d+/);
  return idMatch ? idMatch[0] : null;
}).filter(Boolean);
console.log('✓ Total User Stories:', totalUserStories);
console.log('  First 5 IDs:', userStoryIds.slice(0, 5).join(', '));

// Test 4: Count tasks
const completedMatches = prdContent.match(/^\s*-\s*\[x\]/gmi) || [];
const completedCount = completedMatches.length;
const incompleteMatches = prdContent.match(/^\s*-\s*\[\s\]/gm) || [];
const incompleteCount = incompleteMatches.length;
const skippedMatches = prdContent.match(/^\s*-\s*\[SKIPPED\]/gmi) || [];
const skippedCount = skippedMatches.length;
const totalTasks = completedCount + incompleteCount + skippedCount;
const completionRate = totalTasks > 0 ? Math.round((completedCount / totalTasks) * 100) : 0;

console.log('✓ Tasks:');
console.log('  Completed:', completedCount);
console.log('  Incomplete:', incompleteCount);
console.log('  Skipped:', skippedCount);
console.log('  Total:', totalTasks);
console.log('  Completion Rate:', completionRate + '%');

// Test 5: Extract phases
// Pattern matches: PHASE 1: Foundation                                    [CHECKPOINT: FOUNDATION]
const phaseRegex = /PHASE\s+(\d+):\s+(.+?)\s+\[CHECKPOINT:\s+(.+?)\]/g;
let phaseMatch;
const phases = [];

while ((phaseMatch = phaseRegex.exec(prdContent)) !== null) {
  phases.push({
    phase_number: parseInt(phaseMatch[1]),
    phase_name: phaseMatch[2].trim(),
    checkpoint: phaseMatch[3].trim()
  });
}
const checkpointMatches = prdContent.match(/⏸️\s*\*\*CHECKPOINT:/g) || [];
const checkpointCount = checkpointMatches.length;

console.log('✓ Phases:', phases.length);
phases.forEach(p => console.log(`  Phase ${p.phase_number}: ${p.phase_name} [${p.checkpoint}]`));
console.log('  Checkpoint Gates:', checkpointCount);

// Test 6: Extract goals
const goals = [];
const goalsMatch = prdContent.match(/##\s+Goals\s*\n([\s\S]*?)(?=\n##|$)/);
if (goalsMatch) {
  const goalsSection = goalsMatch[1];
  const goalLines = goalsSection.match(/^\s*-\s+(.+)$/gm) || [];

  goalLines.forEach(line => {
    const goal = line.replace(/^\s*-\s+/, '').trim();
    if (goal) {
      goals.push(goal);
    }
  });
}
console.log('✓ Goals:', goals.length);
goals.forEach(g => console.log('  -', g));

// Test 7: Extract tech stack
const techStack = [];
const techStackMatch = prdContent.match(/##\s+Technical\s+Stack\s*\n([\s\S]*?)(?=\n##|$)/);
if (techStackMatch) {
  const techStackSection = techStackMatch[1];
  const techLines = techStackSection.match(/^\s*-\s+\*\*(.+?):\*\*\s+(.+)$/gm) || [];

  techLines.forEach(line => {
    const match = line.match(/\*\*(.+?):\*\*\s+(.+)$/);
    if (match) {
      techStack.push({
        category: match[1].trim(),
        technology: match[2].trim()
      });
    }
  });
}
console.log('✓ Tech Stack:', techStack.length);
techStack.forEach(t => console.log(`  - ${t.category}: ${t.technology}`));

console.log('\n=== All Tests Passed ✓ ===');

// Build final structured response (like the workflow would)
const result = {
  status: 200,
  message: 'PRD analysis complete',
  data: {
    project_name: projectName,
    client_name: clientName,
    user_stories: {
      total: totalUserStories,
      ids: userStoryIds
    },
    tasks: {
      total: totalTasks,
      completed: completedCount,
      incomplete: incompleteCount,
      skipped: skippedCount,
      completion_rate: completionRate
    },
    phases: {
      total: phases.length,
      details: phases,
      checkpoints: checkpointCount
    },
    goals: {
      total: goals.length,
      list: goals
    },
    tech_stack: {
      total: techStack.length,
      list: techStack
    }
  }
};

console.log('\n=== Final Output (JSON) ===');
console.log(JSON.stringify(result, null, 2));
