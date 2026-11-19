# 旅 TABi — Design System

## Product thesis

TABi is a visual atlas of your memories in Japan.

Core loop:

**Go somewhere → capture a photo → TABi knows where you were → your Atlas grows.**

The app should feel like a cozy Japanese illustrated travel journal, not a conventional iOS utility.

## Visual direction

Primary direction: **cozy Japanese anime travel journal**.

Characteristics:
- warm washi/cream paper
- hand-drawn outlines
- soft watercolor fills
- simple anime-inspired environmental illustration
- restrained pastel palette
- Japanese + English editorial typography
- subtle paper grain
- playful but sophisticated
- illustrated geography rather than a standard map
- real photographs contrasted against an illustrated world

Avoid:
- generic iOS dashboard aesthetics
- standard Apple tab bars
- Google Maps-like map styling
- excessive kawaii decoration
- anime characters as the primary identity
- random sakura everywhere
- tourist-board / "Japan flag" clichés
- heavy retro filters

## Palette

| Token | Hex | Use |
|---|---|---|
| Washi | #F6F0E4 | primary background |
| Sumi | #34312C | primary text |
| Indigo | #557C91 | map/water/primary cool accent |
| Sky | #8FC5D8 | sky/water surfaces |
| Moss | #8FA477 | land/vegetation |
| Peach | #E9A59A | flowers/soft accents |
| Vermilion | #C95B45 | primary interactive accent |
| Sand | #DCC8A5 | secondary surfaces |

Do not introduce iOS blue as an accent.

## Typography

Japanese:
- prefer a Mincho / Japanese serif family for titles and place names
- examples: Noto Serif JP, Source Han Serif

English:
- editorial serif for major titles
- restrained sans-serif for functional UI

Use Japanese and English together where useful:
京都
Kyoto

## Illustration language

Use:
- simple ink outlines
- watercolor texture
- limited colors
- imperfect hand-drawn edges
- soft environmental details
- small scenic motifs

Good motifs:
- Mount Fuji
- shinkansen
- torii
- temple roofs
- clouds
- waves
- mountains
- cherry blossom branches
- bamboo
- lanterns
- small Japanese houses

Use motifs to establish place and atmosphere, not as decoration on every screen.

## Atlas

The Atlas is the hero.

Do not render the default MapKit basemap as the primary visual experience.

Preferred approach:
1. maintain real geographic coordinates/data underneath
2. render a custom illustrated Japan map as the visual layer
3. map taps resolve back to geographic entities
4. visited prefectures/cities are visually emphasized
5. current location is a subtle vermilion marker

Hierarchy:

Japan
→ Prefecture
→ City
→ Place
→ Memories

## Outside Japan

When the user is outside Japan:
- Japan remains the main Atlas
- current location is shown as a small "Elsewhere" / external-island state
- do not make this look like a location error

## Camera

The camera is the primary action.

Minimal controls.
Photo is dominant.

When location is known, show:
京都
Kyoto

祇園
Gion

After capture:
**Memory saved**
**Added to your Atlas**

## Photography

TABi photos should share one restrained photographic treatment:
- warm highlights
- slightly muted saturation
- soft contrast
- gentle highlight rolloff
- subtle grain
- subtle halation
- natural skin tones
- preserve Japanese reds and greens

Avoid exaggerated "disposable camera" effects.

## Navigation

Primary destinations:
- 地図 / Atlas
- Camera / Capture
- 思い出 / Memories

The camera should visually dominate.

Do not use the default iOS tab bar appearance.

## Product constraints

V1:
- Japan only
- Atlas
- Camera
- Memories
- location + timestamp
- automatic place association
- visit confidence
- local-first persistence

Do not add:
- social
- accounts
- itinerary planning
- booking
- recommendations
- weather
- AI-generated stories
- global world atlas
