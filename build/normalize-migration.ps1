$ErrorActionPreference = 'Stop'
$root = 'C:\Users\tscha\OneDrive\Dokumente\Rezepte'
Set-Location $root

$csvPath = Join-Path $root 'migration-status.csv'
$rows = Import-Csv -Path $csvPath

$fixes = @(
  @{Legacy='Gefüllte Pepperoni aus dem Ofen.docx'; Category='01-starters-mezze'; Slug='gefuellte-pepperoni-aus-dem-ofen'},
  @{Legacy='Geröstete Pepperoni Salat mit Kichererbsen.docx'; Category='01-starters-mezze'; Slug='geroestete-pepperoni-salat-mit-kichererbsen'},
  @{Legacy='Glühwein, non-alc.docx'; Category='12-drinks'; Slug='gluehwein-non-alc'},
  @{Legacy='Hörnli-Auflauf.docx'; Category='06-pasta-rice-grains'; Slug='hoernli-auflauf'},
  @{Legacy='Köfte.docx'; Category='05-main-meat'; Slug='koefte'},
  @{Legacy='Kümmel Reis.docx'; Category='06-pasta-rice-grains'; Slug='kuemmel-reis'},
  @{Legacy='Pizzabeläge.docx'; Category='99-base-recipes'; Slug='pizzabelaege'},
  @{Legacy='Rösti.docx'; Category='09-salads-sides'; Slug='roesti'},
  @{Legacy='Rüeblisalat mit Rosinli.docx'; Category='09-salads-sides'; Slug='rueeblisalat-mit-rosinli'},
  @{Legacy='Spaghetti mit Spinat-Käse-Sauce.docx'; Category='06-pasta-rice-grains'; Slug='spaghetti-mit-spinat-kaese-sauce'},
  @{Legacy='Spinatmuffins mit Röstiboden.docx'; Category='03-main-vegetarian'; Slug='spinatmuffins-mit-roestiboden'},
  @{Legacy='Tomaten-Sweetpotato-Rüebli-Sauce.docx'; Category='99-base-recipes'; Slug='tomaten-sweetpotato-rueebli-sauce'},
  @{Legacy='Wähe.docx'; Category='07-bakes-savory'; Slug='waehe'}
)

$changed = 0
foreach ($fix in $fixes) {
  $row = $rows | Where-Object { $_.legacy_docx -eq $fix.Legacy } | Select-Object -First 1
  if ($null -eq $row) { continue }

  $oldRel = $row.new_markdown
  $newRel = "recipes/$($fix.Category)/$($fix.Slug).md"
  $oldPath = Join-Path $root $oldRel
  $newPath = Join-Path $root $newRel

  if ($oldRel -ne $newRel) {
    if (Test-Path $oldPath) {
      New-Item -ItemType Directory -Path (Split-Path -Parent $newPath) -Force | Out-Null
      if (Test-Path $newPath) { Remove-Item -LiteralPath $newPath -Force }
      Move-Item -LiteralPath $oldPath -Destination $newPath -Force
    }
  }

  if (Test-Path $newPath) {
    $content = Get-Content -Path $newPath -Raw -Encoding UTF8
    $content = [regex]::Replace($content, '(?m)^slug:\s*.*$', "slug: $($fix.Slug)")
    $content = [regex]::Replace($content, '(?m)^category:\s*.*$', "category: $($fix.Category)")
    Set-Content -Path $newPath -Value $content -Encoding UTF8
  }

  $row.new_markdown = $newRel
  $row.category = $fix.Category
  $row.status = 'imported-draft'
  $row.notes = 'auto-converted with pandoc; archive original deleted; slug/category normalized'
  $changed++
}

$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Output ("Normalized entries: " + $changed)
