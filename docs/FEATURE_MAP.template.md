# Feature map

The map an agent reads before searching. It describes the application from the user's point of view, not the code's.

Keep it current: when a feature moves or a new route appears, update this file in the same change. A stale map is worse than no map.

## How to use it

1. Find the feature in the table.
2. Go to its directory first, not to a global grep.
3. Use the "reach it" column to exercise it in the UI or the API.

## Features

| Feature | Directory | Entry point | Reach it | Tests | Owner |
|---|---|---|---|---|---|
| Example: customer import | `addons/customer_import/` | `models/import_wizard.py` | Settings > Customers > Import | `tests/test_import.py` | team |
|  |  |  |  |  |  |

## Routes and screens

| Screen | Route or menu | Component or view | Key actions |
|---|---|---|---|
|  |  |  |  |

## Jobs and external calls

| Job | Trigger | Code | Failure mode |
|---|---|---|---|
|  |  |  |  |

## Test data

- Disposable database:
- Seed command:
- Users and groups:

## Known traps

-  (one line per trap, with the file that owns it)
