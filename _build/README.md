# Site sources

The published pages are generated from these files. Edit the files here, then rebuild from the project root:

    perl _build/build.pl _build .

This also assembles `assets/style.css` from the three `css-*.css` files and adds a version tag to its address, so visitors always get the latest styles.

- `layout.html`: shared header, navigation and footer. `{{ROOT}}` becomes the relative path to the site root.
- `content/*.html`: the main content of each page. `{{INCLUDE file}}` pulls in a fragment from this folder.
- `build.pl`: the list of pages, their addresses and titles, and the redirects for old addresses.
- `404.html` is built with the base path `/marionhersh/` for GitHub Pages. Change it in `build.pl` if the site moves to its own domain.
