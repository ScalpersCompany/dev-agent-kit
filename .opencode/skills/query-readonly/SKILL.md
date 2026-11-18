---
name: query-readonly
description: "Answer data questions with read-only SQL and saved evidence."
version: 1.0.0
author: Nicolas Ramos
---

# Read-only queries

Use when the answer needs data from the database.

- Only `SELECT`. Start with `SET TRANSACTION READ ONLY`.
- No writes, no DDL, no stored procedures that write.
- Always add `LIMIT 200` and a `WHERE` on a date or id range.
- Never point at production. If the only database is production, stop and ask for a replica or an export.
- Save the query and the result in `evidence/<run-id>/`.

## Output

```
QUESTION: <what was asked>
QUERY: <file under evidence/>
RESULT: <n rows>
READ: <one sentence with the number>
```

If the result contradicts the ticket, report the contradiction instead of adjusting the query until it agrees.
