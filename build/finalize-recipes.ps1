$ErrorActionPreference = 'Stop'
$root = 'C:\Users\tscha\OneDrive\Dokumente\Rezepte'
Set-Location $root

$recipeFiles = Get-ChildItem -Path 'recipes' -Recurse -File -Filter *.md

# 1) Remove Legacy Import section from all recipe files.
foreach ($file in $recipeFiles) {
  $text = Get-Content -Path $file.FullName -Raw -Encoding UTF8
  $newText = [regex]::Replace($text, '(?s)\r?\n## Legacy Import\r?\n.*$', "`r`n")
  if ($newText -ne $text) {
    Set-Content -Path $file.FullName -Value $newText.TrimEnd() -Encoding UTF8
  }
}

# 2) Recategorize wraps to main meat.
$oldWraps = Join-Path $root 'recipes/03-main-vegetarian/wraps.md'
$newWraps = Join-Path $root 'recipes/05-main-meat/wraps.md'
if (Test-Path $oldWraps) {
  New-Item -ItemType Directory -Path (Split-Path -Parent $newWraps) -Force | Out-Null
  Move-Item -LiteralPath $oldWraps -Destination $newWraps -Force
}
if (Test-Path $newWraps) {
  $wrapsText = Get-Content -Path $newWraps -Raw -Encoding UTF8
  $wrapsText = [regex]::Replace($wrapsText, '(?m)^category:\s*.*$', 'category: 05-main-meat')
  Set-Content -Path $newWraps -Value $wrapsText.TrimEnd() -Encoding UTF8
}

# 3) Update migration-status entries.
$csvPath = Join-Path $root 'migration-status.csv'
$rows = Import-Csv -Path $csvPath
foreach ($row in $rows) {
  if ($row.new_markdown -eq 'recipes/03-main-vegetarian/wraps.md') {
    $row.new_markdown = 'recipes/05-main-meat/wraps.md'
    $row.category = '05-main-meat'
    $row.status = 'finalized'
    $row.notes = 'legacy import removed; recategorized to main meat'
    continue
  }

  if ($row.status -like 'cleaned-pass-*') {
    $row.status = 'finalized'
    if ($row.new_markdown -eq 'recipes/03-main-vegetarian/spinatmuffins-mit-roestiboden.md') {
      $row.notes = 'legacy import removed; source mismatch unresolved; needs proper source restore'
    } elseif ($row.new_markdown -eq 'recipes/01-starters-mezze/zucchini-in-carpione.md' -or $row.new_markdown -eq 'recipes/03-main-vegetarian/auberginen-tamarinde-auflauf.md') {
      $row.notes = 'legacy import removed; source mismatch unresolved'
    } else {
      $row.notes = 'legacy import removed; structured recipe finalized'
    }
  }
}
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

# 4) Regenerate collection index from existing files.
$categoryNames = @{
  '01-starters-mezze' = '01 Starters and Mezze'
  '02-soups-stews' = '02 Soups and Stews'
  '03-main-vegetarian' = '03 Main Vegetarian'
  '04-main-fish-seafood' = '04 Main Fish and Seafood'
  '05-main-meat' = '05 Main Meat'
  '06-pasta-rice-grains' = '06 Pasta Rice and Grains'
  '07-bakes-savory' = '07 Savory Bakes'
  '08-bread-dough-basics' = '08 Bread and Dough Basics'
  '09-salads-sides' = '09 Salads and Sides'
  '10-desserts-sweets' = '10 Desserts and Sweets'
  '11-breakfast-brunch' = '11 Breakfast and Brunch'
  '12-drinks' = '12 Drinks'
  '99-base-recipes' = '99 Base Recipes'
}

$recipesByCategory = @{}
foreach ($key in $categoryNames.Keys) {
  $recipesByCategory[$key] = New-Object System.Collections.ArrayList
}

$allRecipes = Get-ChildItem -Path 'recipes' -Recurse -File -Filter *.md | Sort-Object FullName
foreach ($file in $allRecipes) {
  $cat = Split-Path -Leaf (Split-Path -Parent $file.FullName)
  if (-not $recipesByCategory.ContainsKey($cat)) { continue }

  $title = $null
  $head = Get-Content -Path $file.FullName -TotalCount 40 -Encoding UTF8
  foreach ($line in $head) {
    if ($line -match '^title:\s*(.+)$') {
      $title = $Matches[1].Trim()
      break
    }
  }
  if (-not $title) {
    $title = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
  }
  [void]$recipesByCategory[$cat].Add($title)
}

$indexLines = @()
$indexLines += '# Collection Index'
$indexLines += ''
$indexLines += 'This file is generated from current recipe files and grouped by category.'
$indexLines += ''

foreach ($cat in ($categoryNames.Keys | Sort-Object)) {
  $indexLines += ('## ' + $categoryNames[$cat])
  $indexLines += ''
  $titles = @($recipesByCategory[$cat] | Sort-Object)
  if ($titles.Count -eq 0) {
    $indexLines += '- (none yet)'
  } else {
    foreach ($t in $titles) {
      $indexLines += ('- ' + $t)
    }
  }
  $indexLines += ''
}

Set-Content -Path 'collection-index.md' -Value ($indexLines -join "`r`n") -Encoding UTF8

Write-Output 'finalization completed'
