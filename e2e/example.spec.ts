import { test, expect } from "./fixtures/base";

test.describe("Homepage", () => {
  test("should load the homepage", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveTitle(/Vibe Scaffolding/);
    await expect(
      page.getByRole("heading", { name: /vibe scaffolding/i }),
    ).toBeVisible();
  });

  test("should navigate to 404 page for unknown routes", async ({ page }) => {
    await page.goto("/unknown-route");
    await expect(page.getByText(/page not found/i)).toBeVisible();
  });
});
