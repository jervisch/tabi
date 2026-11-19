# TABi Coding Agent Instructions

Read `/design/DESIGN.md` before implementing UI.

Read the visual reference at:
`/design/references/TABi_visual_handoff_board.png`

## Mission

Build V1 of 旅 TABi: a Japanese visual atlas of memories in Japan.

Core loop:

**Capture → Remember → Atlas**

## Non-negotiable design constraints

- Do not fall back to default iOS visual styling.
- Do not use a standard MapKit basemap as the main Atlas presentation.
- Do not use a standard Apple tab bar appearance.
- Do not create a generic travel dashboard.
- Use the provided design tokens.
- Use Japanese + English labels where appropriate.
- Preserve generous whitespace and editorial hierarchy.
- The illustrated map and photography treatment are core product identity.

## Engineering philosophy

- Prefer native iOS frameworks unless a dependency materially improves the result.
- Keep the architecture simple.
- Separate geographic data from visual rendering so the map can evolve.
- Inject location/camera providers so the app can be tested with simulated journeys.
- Make V1 local-first.
- Avoid speculative features.

## Acceptance test

Starting with an empty Atlas:

1. Simulate being in Kyoto.
2. Open TABi.
3. Capture a photo.
4. Attach timestamp and location.
5. Resolve the location to Kyoto / Kyoto Prefecture.
6. Create a memory.
7. Create/update a visit candidate.
8. Confirm the visit.
9. Kyoto becomes visibly visited on the Atlas.
10. Drill down Japan → Kyoto Prefecture → Kyoto → Place.
11. See the captured memory.
12. Simulate leaving Japan.
13. Atlas remains visible and current location appears in the external/Elsewhere state.

The result should feel like a Japanese illustrated travel journal rather than a conventional mobile app.
