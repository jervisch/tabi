# TABi — Master Coding Agent Prompt

You are implementing V1 of 旅 TABi, a Japan-only visual travel-memory atlas.

## Product

TABi turns intentional photographs into geographic memories.

Core loop:
GO → CAPTURE → REMEMBER → ATLAS

The user should never feel like they are maintaining a travel database.

## Read first

1. `/design/DESIGN.md`
2. `/design/references/TABi_visual_handoff_board.png`
3. existing project documentation and source code

## V1 scope

Build:
- illustrated Japan Atlas
- prefecture → city → place drilldown
- custom TABi camera
- location + timestamp capture
- automatic geographic association
- visit candidate + confidence
- memory gallery
- outside-Japan / Elsewhere state
- local-first persistence

Do not build:
- accounts
- social
- itinerary planner
- booking
- recommendations
- weather
- AI storytelling
- global map

## Recommended iOS stack

If this is a new native iOS project:
- Swift
- SwiftUI
- MapKit only for geographic utilities/interaction where useful
- CoreLocation
- AVFoundation
- Photos / PhotosUI
- CoreImage
- SwiftData

Avoid adding dependencies unless necessary.

## Architecture

Separate:
- Domain models
- geographic data
- location services
- camera services
- image processing
- Atlas rendering
- persistence
- UI

Suggested model:

Memory
- id
- image
- capturedAt
- latitude
- longitude
- placeName
- city
- prefecture
- visitID

Visit
- id
- place
- city
- prefecture
- startedAt
- endedAt
- confidence
- status
- memories

Status:
candidate / confirmed / rejected

## Location model

The intentional photo is the strongest visit signal.

A photo should create a visit candidate using:
- photo timestamp
- GPS coordinate
- GPS accuracy
- recent location samples
- dwell time when available
- movement state

Do not over-engineer visit inference in V1.

Use deterministic heuristics first.

## Atlas

Maintain a real geographic data model independently from the visual renderer.

Preferred visual:
- custom illustrated Japan map
- cream land
- soft blue water
- moss/green land accents
- hand-drawn outlines
- Japanese labels
- vermilion visited markers
- environmental illustration

The geographic model should support future replacement of the illustrated map with a more interactive rendering.

## UI

Primary screens:
1. Atlas
2. Camera
3. Memories
4. Prefecture
5. City
6. Place
7. Memory Detail

The Atlas and Camera are the hero experiences.

## Deliverable

Implement in vertical slices:
1. foundation + design system
2. Atlas with seeded demo data
3. camera
4. location association
5. visit inference
6. memories
7. visual polish
8. testing

At each stage, keep the app runnable.

Before declaring V1 complete, run the acceptance test in `/AGENTS.md`.
