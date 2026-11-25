import { defineConfig, devices } from "@playwright/test";

const outputDir = process.env.PLAYWRIGHT_OUTPUT_DIR || "test-results";
const reportDir = process.env.PLAYWRIGHT_REPORT_DIR || "playwright-report";
const baseURL = process.env.E2E_BASE_URL || "http://127.0.0.1:8000";

export default defineConfig({
  testDir: "./tests",
  timeout: 60_000,
  expect: { timeout: 10_000 },
  fullyParallel: true,
  forbidOnly: Boolean(process.env.CI),
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 2 : undefined,
  outputDir,
  reporter: [
    ["list"],
    ["html", { outputFolder: reportDir, open: "never" }],
    ["junit", { outputFile: `${reportDir}/junit.xml` }],
    ["json", { outputFile: `${reportDir}/results.json` }],
  ],
  use: {
    baseURL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
});
