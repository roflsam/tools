---
name: expenses-gmail
description: >
  Process unread receipt emails from 11northmilton@gmail.com and add them as expense rows
  to the "Example of Expenses" Google Sheet for the 11 North Milton rental property.
  Use this skill whenever Sam wants to process new receipts, add expenses from emails,
  catch up on unread receipt emails, or update the expense tracker with recent purchases.
  Trigger on prompts like "process my receipt emails", "add the new emails to the sheet",
  "I have new expense emails", "catch up the expense spreadsheet from emails", or any mention of
  adding receipt or order EMAILS to the expense tracker. Do NOT trigger for local receipt files
  in a receipts/ folder — use the expenses-receipts skill for that.
---

# 11 North Milton — Receipt Emails → Expense Sheet

Reads unread receipt emails from `11northmilton@gmail.com`, parses them into expense rows,
and appends them to the appropriate year's tab in the Example of Expenses spreadsheet.

**Before doing anything else**, read `.claude/skills/references/shared-rules.md` — it has
the column schema, formatting rules, categories, cost rules, and validation checks that
apply to every step below.

---

## Step 0: Find where to append

Read column A of the target year's tab to find the first empty row:

```
mcp__workspace-mcp__read_sheet_values
  spreadsheet_id: 1CWbvEAXwOAL9It6xMTRrHmfEJVPyi71TFWjdNEBXUns
  range_name: <year>!A1:A500
```

The first empty cell in column A is your starting row.

---

## Step 1: Find the emails to process

If Sam already provided specific message IDs, skip this step and go straight to Step 2.

Otherwise, search for unread receipt emails:

```
mcp__workspace-mcp__search_gmail_messages
  user_google_email: 11northmilton@gmail.com
  query: is:unread category:primary
  page_size: 50
```

Collect all message IDs. If there are more than 50, paginate. Show Sam the count and date
range before processing, or proceed directly if he already said to.

---

## Step 2: Parallel email reading

Split the message IDs into batches of ~7 and spawn one subagent per batch (4 subagents
total is typical for ~28 emails). Launch **all subagents in the same turn**.

Two reasons this matters:
- **Speed** — all batches run in parallel instead of sequentially
- **Context window** — full email bodies are verbose. Subagents absorb that raw content
  and return only the compact parsed rows, keeping the main context clean and leaving
  room for the sheet-writing steps.

For fewer than 8 emails total, skip the team and process inline with one
`get_gmail_messages_content_batch` call.

### Setting up

```
TeamCreate  team_name: "receipt-processor"
```

### Each subagent's prompt

Give every subagent:
- Its batch of message IDs
- **The cost rule from shared-rules.md (state this FIRST and prominently)**
- The column schema and formatting rules from shared-rules.md
- The category guide from shared-rules.md
- The one-row-per-order rule and flag-instead-of-skip rule
- Instructions: "Use `mcp__workspace-mcp__get_gmail_messages_content_batch` with
  `format: full` (not metadata — you need the body). Read the FULL body of each email.
  For forwarded emails, find the original content inside the wrapper. Return tab-separated
  rows (no header), then SendMessage to team-lead."

### Receipt column for emails

- **If cost < $75:** Order/invoice number (e.g. `Order #111-9922822-0133832`, `Invoice #1894`)
- **If cost ≥ $75:** Google Drive link to a PDF receipt saved in the year's Drive folder.
  For 2025: `https://drive.google.com/drive/folders/1ZUej3QETLaxgAglUe_sWT52F0eDI_2GJ`.
  If the PDF hasn't been uploaded yet, put the order/invoice number AND add
  `⚠️ NEEDS REVIEW: PDF receipt required — upload to Drive` in the Notes column.

After all subagents report back, send shutdown requests and call `TeamDelete`.

---

## Step 3: Aggregate and sort

1. Combine rows from all subagents
2. Sort chronologically by date (oldest first)
3. Check for duplicates: same date + vendor + amount + receipt number

---

## Step 4: Validate, write, verify, and report

Follow the pre-write validation, writing, post-write verification, and summary report
steps from `shared-rules.md`.

Summary report should include:
1. **Rows written** and range (e.g. "40 rows, rows 142–181")
2. **Flagged items** — a table: row # | date | item | flag reason
3. **Excluded items** — anything omitted and why
