# Recipe Collection

This repository stores recipes in Markdown and renders print-ready PDFs via Pandoc + LaTeX.

## Goals

- Keep recipe authoring simple and fast.
- Keep layout consistent and print-friendly.
- Separate source files, generated files, and build artifacts.

## Folder Layout

- `recipes/`: recipe source files in Markdown.
- `templates/`: recipe and PDF style templates.
- `build/`: build scripts and generated intermediate files.
- `output/pdf/`: generated PDF files.

## Authoring Workflow

1. Copy `templates/recipe-template.md` to the appropriate category folder in `recipes/`.
2. Rename using lowercase kebab-case, for example `miso-auberginen.md`.
3. Fill metadata and content.
4. Run the build script to generate a full PDF collection.

## Build PDF Collection

Requirements:

- Pandoc installed and available in PATH.
- A TeX engine available (`xelatex`, `lualatex`, or `pdflatex`).

Run:

```powershell
./build/build.ps1
```

Kitchen print mode (denser layout):

```powershell
./build/build.ps1 -PrintMode kitchen
```

Output:

- `output/pdf/recipe-collection.pdf` (elegant mode)
- `output/pdf/recipe-collection-kitchen.pdf` (kitchen mode)

## Build One Recipe (optional)

```powershell
./build/build.ps1 -RecipePath "recipes/10-desserts-sweets/bananenbrot.md"
```

Single recipe in kitchen mode:

```powershell
./build/build.ps1 -RecipePath "recipes/10-desserts-sweets/bananenbrot.md" -PrintMode kitchen
```

Output:

- `output/pdf/<recipe-file-name>.pdf`
- `output/pdf/<recipe-file-name>-kitchen.pdf` (kitchen mode)

## Migration Status

Migration is complete and tracked in `migration-status.csv`.
