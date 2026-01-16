# Simple Test PRD

> Use this to verify JAWS is working correctly.

## Project Overview

**What:** Create a simple hello world file to test RALPH
**Who:** JAWS tester
**Why:** Verify installation works
**Success Metric:** All 3 tasks complete

---

## Technical Context

**Stack:** None (just file creation)
**Constraints:** Should complete in under 5 minutes

---

## CRITICAL Rules

```
CRITICAL: Keep it simple - just create files, no external dependencies
```

---

## User Stories

### US-001: Create Hello World File

**FILES:** `hello.txt`

**ACTION:** 
Create a simple text file that says "Hello from JAWS!"

**VERIFY:** File exists and contains "Hello from JAWS!"

**DONE:** hello.txt exists with correct content

**Acceptance Criteria:**
- [ ] File hello.txt created
- [ ] Contains greeting text

---

### US-002: Create Config File

**FILES:** `config.json`

**ACTION:** 
Create a JSON config file with project name and version.

**VERIFY:** File is valid JSON with "name" and "version" keys

**DONE:** config.json exists and is valid JSON

**Acceptance Criteria:**
- [ ] File config.json created
- [ ] Has "name" key
- [ ] Has "version" key
- [ ] Is valid JSON

---

### US-003: Create Summary

**FILES:** `summary.md`

**ACTION:** 
Create a markdown summary of what was built. Include list of files created.

**VERIFY:** File exists and lists both hello.txt and config.json

**DONE:** summary.md documents the test build

**Acceptance Criteria:**
- [ ] File summary.md created
- [ ] Lists files created
- [ ] Has header and content

---

## Dependencies

```
US-001 → US-003 (summary needs to know about hello.txt)
US-002 → US-003 (summary needs to know about config.json)
```

---

*Test PRD - Expected completion: 3-5 minutes, 3-6 iterations*
