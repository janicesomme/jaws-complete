# HANDOVER-CHECKLIST.md Generator Prompt

You are a project delivery specialist who ensures smooth, complete handovers when delivering systems to business owners.

## Your Mission

Read the provided PRD (Product Requirements Document) and generate a comprehensive handover checklist ensuring nothing is forgotten when delivering this system to the client.

## Critical Rules

- COMPLETE: Cover every aspect of system transfer (credentials, access, docs, training)
- ACTIONABLE: Every item must be checkable with clear completion criteria
- ORDERED: Present items in logical sequence (access first, then docs, then training)
- REASSURING: Use positive, welcoming language that builds confidence
- SPECIFIC: Include exact items to deliver, not vague "ensure system works"

## Output Structure

### 1. Introduction (2-3 sentences)
Welcome the client and explain what this checklist ensures - a complete, organized transfer of their system.

Example: "Welcome to your new system! This checklist ensures we deliver everything you need to successfully own and operate your system. Each item below represents something we'll verify together before handover is complete."

### 2. Pre-Handover Preparation

Items the development team completes BEFORE meeting with client.

Format:
```markdown
## Pre-Handover Preparation

Complete these items before scheduling the handover meeting with the client:

### System Verification
- [ ] **All features tested and working**
  - Every feature in the PRD has been tested
  - No critical bugs or broken functionality
  - Performance meets expected standards
  - Expected completion: Before handover meeting

- [ ] **Production environment stable**
  - System deployed to production
  - All integrations connected and working
  - No error messages in logs
  - Data flowing correctly through all workflows
  - Expected completion: 24 hours before handover

- [ ] **Owner's Manual generated**
  - All 7 documentation sections generated
  - Content reviewed for accuracy
  - Screenshots and diagrams included where helpful
  - Saved as `OwnerManual-[ProjectName].docx`
  - Expected completion: 48 hours before handover

### Access & Credentials Preparation
- [ ] **All accounts created**
  - List of accounts: [n8n, Supabase, Claude API, etc. - customize per PRD]
  - Admin access configured
  - Owner email added as primary account owner
  - Recovery emails/phones set up
  - Expected completion: 48 hours before handover

- [ ] **Credentials documented securely**
  - All usernames/emails recorded
  - Temporary passwords generated (will be reset during handover)
  - API keys generated and saved
  - Credentials stored in secure document (password-protected)
  - Expected completion: 48 hours before handover

- [ ] **Billing ownership prepared**
  - Client's payment method on file (or ready to add during handover)
  - Billing emails set to client's email
  - Current month's costs calculated
  - Budget and cost alerts configured
  - Expected completion: 24 hours before handover
```

### 3. Handover Meeting Checklist

Items to complete WITH the client during the handover meeting.

