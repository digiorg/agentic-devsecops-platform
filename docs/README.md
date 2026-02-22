# Documentation

Platform documentation and Architecture Decision Records.

## Structure

```
docs/
├── adr/            # Architecture Decision Records
│   ├── template.md
│   └── 001-*.md
└── guides/         # User and operator guides
    ├── getting-started.md
    ├── local-development.md
    └── operations.md
```

## Architecture Decision Records (ADRs)

ADRs document significant architectural decisions:

| ADR | Title | Status |
|-----|-------|--------|
| [Template](adr/template.md) | ADR Template | - |

### Creating an ADR

1. Copy `adr/template.md` to `adr/NNN-title.md`
2. Fill in the sections
3. Submit PR for review
4. Update status after decision

## Guides

| Guide | Description |
|-------|-------------|
| Getting Started | Initial setup and first deployment |
| Local Development | Setting up local KinD environment |
| Operations | Day-to-day platform operations |

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for documentation guidelines.
