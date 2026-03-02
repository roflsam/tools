---
name: expenses-receipts
description: >
  Process local receipt files from the receipts/ folder and add them as expense rows
  to the "Example of Expenses" Google Sheet for the 11 North Milton rental property.
  Use this skill whenever Sam wants to process receipt files, add expenses from local files,
  or update the expense tracker with files from the receipts folder.
  Trigger on prompts like "process my receipts", "add the receipts to the sheet",
  "I have new receipts", "catch up the expense spreadsheet", "process the files in receipts/",
  or any mention of processing local receipt files or adding them to the expense tracker.
  Do NOT trigger for email-based receipts — use the expenses-gmail skill for that.
---

# 11 North Milton — Local Receipts → Expense Sheet

Reads receipt files from the `receipt_processor/receipts/` folder, parses them
into expense rows using Claude vision, and appends the rows to the appropriate year's tab
of the Example of Expenses spreadsheet.

**Before doing anything else**, read `.claude/skills/references/shared-rules.md` — it has
the column schema, formatting rules, categories, cost rules, and validation checks that
apply to every step below.

---

## Step 0: Find where to append

Read column A of the target year's tab to find the first empty row:

```
mcp__workspace-mcp__read_sheet_values
  spreadsheet_id: 1CWbvEAXwOAL9It6xMTRrHmfEJVPyi71TFWjdNEBXUns
  range_name: <year>!A1:A900
```

The first empty cell in column A is your starting row.

---

## Step 1: Find receipt files to process

Glob for all files in the `receipt_processor/receipts/` directory:

```
Glob  pattern: receipt_processor/receipts/**/*
```

Collect the list of files (skip `.DS_Store` and other hidden files). Common formats: `.pdf`, `.jpg`, `.jpeg`, `.png`, `.webp`, `.heic`.
Show Sam the count and file names before processing, or proceed directly if he already said to.

If the folder is empty or doesn't exist, tell Sam and stop.

---

## Step 2: Parallel file processing

For larger batches (8+ files), split into groups of ~6 and spawn one subagent per group.
Launch **all subagents in the same turn**.

For fewer than 8 files, process inline.

Two reasons parallel processing matters:
- **Speed** — all batches run in parallel instead of sequentially
- **Context window** — full file contents (especially PDFs) are verbose. Subagents absorb raw
  content and return only compact parsed rows, keeping the main context clean.

### Setting up

```
TeamCreate  team_name: "receipt-processor"
```

### Each subagent's prompt

Give every subagent:
- Its batch of file paths
- **The cost rule from shared-rules.md (state this FIRST and prominently)**
- The column schema and formatting rules from shared-rules.md
- The category guide from shared-rules.md
- The one-row-per-order rule and flag-instead-of-skip rule
- Instructions: "Use the Read tool to read each file — it passes PDFs and images directly
  to Claude's vision model, which will extract the text. For each file, extract the expense
  details from the visual content. Use the exact filename as the Receipt column value.
  Return tab-separated rows (no header), then SendMessage to team-lead."

After all subagents report back, send shutdown requests and call `TeamDelete`.

---

## Step 3: Aggregate and sort

1. Combine rows from all subagents
2. Sort chronologically by date (oldest first)
3. Check for duplicates: same date + vendor + amount

---

## Step 4: Validate, write, verify, and report

Follow the pre-write validation, writing, post-write verification, and summary report
steps from `shared-rules.md`.

Summary report should include:
1. **Files processed** — list of filenames
2. **Rows written** and range (e.g. "5 rows, rows 178–182")
3. **Flagged items** — a table: row # | date | item | flag reason
4. **Excluded items** — anything omitted and why
