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

function Get-CategoryDisplayName {
    param([string]$CategorySlug)

    $map = @{
        "01-starters-mezze" = "Starters and Mezze"
        "02-soups-stews" = "Soups and Stews"
        "03-main-vegetarian" = "Main Vegetarian"
        "04-main-fish-seafood" = "Main Fish and Seafood"
        "05-main-meat" = "Main Meat"
        "06-pasta-rice-grains" = "Pasta Rice and Grains"
        "07-bakes-savory" = "Savory Bakes"
        "08-bread-dough-basics" = "Bread and Dough Basics"
        "09-salads-sides" = "Salads and Sides"
        "10-desserts-sweets" = "Desserts and Sweets"
        "11-breakfast-brunch" = "Breakfast and Brunch"
        "12-drinks" = "Drinks"
        "99-base-recipes" = "Base Recipes"
    }

    if ($map.ContainsKey($CategorySlug)) {
        return $map[$CategorySlug]
    }

    return $CategorySlug
}

function Convert-SlugToTitle {
    param([string]$Slug)

    $parts = $Slug -split '-'
    $out = @()
    foreach ($p in $parts) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        if ($p.Length -eq 1) {
            $out += $p.ToUpper()
        } else {
            $out += ($p.Substring(0, 1).ToUpper() + $p.Substring(1))
        }
    }
    return ($out -join ' ')
}

function Parse-RecipeFile {
    param([string]$FilePath)

    $raw = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $fallbackTitle = Convert-SlugToTitle -Slug ([System.IO.Path]::GetFileNameWithoutExtension($FilePath))
    $title = $fallbackTitle
    $body = $raw

    if ($raw -match '^(?s)---\r?\n(.*?)\r?\n---\r?\n(.*)$') {
        $frontmatter = $Matches[1]
        $body = $Matches[2]

        if ($frontmatter -match '(?m)^title:\s*(.+)$') {
            $candidate = $Matches[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($candidate)) {
                $title = $candidate
            }
        }
    }

    return @{ Title = $title; Body = $body.Trim() }
}

function Shift-MarkdownHeadings {
    param(
        [string]$Text,
        [int]$ShiftBy
    )

    if ($ShiftBy -eq 0) {
        return $Text
    }

    return [regex]::Replace($Text, '(?m)^(#{1,6})(\s+)', {
        param($m)
        $newLevel = [Math]::Min(6, $m.Groups[1].Value.Length + $ShiftBy)
        return ('#' * $newLevel) + $m.Groups[2].Value
    })
}

function Remove-SummarySection {
    param([string]$Text)

    # Remove "## Summary" section content so rendered recipes start directly
    # with actionable sections like Ingredients and Preparation.
    $result = [regex]::Replace($Text, '(?ms)^##\s+Summary\s*\r?\n.*?(?=^##\s+|\z)', '')
    return $result.Trim()
}

if (-not (Test-Command "pandoc")) {
    throw "Pandoc is not installed or not in PATH."
}

$subtitle = "Binder Mode"
if ($PrintMode -eq "kitchen") {
    $subtitle = "Kitchen Mode"
}

$metadataArgs = @(
    "--metadata", "title=Recipe Collection",
    "--metadata", "subtitle=$subtitle",
    "--metadata", "date=$(Get-Date -Format yyyy-MM-dd)"
)

$pandocCommonArgs = @(
    "--from", "markdown+raw_tex",
    "--template", $templatePath,
    "--toc",
    "--toc-depth=2",
    "--pdf-engine=xelatex"
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

    $singleRendered = Join-Path $buildDir "_single.generated.md"
    $parsed = Parse-RecipeFile -FilePath $fullRecipePath

    "# $($parsed.Title)" | Set-Content -Path $singleRendered -Encoding UTF8
    "" | Add-Content -Path $singleRendered -Encoding UTF8
    $singleBody = Remove-SummarySection -Text $parsed.Body
    (Shift-MarkdownHeadings -Text $singleBody -ShiftBy 0) | Add-Content -Path $singleRendered -Encoding UTF8

    & pandoc $singleRendered -o $outputFile @pandocCommonArgs @metadataArgs
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

"" | Set-Content -Path $generatedCollection -Encoding UTF8

$currentGroup = ""
foreach ($file in $recipeFiles) {
    $group = Split-Path -Leaf (Split-Path -Parent $file.FullName)
    if ($group -ne $currentGroup) {
        if ($currentGroup -ne "") {
            "\newpage" | Add-Content -Path $generatedCollection -Encoding UTF8
            "" | Add-Content -Path $generatedCollection -Encoding UTF8
        }
        "# $(Get-CategoryDisplayName -CategorySlug $group)" | Add-Content -Path $generatedCollection -Encoding UTF8
        "" | Add-Content -Path $generatedCollection -Encoding UTF8
        if ($PrintMode -eq "elegant") {
            "\newpage" | Add-Content -Path $generatedCollection -Encoding UTF8
            "" | Add-Content -Path $generatedCollection -Encoding UTF8
        }
        $currentGroup = $group
    }

    $parsed = Parse-RecipeFile -FilePath $file.FullName

    "## $($parsed.Title)" | Add-Content -Path $generatedCollection -Encoding UTF8
    "" | Add-Content -Path $generatedCollection -Encoding UTF8

    $renderBody = Remove-SummarySection -Text $parsed.Body
    (Shift-MarkdownHeadings -Text $renderBody -ShiftBy 1) | Add-Content -Path $generatedCollection -Encoding UTF8
    "" | Add-Content -Path $generatedCollection -Encoding UTF8

    if ($PrintMode -eq "elegant") {
        "\newpage" | Add-Content -Path $generatedCollection -Encoding UTF8
        "" | Add-Content -Path $generatedCollection -Encoding UTF8
    }
}

$outputName = "recipe-collection.pdf"
if ($PrintMode -eq "kitchen") {
    $outputName = "recipe-collection-kitchen.pdf"
}
$outputFile = Join-Path $outputDir $outputName
& pandoc $generatedCollection -o $outputFile @pandocCommonArgs @metadataArgs
if ($LASTEXITCODE -ne 0) {
    throw "Pandoc failed while building full collection."
}
Write-Host "Built: $outputFile"
