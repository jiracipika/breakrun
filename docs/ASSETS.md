# Asset provenance

## Runtime

- `scripts/art/sunbreak_world.gd`: original procedural mesh construction authored for this project. No franchise assets or external 3D model downloads.
- `assets/fonts/BarlowCondensed-ExtraBold.ttf`: Google Fonts, Barlow Condensed family, SIL Open Font License. Exact license bundled as BarlowCondensed-OFL.txt. Source: https://github.com/google/fonts/tree/main/ofl/barlowcondensed
- `assets/fonts/AtkinsonHyperlegible-Regular.ttf`: Google Fonts, Atkinson Hyperlegible family, SIL Open Font License. Exact license bundled as AtkinsonHyperlegible-OFL.txt. Source: https://github.com/google/fonts/tree/main/ofl/atkinsonhyperlegible
- No audio, music, paid assets, external game services or plugins in this slice.

## Design-only artwork

`docs/design/breakrun/art/01-directions.png` and `02-sunbreak-concept.png` were generated with GPT Image under Astra direction during planning. Exact prompts and provenance are preserved in the adjacent PROMPTS.md. They are not runtime textures, game screenshots, meshes, or finished production references. Commercial rights and working-title clearance remain unaudited.

## Actual screenshots

`docs/screenshots/title.png` and `gameplay.png` are captured from this Godot project's GL renderer using tests/capture_scene.gd. No concept image is substituted for live gameplay evidence.

Documentation is excluded from Godot import by docs/.gdignore. Runtime fonts remain importable.
