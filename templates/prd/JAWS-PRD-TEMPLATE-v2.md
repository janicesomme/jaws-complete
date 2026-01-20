# [Project Name] - Product Requirements Document

**Version:** 1.1  
**Created:** [Date]  
**Last Updated:** [Date]  
**Build ID:** US-301 through US-XXX  
**Has UI:** Yes / No ← RALPH uses this for automatic browser validation

---

## Project Overview

[2-3 sentences describing what you're building and why. This context helps Claude understand the goal even in fresh sessions.]

**Target Outcome:** [What success looks like]

**Key Constraints:**
- [Constraint 1]
- [Constraint 2]
- [Constraint 3]

---

## Dependency Map

Visual representation of task dependencies:

```
Phase 1: Foundation
──────────────────────────────────────────────────────────────
[US-301] Database/Auth Setup
    │
    ▼
Phase 2: Core Features (PARALLEL-READY after US-301)
──────────────────────────────────────────────────────────────
    ├──► [US-302] Feature A ──┐
    │                         │
    ├──► [US-303] Feature B ──┼──► Phase 3
    │                         │
    └──► [US-304] Feature C ──┘
                              │
                              ▼
Phase 3: Integration
──────────────────────────────────────────────────────────────
                        [US-305] Connect Everything
                              │
                              ▼
Phase 4: Polish
──────────────────────────────────────────────────────────────
                        [US-306] Testing & Docs
```

---

## Guardian Checkpoints

Quality gates requiring fresh-context verification:

- [ ] **After Phase 1:** Verify foundation before parallel work begins
- [ ] **After Phase 2:** Verify all parallel features before integration
- [ ] **After Phase 3:** Verify integration before polish
- [ ] **After Phase 4:** Final verification before deployment

---

## Phase 1: Foundation

*Must complete before any parallel work*

### US-301: [Foundation Task Name]

**TYPE:** Backend
**DEPENDS ON:** None (this is the foundation)  
**PARALLEL WITH:** None  
**BLOCKS:** US-302, US-303, US-304

**FILES:** `schema.sql`, `auth/`, `config/`  
**VERIFY:** `npm run test:foundation` OR manual verification steps  
**DONE:** Database accessible, auth working, environment configured

**Acceptance Criteria:**
- [ ] Database schema created and migrated
- [ ] Authentication system functional (login/logout/signup)
- [ ] Environment variables configured
- [ ] Base API structure in place

**Notes for Next Phase:**
- [Anything the next session needs to know]

---

## Phase 2: Core Features

*These tasks can run in PARALLEL after US-301 completes*

### US-302: [Feature A Name]

**TYPE:** UI / Backend / Both ← RALPH auto-validates UI types with browser
**DEPENDS ON:** US-301 (foundation must be complete)  
**PARALLEL WITH:** US-303, US-304  
**BLOCKS:** US-305

**FILES:** `src/features/featureA/`, `components/FeatureA.jsx`  
**VERIFY:** [Specific test or verification command]  
**DONE:** [Clear statement of what "done" looks like]

**Acceptance Criteria:**
- [ ] Criterion 1 with specific, verifiable outcome
- [ ] Criterion 2 with specific, verifiable outcome
- [ ] Criterion 3 with specific, verifiable outcome

---

### US-303: [Feature B Name]

**TYPE:** UI / Backend / Both
**DEPENDS ON:** US-301 (foundation must be complete)  
**PARALLEL WITH:** US-302, US-304  
**BLOCKS:** US-305

**FILES:** `src/features/featureB/`, `components/FeatureB.jsx`  
**VERIFY:** [Specific test or verification command]  
**DONE:** [Clear statement of what "done" looks like]

**Acceptance Criteria:**
- [ ] Criterion 1 with specific, verifiable outcome
- [ ] Criterion 2 with specific, verifiable outcome
- [ ] Criterion 3 with specific, verifiable outcome

---

### US-304: [Feature C Name]

**TYPE:** UI / Backend / Both
**DEPENDS ON:** US-301 (foundation must be complete)  
**PARALLEL WITH:** US-302, US-303  
**BLOCKS:** US-305

**FILES:** `src/features/featureC/`, `components/FeatureC.jsx`  
**VERIFY:** [Specific test or verification command]  
**DONE:** [Clear statement of what "done" looks like]

**Acceptance Criteria:**
- [ ] Criterion 1 with specific, verifiable outcome
- [ ] Criterion 2 with specific, verifiable outcome
- [ ] Criterion 3 with specific, verifiable outcome

---

## Phase 3: Integration

*Sequential - requires all Phase 2 features complete*

### US-305: [Integration Task Name]

**TYPE:** Both
**DEPENDS ON:** US-302, US-303, US-304 (all features must be complete)  
**PARALLEL WITH:** None  
**BLOCKS:** US-306

**FILES:** `src/integration/`, `config/routes.js`  
**VERIFY:** [End-to-end test or verification command]  
**DONE:** [Clear statement of what "done" looks like]

**Acceptance Criteria:**
- [ ] All features connected and working together
- [ ] Data flows correctly between components
- [ ] No regression in individual features
- [ ] Error handling covers integration points

---

## Phase 4: Polish

*Final phase - testing, documentation, deployment prep*

### US-306: [Polish Task Name]

**TYPE:** Backend
**DEPENDS ON:** US-305 (integration must be complete)  
**PARALLEL WITH:** None  
**BLOCKS:** None (final task)

**FILES:** `docs/`, `tests/`, `README.md`  
**VERIFY:** Full test suite passes, docs reviewed  
**DONE:** Ready for production deployment

**Acceptance Criteria:**
- [ ] All automated tests passing
- [ ] Documentation complete
- [ ] Deployment checklist verified
- [ ] Client review/approval obtained

---

## Test Summary

| Level | Tests | Status |
|-------|-------|--------|
| 1 - Smoke | Foundation health checks | ⬜ Pending |
| 2 - Functional | Acceptance criteria verification | ⬜ Pending |
| 3 - Edge Cases | Error handling verification | ⬜ Pending |

---

## Parallel Execution Guide

### When to use parallel worktrees:

✅ **Do use parallel when:**
- Phase 2+ tasks are marked `PARALLEL WITH` each other
- Foundation (Phase 1) is complete and verified
- Tasks don't share the same files

❌ **Don't use parallel when:**
- Tasks have incomplete `DEPENDS ON` requirements
- Tasks modify the same files
- You're in Phase 1 (foundation)

### Parallel session prompts:

After Phase 1 completes, generate prompts for each parallel task:

```
You are working on [US-XXX] in a PARALLEL worktree.

Other sessions are building: [list other parallel tasks]

DO NOT modify:
- Database schema
- Auth system  
- Files outside your task scope

YOUR FILES: [list from FILES field]

Read PRD.md, implement your task, mark criteria complete.
```

---

## Session Handoff Notes

### Phase 1 Completion
- **Completed by:** [Session ID/Date]
- **Key decisions:** [See DECISIONS.md]
- **Notes for Phase 2:** [What parallel sessions need to know]

### Phase 2 Completion
- **Completed by:** [Session IDs/Dates]
- **Key decisions:** [See DECISIONS.md]
- **Notes for Phase 3:** [What integration session needs to know]

### Phase 3 Completion
- **Completed by:** [Session ID/Date]
- **Key decisions:** [See DECISIONS.md]
- **Notes for Phase 4:** [What polish session needs to know]

---

*Generated for JAWS with Parallel Enhancement v1.0*
