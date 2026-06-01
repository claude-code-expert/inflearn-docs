<!--
  Document : Project Structure
  Purpose  : Reference map of the directory layout (src/domain, services, api, lib, tests, .claude/rules) and conventions (path alias, where types/config live) so paths are never guessed.
  Stack    : TypeScript
  Version  : 1.0.0 (2026-06-01)
-->
# Project Structure

> Reference map so paths are never guessed (see CLAUDE.md "Source first").

## Layout (adjust per project)
```
.
├── src/                 # application source
│   ├── domain/          # entities, types, business rules (framework-free)
│   ├── services/        # use cases / application logic
│   ├── api/ (or routes/)# HTTP handlers, controllers
│   ├── lib/             # shared utilities
│   └── index.ts         # entry point
├── tests/               # mirrors src/ structure
├── .claude/rules/       # project guidelines (this folder)
├── package.json
├── tsconfig.json
└── CHANGELOG.md
```

## Conventions
- One module = one responsibility. Keep files focused and small.
- `domain/` has **no** framework or I/O imports — pure types and logic only.
- Test files live in `tests/` mirroring the source path (`src/services/x.ts` → `tests/services/x.test.ts`).
- Path alias `@/*` → `src/*` (configured in `tsconfig.json`).

## Where things live
- Types/schemas: `src/domain/`
- Config/env access: a single typed module (e.g. `src/lib/env.ts`), validated with Zod.
- Never scatter `process.env` reads across the codebase.
