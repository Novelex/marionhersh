# Site sources

The pages are generated from these files. Run these from the project root:

    perl _build/convert.pl _build/original _build/src
    perl _build/build.pl _build .
    perl _build/verify.pl

1. `convert.pl` turns the original WordPress page content (`original/`) into clean, accessible HTML fragments (`src/`). It changes structure only: headings, lists, table headers and line breaks. It never changes words.
2. `build.pl` puts each page together from `layout.html` (header, menu, footer) and `content/*.html` (page structure). `{{INCLUDE file}}` pulls in a fragment. It also assembles `assets/style.css` from the three `css-*.css` files and adds a version tag to its address, so visitors always get the latest styles.
3. `verify.pl` compares every page with the original text, word by word, and reports any difference.

Other files:

- `src/flyer.frag.html`: the election flyer image and its text, typed out from the flyer.
- `SUGGESTED-CORRECTIONS.md`: possible errors in the original text, for Marion to approve. Nothing in it has been applied.
- `404.html` uses the base path `/marionhersh/` for GitHub Pages. Change it in `build.pl` if the site moves to its own domain.
