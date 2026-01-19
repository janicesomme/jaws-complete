# Plan Guardian Prompts

**Copy-paste these into a FRESH Claude Code terminal for quality verification.**

---

## After Phase 1 (Foundation)

```
Read PRD.md. Phase 1 (Foundation) just completed in another session.

Verify against the PRD:
1. Is the database schema created and accessible?
2. Does authentication work (login/logout/signup)?
3. Are all environment variables configured?
4. Are all US-301 acceptance criteria actually complete?

Run any verification commands from the VERIFY field.
Report any issues or gaps before we start parallel work.
```

---

## After Parallel Phase (e.g., Phase 2)

```
Read PRD.md. Phase 2 features were built in parallel worktrees.

Tasks completed: US-302, US-303, US-304

Verify against the PRD:
1. Are ALL acceptance criteria for these tasks actually complete?
2. Do the VERIFY checks pass when you run them?
3. Are there any conflicts or inconsistencies between the parallel builds?
4. Is anything missing that Phase 3 (integration) will need?

Be thorough. Check actual code/workflows, not just checkboxes.
List any issues found.
```

---

## Before Integration

```
Read PRD.md and DECISIONS.md.

We're about to start integration (Phase 3). 

Verify:
1. All Phase 2 features are complete and working independently
2. No conflicting implementations between features
3. All dependencies for US-305 are satisfied
4. DECISIONS.md captures any deviations from the original plan

What potential integration issues should we watch for?
```

---

## Final Verification (Before Deployment)

```
Read PRD.md. All phases are marked complete.

Final verification checklist:
1. Run through ALL acceptance criteria - are they actually met?
2. Execute ALL VERIFY commands - do they pass?
3. Test the happy path end-to-end
4. Check for any TODO comments or incomplete work
5. Verify documentation matches implementation

This is the last quality gate. Be thorough.
Report: Ready for production? If not, what's missing?
```

---

## After Any Task Completion

```
Read PRD.md. Task [US-XXX] was just completed in another session.

Verify:
1. All acceptance criteria for [US-XXX] are checked and actually working
2. The VERIFY check passes: [paste VERIFY command]
3. The DONE criteria is met: [paste DONE criteria]
4. No unintended changes to other parts of the system

Report any issues.
```

---

## Parallel Work-In-Progress Check

```
Read PRD.md. We have [N] parallel sessions working on:
- US-302 in worktree A
- US-303 in worktree B  
- US-304 in worktree C

None have completed yet. 

Check the main branch and DECISIONS.md:
1. Is the foundation still intact?
2. Are there any shared concerns the parallel sessions should know about?
3. Any coordination needed before they merge?
```

---

## Troubleshooting Prompt

```
Read PRD.md and check the codebase.

Something isn't working as expected. Help me diagnose:

Symptom: [Describe what's wrong]

Expected: [What should happen]

Actual: [What's actually happening]

Check:
1. Is the related acceptance criterion marked complete?
2. Does the implementation match what the PRD specifies?
3. Are there any DECISIONS.md entries that explain a deviation?
4. What's the most likely cause?
```

---

## Usage Tips

1. **Always use a FRESH terminal** - The whole point is virgin context
2. **Don't implement fixes in the Guardian session** - Just diagnose and report
3. **Be specific** - Replace [US-XXX] and [placeholders] with actual values
4. **Trust the Guardian** - If it finds issues, address them before proceeding
5. **Document findings** - Add significant discoveries to DECISIONS.md

---

*Part of JAWS Parallel Enhancement v1.0*
