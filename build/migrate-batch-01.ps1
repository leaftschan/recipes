$ErrorActionPreference = 'Stop'
$root = 'C:\Users\tscha\OneDrive\Dokumente\Rezepte'
Set-Location $root

if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
  throw 'Pandoc is required for migration but is not available in PATH.'
}

$migrations = @(
  [pscustomobject]@{Docx='archive/docx-originals/Afghanisches Ragout mit Quitten und Backpflaumen.docx'; Category='02-soups-stews'; Slug='afghanisches-ragout-mit-quitten-und-backpflaumen'; Cuisine='middle-eastern'; Tags='stew,savory'; Servings='4'},
  [pscustomobject]@{Docx='archive/docx-originals/Auberginen-Tamarinde Auflauf.docx'; Category='03-main-vegetarian'; Slug='auberginen-tamarinde-auflauf'; Cuisine='mediterranean'; Tags='vegetarian,bake'; Servings='4'},
  [pscustomobject]@{Docx='archive/docx-originals/Auberginenauflauf mit Feta.docx'; Category='03-main-vegetarian'; Slug='auberginenauflauf-mit-feta'; Cuisine='mediterranean'; Tags='vegetarian,bake'; Servings='4'},
  [pscustomobject]@{Docx='archive/docx-originals/Backkartoffeln mit Rosmarin.docx'; Category='09-salads-sides'; Slug='backkartoffeln-mit-rosmarin'; Cuisine='european'; Tags='side,oven'; Servings='4'},
  [pscustomobject]@{Docx='archive/docx-originals/Balsamico Fenchel.docx'; Category='09-salads-sides'; Slug='balsamico-fenchel'; Cuisine='european'; Tags='side,vegetarian'; Servings='4'},
  [pscustomobject]@{Docx='archive/docx-originals/Couscous-Salat.docx'; Category='09-salads-sides'; Slug='couscous-salat'; Cuisine='mediterranean'; Tags='salad,grain'; Servings='4'},
  [pscustomobject]@{Docx='archive/docx-originals/Flammkuchen.docx'; Category='07-bakes-savory'; Slug='flammkuchen'; Cuisine='french'; Tags='bake,savory'; Servings='4'},
  [pscustomobject]@{Docx='archive/docx-originals/Fleisch-Brot.docx'; Category='05-main-meat'; Slug='fleisch-brot'; Cuisine='european'; Tags='meat,bake'; Servings='6'},
  [pscustomobject]@{Docx='archive/docx-originals/Gurkensalat.docx'; Category='09-salads-sides'; Slug='gurkensalat'; Cuisine='european'; Tags='salad,side'; Servings='4'},
  [pscustomobject]@{Docx='archive/docx-originals/Kartoffelsalat.docx'; Category='09-salads-sides'; Slug='kartoffelsalat'; Cuisine='european'; Tags='salad,side'; Servings='4'},
  [pscustomobject]@{Docx='archive/docx-originals/Köfte.docx'; Category='05-main-meat'; Slug='koefte'; Cuisine='turkish'; Tags='meat,pan'; Servings='4'},
  [pscustomobject]@{Docx='archive/docx-originals/Linsensalat.docx'; Category='09-salads-sides'; Slug='linsensalat'; Cuisine='mediterranean'; Tags='salad,legume'; Servings='4'},
  [pscustomobject]@{Docx='archive/docx-originals/zum ausdrucken/cocos-pandan-rice.docx'; Category='10-desserts-sweets'; Slug='cocos-pandan-rice'; Cuisine='asian'; Tags='sweet,rice'; Servings='4'},
  [pscustomobject]@{Docx='archive/docx-originals/zum ausdrucken/rigatoni-chickpea Auflauf mit Zucchini und Feta.docx'; Category='06-pasta-rice-grains'; Slug='rigatoni-chickpea-auflauf-mit-zucchini-und-feta'; Cuisine='mediterranean'; Tags='pasta,bake'; Servings='4'}
)

function To-TitleCase([string]$slug) {
  $parts = $slug -split '-'
  $out = @()
  foreach ($p in $parts) {
    if ([string]::IsNullOrWhiteSpace($p)) { continue }
    if ($p.Length -eq 1) { $out += $p.ToUpper() }
    else { $out += ($p.Substring(0,1).ToUpper() + $p.Substring(1)) }
  }
  return ($out -join ' ')
}

$migrated = @()
foreach ($m in $migrations) {
  $src = Join-Path $root $m.Docx
  if (-not (Test-Path $src)) { continue }

  $destDir = Join-Path $root ("recipes/" + $m.Category)
  New-Item -ItemType Directory -Path $destDir -Force | Out-Null
  $dest = Join-Path $destDir ($m.Slug + '.md')
  $tmp = Join-Path $root ("build/_tmp-" + $m.Slug + '.md')

  & pandoc $src -f docx -t gfm -o $tmp
  if ($LASTEXITCODE -ne 0) { throw "Pandoc conversion failed for $($m.Docx)" }

  $imported = Get-Content -Path $tmp -Raw -Encoding UTF8
  Remove-Item -LiteralPath $tmp -Force

  $title = To-TitleCase $m.Slug
  $tagLines = ""
  foreach ($tag in ($m.Tags -split ',')) {
    $tagLines += "  - " + $tag.Trim() + "`r`n"
  }

  $frontmatter = "---`r`n" +
                 "title: " + $title + "`r`n" +
                 "slug: " + $m.Slug + "`r`n" +
                 "category: " + $m.Category + "`r`n" +
                 "cuisine: " + $m.Cuisine + "`r`n" +
                 "servings: " + $m.Servings + "`r`n" +
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

  Remove-Item -LiteralPath $src -Force

  $migrated += [pscustomobject]@{
    legacy_docx = [System.IO.Path]::GetFileName($src)
    new_markdown = ("recipes/" + $m.Category + "/" + $m.Slug + ".md")
    category = $m.Category
    status = 'imported-draft'
    notes = 'auto-converted with pandoc; archive original deleted'
  }
}

$csvPath = Join-Path $root 'migration-status.csv'
$existing = @()
if (Test-Path $csvPath) {
  $existing = Import-Csv -Path $csvPath
}

foreach ($row in $existing) {
  if ($row.new_markdown -in @('recipes/10-desserts-sweets/bananenbrot.md','recipes/03-main-vegetarian/miso-auberginen.md','recipes/04-main-fish-seafood/thunfisch-frikadellen.md')) {
    $row.status = 'imported-draft'
    $row.notes = 'manual draft created; archive original deleted'
  }
}

$merged = @($existing)
foreach ($newRow in $migrated) {
  $already = $false
  foreach ($row in $merged) {
    if ($row.new_markdown -eq $newRow.new_markdown) { $already = $true; break }
  }
  if (-not $already) { $merged += $newRow }
}

$merged | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$manualArchiveDeletes = @(
  'archive/docx-originals/Bananenbrot.docx',
  'archive/docx-originals/Miso-Auberginen.docx',
  'archive/docx-originals/Thunfisch-Frikadellen.docx'
)
foreach ($rel in $manualArchiveDeletes) {
  $p = Join-Path $root $rel
  if (Test-Path $p) { Remove-Item -LiteralPath $p -Force }
}

Write-Output ("Migrated files: " + $migrated.Count)
