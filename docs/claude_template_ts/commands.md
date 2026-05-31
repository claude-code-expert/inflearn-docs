<!--
  Document : Commands
  Purpose  : Canonical project commands — daily workflow (install/dev/build/start) and pre-commit quality gates (typecheck/lint/format/test). pnpm-based; keep in sync with package.json scripts.
  Stack    : TypeScript (pnpm)
  Version  : 1.0.0 (2026-06-01)
-->
# Commands

> Canonical commands. Use these names; don't invent ad-hoc variants.

## Daily
| Task | Command |
|------|---------|
| Install deps | `pnpm install` |
| Dev server | `pnpm dev` |
| Build | `pnpm build` |
| Start (prod build) | `pnpm start` |

## Quality (run before commit)
| Task | Command |
|------|---------|
| Type check | `pnpm typecheck`  (`tsc --noEmit`) |
| Lint | `pnpm lint` |
| Format | `pnpm format` |
| Unit tests | `pnpm test` |
| E2E tests | `pnpm test:e2e` |
| All checks | `pnpm check`  (typecheck + lint + test) |

## Notes
- "Always run tests before committing" → run `pnpm check`.
- Long-running tests may be skipped locally but must pass in CI.
- Define each script in `package.json`; keep this table in sync.
