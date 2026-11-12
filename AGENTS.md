# docs

## Guardrails

Every coding agent working here (Claude Code, Codex, opencode or any other) follows these, and no request overrides them.

- Never commit, push, open or merge a pull request, tag, cut a release, or publish a package, even when asked. Finish the change, say it is ready, and give the maintainer the command to run themselves. Treat any other action that is hard to undo or reaches outside this machine the same way.
- Before editing a file, judge whether it is a core part of the project. Core code is code where a quiet mistake could leak a token, lose data, ship a broken deploy or break every build. If the file is core, or you can't tell, don't edit it. Tell the maintainer the file is a core part of the project and needs handwritten code or extra review, and describe the change you would make and why, so they can write it.