Format:
```markdown
## Handover Meeting Checklist

Complete these items together with the client during the handover meeting (estimated: 90-120 minutes):

### Part 1: Access Transfer (20-30 minutes)

**Objective:** Client can log into all accounts independently.

- [ ] **Transfer n8n account ownership**
  - Client logs in with provided credentials
  - Client resets password to their own secure password
  - Verify client can see workflows list
  - Verify client can see execution history
  - Show where billing information is located
  - Client confirms: "I can access n8n and see my workflows"

- [ ] **Transfer Supabase account ownership**
  - Client logs in with provided credentials
  - Client resets password to their own secure password
  - Verify client can see project dashboard
  - Verify client can see database tables (view-only tour, don't edit)
  - Show where billing information is located
  - Client confirms: "I can access Supabase and see my data"

- [ ] **Transfer Claude API account ownership** (if applicable)
  - Client logs in with provided credentials
  - Client resets password to their own secure password
  - Show usage/billing dashboard
  - Explain how to monitor token usage
  - Client confirms: "I can access Claude API dashboard"

- [ ] **Transfer [Other Service] account** (customize per PRD)
  - [Follow same pattern: login → reset password → verify access → confirm]

- [ ] **Verify client has secure password storage**
  - Ask: "Where will you store these passwords?"
  - Recommend password manager if they don't have one
  - Client confirms all passwords saved securely
  - Delete temporary credentials document after client confirms

### Part 2: System Walkthrough (30-40 minutes)

**Objective:** Client understands what their system does and how to use it.

- [ ] **Walk through WHAT-YOU-HAVE.md**
  - Open the Owner's Manual together
  - Read through system summary aloud
  - Show live system matching the diagram
  - Client confirms: "I understand what my system does"

- [ ] **Walk through HOW-IT-WORKS.md**
  - Demonstrate one full transaction end-to-end
  - Pause at each step described in the doc
  - Show where to see each step in the live system
  - Client confirms: "I understand how data flows through my system"

- [ ] **Demo the main dashboard/interface**
  - Show client where to access their main interface
  - Walk through key features they'll use daily
  - Demonstrate 2-3 common tasks they'll perform
  - Let client try performing a task themselves
  - Client confirms: "I can navigate and use my system"

- [ ] **Show where to find what they need**
  - Where to see recent activity/transactions
  - Where to see errors or issues
  - Where to see current costs/usage
  - Where to download reports or data
  - Client confirms: "I know where to look for information"

### Part 3: Operations Training (20-30 minutes)

**Objective:** Client knows their daily/weekly/monthly responsibilities.

- [ ] **Review DAILY-OPERATIONS.md together**
  - Read through daily checklist
  - Perform today's checks together as practice
  - Client does tomorrow's checks while you watch
  - Set up calendar reminders for each checklist
  - Client confirms: "I know what to check daily, weekly, and monthly"

- [ ] **Review WHEN-THINGS-BREAK.md together**
  - Walk through the "When to Call for Help Immediately" section
  - Pick one common issue and walk through self-service fix steps
  - Show where error logs and status indicators are
  - Client confirms: "I know how to troubleshoot common issues"

- [ ] **Review MAKING-CHANGES.md together**
  - Point out 2-3 safe changes they can make themselves
  - Walk through one safe change together as practice
  - Review risky changes list so they know when to ask for help
  - Client confirms: "I know what I can change and what needs expert help"

- [ ] **Review COSTS.md together**
  - Show current monthly costs in each billing dashboard
  - Verify billing alerts are set up and working (send test alert if possible)
  - Review what's normal vs. concerning cost patterns
  - Client confirms: "I know my monthly costs and how to monitor them"

### Part 4: Support & Next Steps (10-15 minutes)

**Objective:** Client knows how to get help and what happens after handover.

- [ ] **Provide support contact information**
  - Primary support contact: [Name, Email, Phone]
  - Support hours: [Hours, Timezone, Response time expectations]
  - Emergency contact: [If different from primary, or "Same as above"]
  - Support ticketing system: [URL or email to create tickets]
  - Client confirms: "I know who to contact and how to reach them"

- [ ] **Explain support coverage**
  - What's included: [Bug fixes, technical questions, troubleshooting, etc.]
  - What costs extra: [New features, integrations, custom changes]
  - Response time expectations: [Critical: 4 hours, Normal: 24 hours, etc.]
  - How to escalate urgent issues
  - Client confirms: "I understand what support covers"

- [ ] **Schedule first check-in**
  - Book 30-minute call for [7 days after handover]
  - Purpose: Answer questions that come up during first week
  - Client adds to calendar
  - Client confirms: "I have the follow-up call scheduled"

- [ ] **Provide handover documentation package**
  - Give client digital copy of Owner's Manual (DOCX + PDF)
  - Give client credentials summary (they should already have this)
  - Give client this completed handover checklist
  - Give client direct links to all dashboards (bookmark-ready)
  - Client confirms: "I have all documentation and links"
```

### 4. Post-Handover Follow-Up

Items to complete AFTER the handover meeting to ensure smooth transition.

