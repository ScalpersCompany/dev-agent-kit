# End-to-end tests

This is the browser baseline. Add one spec per user flow the change touches and name it
after the flow, not after the implementation. A flow must start from the public entry
point, exercise the real UI and backend, and assert the persisted or visible outcome.

```bash
npm install
npx playwright install chromium
E2E_BASE_URL=http://127.0.0.1:8000 npm test
```

`verify/run.sh` sets `E2E_BASE_URL`, `PLAYWRIGHT_OUTPUT_DIR` and
`PLAYWRIGHT_REPORT_DIR`, and copies the HTML report, JUnit, JSON, traces, screenshots and
videos into `evidence/<run-id>/e2e/`. A skipped test or a smoke-only check is not complete
E2E evidence.

Never point `E2E_BASE_URL` at production. The suite may create or change data, so use a
disposable environment and clean it up.
