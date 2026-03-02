# Shared Rules — 11 North Milton Expense Tracking

These rules apply to all expense-processing skills. Read this file before parsing any receipts or emails.

---

## Fixed details (don't ask Sam for these)

| Setting | Value |
|---------|-------|
| Gmail account | `11northmilton@gmail.com` |
| Spreadsheet ID | `1CWbvEAXwOAL9It6xMTRrHmfEJVPyi71TFWjdNEBXUns` |
| Sheet tab | **Ask Sam which year** if not obvious from context. Expenses can be processed retroactively for prior years. If Sam says "process my receipts" without specifying a year, ask before proceeding. If the year's tab doesn't exist yet in the spreadsheet, tell Sam and offer to create it. |
| Property | 11 North Milton Ave, Malden MA (Schedule E rental property) |

---

## Cost rule — include this verbatim at the top of every subagent prompt

> **CRITICAL COST RULE — READ THIS FIRST**
> Cost = the FINAL AMOUNT PAID — the very last number on the receipt/email after all
> tax, tips, fees, and shipping are included. Find the line that says "Total", "Grand Total",
> "Amount Charged", or "Amount Due" and use that number — NEVER a subtotal or item
> list price. If an item is $7.99 but the final charge is $8.49 after tax, record $ (8.49).
> For multi-item single-category orders, Cost is still the single final total, not the sum
> of item prices.

---

## One row per order — always

**Each receipt or email produces exactly one row, no exceptions.** Do not split an order into
multiple rows, even if it contains items from different categories.

- The Cost must come from the **order grand total** (including tax and any fees), not from
  individual item prices. Never record a bare item price.
- Pick the **dominant category** (by dollar value) for the row.
- If the order spans multiple categories, list all items in Description and flag it:
  `⚠️ NEEDS REVIEW: mixed categories — [category A] items + [category B] items`

---

## Column schema

```
A: Date | B: Category | C: Description | D: Vendor | E: Miles | F: Allocation | G: Cost | H: Receipt | I: Notes
```

## Column formatting rules

| Column | Format | Notes |
|--------|--------|-------|
| Date | `M/D/YYYY` | e.g. `7/1/2025` — no leading zeros |
| Category | See category guide | Must match exactly |
| Description | Plain text | Be specific: item name, model, qty |
| Vendor | Store/company name | e.g. `Amazon`, `Lowe's`, `Chris' Landscape LLC` |
| Miles | **Leave blank** | Fill only for Auto and Travel — enter the number of miles (e.g. `9`) |
| Allocation | `100%` | Always 100% — all expenses are 100% for this property |
| Cost | ` $ (X.XX)` | Always negative. Space before `$`. Parens = negative. **Order grand total incl. tax — never a bare item price.** |
| Receipt | See individual skill for format | Gmail skill: order/invoice number or Drive link. Receipts skill: local filename. |
| Notes | Blank normally | Auto and Travel: `Round Trip [origin] to 11 North Milton St, Malden`. Otherwise use `⚠️ NEEDS REVIEW: reason` to flag issues. |

**Cost examples:** ` $ (45.99)` · ` $ (120.00)` · ` $ (1,099.00)`

---

## Category guide (IRS Schedule E)

| Category | Use for |
|----------|---------|
| **Repairs** | Fixing or maintaining the property: plumbing, insulation, smoke detectors, appliance parts, caulk/sealant, mortar, insulation, drain catchers, filters, thermostats, radon monitors |
| **Supplies** | Consumable or small tools used at the property: PPE (gloves, hard hats, respirators), saw blades, cleaning supplies, scrapers, fasteners, hardware |
| **Cleaning and Maintenance** | Lawn care, landscaping, pest control, grass seed, fertilizer, manure, spreaders, dryer vent cleaning. **Chris' Landscape LLC always goes here.** |
| **Utilities** | Electric, gas, water, internet |
| **Auto and Travel** | Mileage or travel costs for property visits. Fill Miles with the number of miles. Cost = miles × current IRS mileage rate. Notes = `Round Trip [origin address] to 11 North Milton St, Malden`. |
| **Other Expenses** | Books, reference materials, anything that doesn't fit above |

**When in doubt between Repairs and Supplies:** if it's fixing something specific → Repairs; if it's a tool or consumable used for work → Supplies.

**Never use bare item prices as the cost.** Even for a single-item order, use the grand
total (item + tax + any fees), not the item's list price.

---

## Pre-write validation

Before touching the sheet, run these checks on the rows and fix any issues found:

| Check | What to verify |
|-------|----------------|
| **Starting row is empty** | Read `<year>!A<start>` — confirm it's blank, not existing data |
| **Row above has data** | Read `<year>!A<start-1>` — confirm it has a date (proves you're appending, not skipping rows) |
| **All categories valid** | Every value in column B is one of: `Repairs`, `Supplies`, `Auto and Travel`, `Utilities`, `Cleaning and Maintenance`, `Other Expenses` |
| **All costs negative** | Every column G value matches ` $ (X.XX)` — space, dollar sign, space, open paren, number, close paren |
| **No header row** | Column A row 1 of your data is a date, not the word `Date` |
| **Dates ascending** | Each row's date is ≥ the previous row's date |
| **No blanks in required columns** | Date, Category, Vendor, Allocation, Cost are filled on every row |
| **Receipt column filled** | Every Receipt cell has a value (not blank) |

If any check fails, fix the rows before writing — do not write bad data and plan to fix it later.

---

## Writing to the sheet

Write in sub-batches of 20 rows. Use `USER_ENTERED` mode so dates and the
` $ (X.XX)` format render correctly.

```
mcp__workspace-mcp__modify_sheet_values
  spreadsheet_id: 1CWbvEAXwOAL9It6xMTRrHmfEJVPyi71TFWjdNEBXUns
  range_name: <year>!A<start>:I<start+19>
  value_input_option: USER_ENTERED
  values: [[...], ...]
```

---

## Post-write verification

```
mcp__workspace-mcp__read_sheet_values
  spreadsheet_id: 1CWbvEAXwOAL9It6xMTRrHmfEJVPyi71TFWjdNEBXUns
  range_name: <year>!A<start-2>:I<end+2>
```

Confirm all of the following:

- **Row count** — number of rows written matches number of rows parsed
- **No overwrite** — the 2 rows immediately before `<start>` still contain the original data
- **No header** — `<year>!A<start>` is a date like `7/1/2025`, not the word `Date`
- **Dates ascending** — the date in the last new row is ≥ the date in the first new row
- **Cost spot-check** — sample 3–4 rows from column G and confirm they match ` $ (X.XX)` format
- **Categories spot-check** — sample 3–4 rows from column B and confirm they're in the allowed list
- **Receipt column** — confirm column H rows have values (not blank)

If anything looks wrong, report it to Sam before marking the task done rather than silently leaving bad data.

---

## Flag instead of skip

Never drop a row because something is unclear. Write best-effort data and flag it:

```
⚠️ NEEDS REVIEW: <reason>
```

Common reasons:
- `likely personal expense` — include it anyway, Sam decides
- `amount unclear / receipt truncated` — use best estimate
- `category ambiguous` — pick the best guess and flag
- `date not found on receipt` — use file modification date as fallback, flag it
- `delivery address differs from 11 North Milton` — flag it

Personal-looking items should still get a row with the flag — do not silently exclude them.
