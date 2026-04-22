// Scrape Giphy Favorites Page
// ----------------------------
// Run this in the browser console on https://giphy.com/favorites
// Outputs JSON compatible with ~/.claude/giphy-favorites.json
//
// Usage:
//   1. Go to https://giphy.com/favorites
//   2. Scroll to the bottom to load all favorites (lazy-loaded)
//   3. Open DevTools console (Cmd+Option+J)
//   4. Paste this script and press Enter
//   5. JSON is copied to clipboard and logged to console

(() => {
  const gifs = document.querySelectorAll("a[data-giphy-id]");
  if (!gifs.length) {
    console.error("No GIFs found. Are you on the Giphy favorites page?");
    return;
  }

  const results = Array.from(gifs).map((a) => {
    const id = a.getAttribute("data-giphy-id");
    const img = a.querySelector("img");
    const title = img?.alt?.trim() || "";

    // Build the canonical GIF URL from the ID
    const url = `https://media.giphy.com/media/${id}/giphy.gif`;

    // Extract visible tags from the tag container spans
    const tagContainer = a.querySelector('div[class*="TagContainer"], div > span');
    const tagSpans = tagContainer
      ? tagContainer.closest("div").querySelectorAll("span")
      : a.querySelectorAll('span[class]');

    const tags = Array.from(tagSpans)
      .map((s) => s.textContent.replace(/^#/, "").replace(/\u00a0/g, "").trim().toLowerCase())
      .filter((t) => t.length > 0);

    return { url, title, tags };
  });

  const json = JSON.stringify(results, null, 2);
  console.log(`Found ${results.length} favorites:`);
  console.log(json);

  // Copy to clipboard
  navigator.clipboard.writeText(json).then(
    () => console.log("Copied to clipboard!"),
    () => console.warn("Clipboard write failed -- copy from console output above.")
  );
})();