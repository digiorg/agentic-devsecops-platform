# Documentation

Platform documentation and Architecture Decision Records.

## Overview

- [Architecture Overview](architecture.md) — High-level platform architecture

## Guides

| Guide | Description |
|-------|-------------|
| [Getting Started](guides/getting-started.md) | Initial setup and first deployment |
| Local Development | Setting up local KinD environment (coming soon) |
| Operations | Day-to-day platform operations (coming soon) |

## Architecture Decision Records (ADRs)

ADRs document significant architectural decisions:

| ADR | Title | Status |
|-----|-------|--------|
| [001](adr/001-bootstrap-framework-architecture.md) | Bootstrap Framework Architecture | Accepted |
| [Template](adr/template.md) | ADR Template | — |

### Creating an ADR

1. Copy `adr/template.md` to `adr/NNN-title.md`
2. Fill in the sections
3. Submit PR for review
4. Update status after decision

## Directory Structure

```
docs/
├── architecture.md     # Platform architecture overview
├── adr/                # Architecture Decision Records
│   ├── template.md
│   └── 001-*.md
└── guides/             # User and operator guides
    ├── getting-started.md
    └── ...
```

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for documentation guidelines.
