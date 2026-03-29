$ErrorActionPreference = 'Stop'
$root = 'C:\Users\tscha\OneDrive\Dokumente\Rezepte'
Set-Location $root

if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
  throw 'Pandoc is required for migration but is not available in PATH.'
}

function Normalize-Slug([string]$name) {
  $s = $name.ToLowerInvariant()
  $s = $s.Replace('ä', 'ae').Replace('ö', 'oe').Replace('ü', 'ue').Replace('ß', 'ss')
  $s = $s.Replace('é', 'e').Replace('è', 'e').Replace('ê', 'e').Replace('à', 'a').Replace('ô', 'o')
  $s = $s -replace '[^a-z0-9]+', '-'
  $s = $s.Trim('-')
  return $s
}

$categoryMap = @{
  'Fotzelschnitten mit Apfelmus' = '10-desserts-sweets'
  'GANZ VIELE GERICHTE' = '99-base-recipes'
  'Gefüllte Pepperoni aus dem Ofen' = '01-starters-mezze'
  'Geröstete Pepperoni Salat mit Kichererbsen' = '01-starters-mezze'
  'Glühwein, non-alc' = '12-drinks'
  'Hack-Tomaten-Kartoffeln Eintopf' = '02-soups-stews'
  'Hefeteig Zopfteig' = '08-bread-dough-basics'
  'Hörnli-Auflauf' = '06-pasta-rice-grains'
  'Köfte' = '05-main-meat'
  'Kümmel Reis' = '06-pasta-rice-grains'
  'Omeletten' = '11-breakfast-brunch'
  'Pandankuchen' = '10-desserts-sweets'
  'Pasta mit Pesto' = '06-pasta-rice-grains'
  'Pesto Salat mit Gurke und Cherrytomaten' = '09-salads-sides'
  'Pide mit Spinat und Feta' = '07-bakes-savory'
  'Pizza' = '07-bakes-savory'
  'Pizzabeläge' = '99-base-recipes'
  'Quiche vegi' = '03-main-vegetarian'
  'Quinoasalat' = '09-salads-sides'
  'Risotto' = '06-pasta-rice-grains'
  'Rösti' = '09-salads-sides'
  'Rüeblisalat mit Rosinli' = '09-salads-sides'
  'Safranbrot' = '08-bread-dough-basics'
  'Spaghetti mit Spinat-Käse-Sauce' = '06-pasta-rice-grains'
  'Spinat-Kartoffel-Auflauf' = '03-main-vegetarian'
  'Spinatmuffins mit Röstiboden' = '03-main-vegetarian'
  'Tomaten-Sweetpotato-Rüebli-Sauce' = '99-base-recipes'
  'Tomaten-Thunfisch Salat' = '04-main-fish-seafood'
  'Tzaziki' = '01-starters-mezze'
  'Vitello-Tonato' = '01-starters-mezze'
  'Wraps' = '03-main-vegetarian'
  'Wähe' = '07-bakes-savory'
  'Zucchini in Carpione' = '01-starters-mezze'
}

$defaultTagsByCategory = @{
  '01-starters-mezze' = 'starter,mezze'
  '02-soups-stews' = 'soup,stew'
  '03-main-vegetarian' = 'vegetarian,main'
  '04-main-fish-seafood' = 'fish,main'
  '05-main-meat' = 'meat,main'
  '06-pasta-rice-grains' = 'pasta-rice,main'
  '07-bakes-savory' = 'savory,bake'
  '08-bread-dough-basics' = 'bread,dough'
  '09-salads-sides' = 'salad,side'
  '10-desserts-sweets' = 'dessert,sweet'
  '11-breakfast-brunch' = 'breakfast,brunch'
  '12-drinks' = 'drink,non-alcoholic'
  '99-base-recipes' = 'base,component'
}

$docxFiles = Get-ChildItem -Path (Join-Path $root 'archive/docx-originals') -Recurse -File -Filter *.docx |
  Where-Object { $_.Name -ne 'Vorlage.docx' }

$migrated = @()
foreach ($file in $docxFiles) {
  $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
  $category = '99-base-recipes'
  if ($categoryMap.ContainsKey($baseName)) {
    $category = $categoryMap[$baseName]
  }

  $slug = Normalize-Slug $baseName
  $destDir = Join-Path $root ("recipes/" + $category)
  New-Item -ItemType Directory -Path $destDir -Force | Out-Null
  $dest = Join-Path $destDir ($slug + '.md')

  if (Test-Path $dest) {
    Remove-Item -LiteralPath $file.FullName -Force
    continue
  }

  $tmp = Join-Path $root ("build/_tmp-" + $slug + '.md')
  & pandoc $file.FullName -f docx -t gfm -o $tmp
  if ($LASTEXITCODE -ne 0) { throw "Pandoc conversion failed for $($file.FullName)" }

  $imported = Get-Content -Path $tmp -Raw -Encoding UTF8
  Remove-Item -LiteralPath $tmp -Force

  $tags = 'base,component'
  if ($defaultTagsByCategory.ContainsKey($category)) {
    $tags = $defaultTagsByCategory[$category]
  }

  $tagLines = ""
  foreach ($tag in ($tags -split ',')) {
    $tagLines += "  - " + $tag.Trim() + "`r`n"
  }

  $frontmatter = "---`r`n" +
                 "title: " + $baseName + "`r`n" +
                 "slug: " + $slug + "`r`n" +
                 "category: " + $category + "`r`n" +
                 "cuisine: unknown`r`n" +
                 "servings: unknown`r`n" +
                 "prep_time: unknown`r`n" +
                 "cook_time: unknown`r`n" +
                 "total_time: unknown`r`n" +
                 "difficulty: unknown`r`n" +
                 "tags:`r`n" +
                 $tagLines +
                 "equipment:`r`n" +
                 "  - unknown`r`n" +
                 "source: migrated from docx`r`n" +
                 "status: imported-draft`r`n" +
                 "---`r`n`r`n" +
                 "## Summary`r`n`r`n" +
                 "Migration draft imported from DOCX. Validate quantities and steps against your original notes.`r`n`r`n" +
                 "## Imported Content`r`n`r`n"

  Set-Content -Path $dest -Value ($frontmatter + $imported + "`r`n") -Encoding UTF8
  Remove-Item -LiteralPath $file.FullName -Force

  $migrated += [pscustomobject]@{
    legacy_docx = $file.Name
    new_markdown = ("recipes/" + $category + "/" + $slug + ".md")
    category = $category
    status = 'imported-draft'
    notes = 'auto-converted with pandoc; archive original deleted'
  }
}

$csvPath = Join-Path $root 'migration-status.csv'
$existing = @()
if (Test-Path $csvPath) { $existing = Import-Csv -Path $csvPath }

$merged = @($existing)
foreach ($newRow in $migrated) {
  $match = $null
  foreach ($row in $merged) {
    if ($row.new_markdown -eq $newRow.new_markdown -or $row.legacy_docx -eq $newRow.legacy_docx) {
      $match = $row
      break
    }
  }

  if ($null -ne $match) {
    $match.new_markdown = $newRow.new_markdown
    $match.category = $newRow.category
    $match.status = $newRow.status
    $match.notes = $newRow.notes
  } else {
    $merged += $newRow
  }
}

$merged | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Output ("Migrated files: " + $migrated.Count)
