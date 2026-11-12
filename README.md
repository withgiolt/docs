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

## AI use

AI may write code in every Giolt repository, and this one is heavily AI-assisted: agents critique its structure, proofread, and write the tedious parts.

How AI use is managed here:

- Every change reaches `main` through a pull request with passing CI, and CI deploys the site only from `main`. GitHub enforces both, for everyone.
- Before each commit and merge, an agent waits for the maintainer to confirm they reviewed the change, and the commit records it in a `Reviewed-by:` trailer. GitHub doesn't check this. It is a rule the agents follow.
- A change to core code, where a quiet mistake could leak a token, lose data, ship a broken deploy or break every build, gets a code review pass first, and the agent names each core file it touched.

The agents' rules are in [AI.md](AI.md). The [AI use policy](https://giolt.com/ai) covers every Giolt repository.
