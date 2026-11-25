import { test, expect } from "@playwright/test";

test("the service responds and renders a page", async ({ page }) => {
  const baseURL = process.env.E2E_BASE_URL;
  expect(baseURL, "E2E_BASE_URL must be configured").toBeTruthy();

  const path = process.env.E2E_HEALTH_PATH || "/";
  const response = await page.goto(path);

  expect(response, `no response for ${path}`).not.toBeNull();
  expect(response?.ok(), `${path} returned HTTP ${response?.status()}`).toBeTruthy();
  await expect(page.locator("body")).toBeVisible();
});