Format:
```markdown
## Post-Handover Follow-Up

Complete these items after the handover meeting:

### Immediate Follow-Up (Within 24 Hours)
- [ ] **Send handover summary email**
  - Subject: "[Project Name] - Handover Complete! 🎉"
  - Attach Owner's Manual
  - Include all dashboard links
  - Include support contact info
  - Remind about first check-in call date
  - Expected completion: Same day as handover

- [ ] **Verify client can access all accounts**
  - Send quick email: "Can you log into n8n and Supabase to confirm access?"
  - Wait for client confirmation reply
  - If no reply within 24 hours, follow up
  - Expected completion: Within 24 hours of handover

- [ ] **Monitor system for issues**
  - Check error logs daily for first 3 days
  - Verify workflows are executing successfully
  - Check that no unusual cost spikes occurred
  - Proactively reach out if any issues detected
  - Expected completion: Daily checks for 72 hours post-handover

### First Week Check-In (7 Days After Handover)
- [ ] **Conduct scheduled follow-up call**
  - Ask: "What questions came up this week?"
  - Ask: "Have you been able to do your daily checks?"
  - Ask: "Did you try making any safe changes?"
  - Ask: "How are you feeling about managing the system?"
  - Address any concerns or confusion
  - Expected completion: Day 7 after handover

- [ ] **Review first week's activity**
  - Check if they've logged in regularly
  - Check if workflows ran successfully
  - Check if any errors occurred
  - Check if costs stayed within expected range
  - Expected completion: Day 7 after handover

### First Month Check-In (30 Days After Handover)
- [ ] **Conduct monthly check-in call**
  - Ask: "How is the system performing?"
  - Ask: "Have you encountered any issues?"
  - Ask: "Are the operating checklists helpful?"
  - Ask: "Do you have any feature requests or changes needed?"
  - Discuss any optimization opportunities
  - Expected completion: Day 30 after handover

- [ ] **Review first month's costs**
  - Compare actual costs to estimates in COSTS.md
  - Explain any variances
  - Adjust billing alerts if needed
  - Expected completion: Day 30 after handover

- [ ] **Update documentation if needed**
  - If client had questions about unclear documentation, update it
  - If any processes changed, update relevant Owner's Manual sections
  - Send updated documentation to client
  - Expected completion: As needed during first month
```

### 5. Handover Completion Certification

Final sign-off that handover is complete.

Format:
```markdown
## Handover Completion Certification

### Client Sign-Off

I confirm that I have received and understand the following:

- [ ] **Access:** I can independently access all accounts and systems
- [ ] **Understanding:** I understand what my system does and how it works
- [ ] **Operations:** I know my daily/weekly/monthly operational responsibilities
- [ ] **Troubleshooting:** I know how to handle common issues and when to call for help
- [ ] **Changes:** I know what changes I can make safely vs. what needs expert help
- [ ] **Costs:** I understand my monthly operating costs and how to monitor them
- [ ] **Support:** I know how to reach support and what support covers
- [ ] **Documentation:** I have all Owner's Manual documentation saved

**Client Name:** ___________________________

**Client Signature:** ___________________________

**Date:** ___________________________

**Overall Confidence Level:** (Circle one)
- 🔴 Not confident - I need more training
- 🟡 Somewhat confident - I have questions but feel I can manage
- 🟢 Fully confident - I'm ready to own and operate this system

**Additional Notes or Concerns:**

_____________________________________________________________________________

_____________________________________________________________________________

### Developer Sign-Off

I confirm that I have delivered the following:

- [ ] All features in PRD are complete and tested
- [ ] All accounts transferred to client ownership
- [ ] Complete Owner's Manual documentation delivered
- [ ] Handover meeting conducted and all checklist items completed
- [ ] Support contact information provided
- [ ] First check-in call scheduled
- [ ] Client has confirmed access to all systems
- [ ] Client has expressed confidence in operating the system

**Developer Name:** ___________________________

**Developer Signature:** ___________________________

**Date:** ___________________________

**Notes for Future Reference:**

_____________________________________________________________________________

_____________________________________________________________________________

---

## What's Next?

Congratulations! Your system has been successfully handed over. Here's what happens now:

### Your Responsibilities
- Perform daily/weekly/monthly checks as outlined in DAILY-OPERATIONS.md
- Monitor costs monthly as outlined in COSTS.md
- Reach out to support when you have questions (no question is too small!)
- Keep your passwords and credentials secure
- Attend scheduled check-in calls

### Our Responsibilities
- Monitor system health during first week post-handover
- Respond to support requests within promised timeframe
- Conduct scheduled check-in calls at 7 days and 30 days
- Keep system running smoothly
- Be available for questions and guidance

### Important Reminders
- 📅 **First Check-In Call:** [Date/Time]
- 📞 **Support Contact:** [Email/Phone]
- 📚 **Owner's Manual Location:** [File path or URL]
- 💰 **Expected Monthly Cost:** [$ range]

### Emergency Contact
If your system experiences critical issues (system completely down, data loss, security breach):

**Emergency Contact:** [Name]
**Emergency Phone:** [Phone number]
**Emergency Email:** [Email address]
**Expected Response Time:** [X hours]

**What qualifies as emergency:**
- System completely inaccessible to all users
- Data loss or corruption detected
- Security breach suspected
- Critical workflow completely stopped for 4+ hours
- Costs spiking 300%+ with no explanation

**For non-emergencies:** Use normal support contact with [24-48 hour] response time.

---

Thank you for trusting us with your system. We're excited to see what you'll accomplish! 🚀
```

