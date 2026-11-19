# TABi Design Kit

This package contains the handoff materials for implementing V1 of 旅 TABi.

## Start here

1. Read `AGENTS.md`
2. Read `design/DESIGN.md`
3. Open `design/references/TABi_visual_handoff_board.png`
4. Give the coding agent `prompts/MASTER_CODING_AGENT_PROMPT.md`
5. Use the specialized prompts when implementing map, camera, UI, and visual QA.

## Important

The visual board is a design reference, not a production UI screenshot.

The agent should reproduce the visual language, not hard-code the board.

## Recommended repository placement

Copy the contents of this package into the project:

```
/
├── AGENTS.md
├── design/
│   ├── DESIGN.md
│   ├── ASSET_MANIFEST.json
│   └── references/
│       └── TABi_visual_handoff_board.png
└── prompts/
    ├── MASTER_CODING_AGENT_PROMPT.md
    ├── MAP_ASSET_PROMPT.md
    ├── CAMERA_FILM_PROMPT.md
    ├── UI_IMPLEMENTATION_PROMPT.md
    └── VISUAL_QA_PROMPT.md
```

The coding agent can then work from the repository as its source of truth.
