param(
    [string]$RecipePath,
    [ValidateSet("elegant", "kitchen")]
    [string]$PrintMode = "elegant"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $repoRoot "output/pdf"
$buildDir = Join-Path $repoRoot "build"

$templatePath = Join-Path $repoRoot "templates/collection-template.tex"
if ($PrintMode -eq "kitchen") {
    $templatePath = Join-Path $repoRoot "templates/collection-template-kitchen.tex"
}

if (-not (Test-Path $templatePath)) {
    throw "Template not found: $templatePath"
}

New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

function Test-Command {
    param([string]$CommandName)
    return [bool](Get-Command $CommandName -ErrorAction SilentlyContinue)
}

if (-not (Test-Command "pandoc")) {
    throw "Pandoc is not installed or not in PATH."
}

$metadataArgs = @(
    "--metadata", "title=Recipe Collection",
    "--metadata", "subtitle=Grouped by Category ($PrintMode mode)",
    "--metadata", "date=$(Get-Date -Format yyyy-MM-dd)"
)

if ($RecipePath) {
    $fullRecipePath = Join-Path $repoRoot $RecipePath
    if (-not (Test-Path $fullRecipePath)) {
        throw "Recipe file not found: $RecipePath"
    }

    $name = [System.IO.Path]::GetFileNameWithoutExtension($fullRecipePath)
    $suffix = ""
    if ($PrintMode -eq "kitchen") { $suffix = "-kitchen" }
    $outputFile = Join-Path $outputDir ("$name$suffix.pdf")

    & pandoc $fullRecipePath -o $outputFile --from markdown --template $templatePath --toc --pdf-engine=xelatex @metadataArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Pandoc failed while building recipe: $RecipePath"
    }
    Write-Host "Built: $outputFile"
    exit 0
}

$recipesRoot = Join-Path $repoRoot "recipes"
$recipeFiles = Get-ChildItem -Path $recipesRoot -Recurse -File -Filter *.md | Sort-Object FullName

if (-not $recipeFiles) {
    throw "No recipe markdown files found under recipes/."
}

$generatedCollection = Join-Path $buildDir "_collection.generated.md"

"# Recipe Collection" | Set-Content -Path $generatedCollection -Encoding UTF8
"" | Add-Content -Path $generatedCollection -Encoding UTF8
"This collection is generated automatically from recipes/." | Add-Content -Path $generatedCollection -Encoding UTF8
"" | Add-Content -Path $generatedCollection -Encoding UTF8

$currentGroup = ""
foreach ($file in $recipeFiles) {
    $group = Split-Path -Leaf (Split-Path -Parent $file.FullName)
    if ($group -ne $currentGroup) {
        if ($currentGroup -ne "") {
            "\\newpage" | Add-Content -Path $generatedCollection -Encoding UTF8
            "" | Add-Content -Path $generatedCollection -Encoding UTF8
        }
        "## $group" | Add-Content -Path $generatedCollection -Encoding UTF8
        "" | Add-Content -Path $generatedCollection -Encoding UTF8
        $currentGroup = $group
    }

    Get-Content -Path $file.FullName -Encoding UTF8 | Add-Content -Path $generatedCollection -Encoding UTF8
    "" | Add-Content -Path $generatedCollection -Encoding UTF8
}

$outputName = "recipe-collection.pdf"
if ($PrintMode -eq "kitchen") {
    $outputName = "recipe-collection-kitchen.pdf"
}
$outputFile = Join-Path $outputDir $outputName
& pandoc $generatedCollection -o $outputFile --from markdown --template $templatePath --toc --pdf-engine=xelatex @metadataArgs
if ($LASTEXITCODE -ne 0) {
    throw "Pandoc failed while building full collection."
}
Write-Host "Built: $outputFile"