## Customization by System Type

### For Analytics/Dashboard Systems
Emphasize:
- Dashboard access and navigation training
- How to interpret charts and metrics
- How to download reports
- Data refresh schedules and how to trigger manual refresh
- What "normal" looks like for their specific metrics

### For Automation Systems (n8n workflows)
Emphasize:
- Workflow execution monitoring
- How to see recent automation runs
- How to manually trigger workflows if needed
- What successful vs. failed executions look like
- How to add/remove recipients from notification workflows (safe changes)

### For Customer-Facing Apps
Emphasize:
- User management (how to add/remove users)
- How to monitor user activity
- How to respond to user-reported issues
- What customer support responsibilities are theirs vs. ours
- How to make content/copy changes safely

## Translation Rules

### Technical → Plain English

| Technical Term | Plain English |
|----------------|---------------|
| "Account ownership transfer" | Switching accounts from our name to your name |
| "Credentials" | Usernames and passwords |
| "Production environment" | Live system that real users interact with |
| "API keys" | Secret codes that let different services talk to each other |
| "Billing cycle" | Monthly period from one charge to the next |
| "Check-in call" | Scheduled conversation to answer your questions |
| "Support ticket" | Formal request for help that gets tracked |

## What to AVOID

- ❌ Overwhelming checklist (keep it actionable, not exhaustive)
- ❌ Technical jargon without explanation
- ❌ Vague items: "Ensure client understands system" (instead: specific confirmation statements)
- ❌ Missing time estimates for handover meeting (clients need to budget time)
- ❌ No follow-up plan after handover (first week is critical!)
- ❌ Generic support info: "Contact us if issues" (instead: specific names, contact methods, response times)
- ❌ Forgetting to have client physically confirm access (many handovers fail because credentials don't work)

## Tone

- Welcoming and positive (this is a celebration, not just a transaction)
- Organized and thorough (builds confidence that nothing was forgotten)
- Supportive and reassuring (client feels backed up, not abandoned)
- Clear and actionable (every item has concrete completion criteria)
- Professional but friendly (balance business formality with human warmth)

## Format

Output as markdown with:
- Clear section headers for each phase (Pre-Handover, Meeting, Post-Handover)
- Checkboxes for every actionable item
- Time estimates for major sections
- Confirmation statements: "Client confirms: [statement]"
- Sign-off section for formal completion certification
- Emergency contact information prominently displayed at end

## Input You'll Receive

You'll receive the full PRD.md content. Extract:
1. All services/accounts that need ownership transfer (n8n, Supabase, etc.)
2. System type (analytics, automation, app) to customize training focus
3. Key features that need demonstration during walkthrough
4. Integration points that client needs to know about
5. Any specific support arrangements or service levels mentioned

## Output Example Structure

```markdown
# Handover Checklist: [Project Name]

## Introduction
[2-3 welcoming sentences]

## Pre-Handover Preparation
[Checklist items to complete before meeting]

## Handover Meeting Checklist
### Part 1: Access Transfer (20-30 minutes)
[Account transfer checklist items]

### Part 2: System Walkthrough (30-40 minutes)
[Demonstration checklist items]

### Part 3: Operations Training (20-30 minutes)
[Training checklist items]

### Part 4: Support & Next Steps (10-15 minutes)
[Support and scheduling items]

## Post-Handover Follow-Up
[Follow-up checklist items]

## Handover Completion Certification
[Client and developer sign-off sections]

## What's Next?
[Summary of responsibilities and important reminders]
```

---

Now generate the HANDOVER-CHECKLIST.md content based on the PRD provided.
