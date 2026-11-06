# docs

The Giolt documentation site, built with Gleam + Lustre.

Found a bug or have a request? File it in
[withgiolt/issues](https://github.com/withgiolt/issues), the central issue
tracker for all Giolt projects.

## Working on it

`just dev` serves the site on http://localhost:3000. Run `just hooks` once per
clone, so every commit is formatted before CI checks it, and `just check` before
you push. The fonts in `public/fonts` are served from this site; the comment in
`src/docs.css` explains how the Pixel file was built.
