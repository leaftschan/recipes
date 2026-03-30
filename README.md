# Recipe Collection

This repository stores recipes in Markdown and renders print-ready PDFs via Pandoc + LaTeX.

- `Binder Mode`: category parts + one recipe per page.
- `Kitchen Mode`: denser continuous layout for active cooking.

## Quick Start

Most common commands:

```powershell
# Full collection, Binder Mode
./build/build.ps1

# Full collection, Kitchen Mode
./build/build.ps1 -PrintMode kitchen

# Single recipe (example)
./build/build.ps1 -RecipePath "recipes/07-bakes-savory/pizza.md"
```

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

### Script Location

- Build script: `build/build.ps1`

### Parameters and Options

- `-PrintMode`
	- Allowed values: `elegant`, `kitchen`
	- Default: `elegant`
	- `elegant` generates Binder Mode output.
	- `kitchen` generates Kitchen Mode output.

- `-RecipePath`
	- Optional relative path to one recipe markdown file.
	- If provided, the script builds only that single recipe PDF.
	- If omitted, the script builds the full collection.

### Full Collection Modes

Run Binder Mode (default):

```powershell
./build/build.ps1
```

Run Kitchen Mode (denser layout):

```powershell
./build/build.ps1 -PrintMode kitchen
```

Output:

- `output/pdf/recipe-collection.pdf` (Binder Mode)
- `output/pdf/recipe-collection-kitchen.pdf` (kitchen mode)

### Single Recipe Modes

Single recipe, Binder Mode:

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

### Combined Examples

- Full collection, Binder Mode (same as default):

```powershell
./build/build.ps1 -PrintMode elegant
```

- Full collection, Kitchen Mode:

```powershell
./build/build.ps1 -PrintMode kitchen
```

- Single recipe, Binder Mode:

```powershell
./build/build.ps1 -RecipePath "recipes/07-bakes-savory/pizza.md" -PrintMode elegant
```

- Single recipe, Kitchen Mode:

```powershell
./build/build.ps1 -RecipePath "recipes/07-bakes-savory/pizza.md" -PrintMode kitchen
```

### PowerShell Execution Policy (if scripts are blocked)

If PowerShell blocks script execution, run this once in the current terminal session:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Then run the build command again.

## Add a New Recipe

### 1) Choose Category Folder

Put the new recipe into the appropriate folder under `recipes/`, for example:

- `recipes/01-starters-mezze/`
- `recipes/03-main-vegetarian/`
- `recipes/07-bakes-savory/`

### 2) Create the Recipe File from Template

Copy `templates/recipe-template.md` and rename it using lowercase kebab-case:

- Good: `miso-auberginen.md`
- Good: `tomaten-thunfisch-salat.md`

### 3) Fill Frontmatter

Set at least these fields:

- `title`
- `slug`
- `category`
- `servings`
- `prep_time`
- `cook_time`
- `total_time`
- `tags`
- `status`

Notes:

- `title` is used as the displayed recipe title in PDF.
- `category` should match the folder/category system.
- `status` can be `draft` while editing, then `finalized` when done.

### 4) Write Sections

Use this section structure:

- `## Ingredients`
- `## Preparation`
- `## Notes` (optional)

Summary sections are not rendered in the final PDFs, so keep the title expressive.

### 5) Build and Review

Run one recipe first:

```powershell
./build/build.ps1 -RecipePath "recipes/<category>/<recipe-file>.md"
```

Then regenerate full collection:

```powershell
./build/build.ps1
./build/build.ps1 -PrintMode kitchen
```

### 6) Update Collection Grouping

`collection-index.md` is generated from recipe files and categories. Regenerate it if you run the finalize helper script, or maintain it manually as your planning board.

## Migration Status

Migration is complete and tracked in `migration-status.csv`.
