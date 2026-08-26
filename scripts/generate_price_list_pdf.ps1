#requires -Version 5.1
# Generates site/assets/kdc-price-list-2026.pdf directly (no external PDF libraries needed).
# Pricing data and colors are transcribed from site/pricing.html and site/css/styles.css
# (--green, --green-light, --black, --gray-200) so the PDF matches the live site's design
# and never drifts from it. Standard PDF fonts only (Helvetica/Helvetica-Bold/Times-Bold) —
# no font embedding — so headings use Times-Bold to echo the site's serif (Lora) headings.

$ErrorActionPreference = "Stop"
$ic = [System.Globalization.CultureInfo]::InvariantCulture

$outPath = Join-Path $PSScriptRoot "..\site\assets\kdc-price-list-2026.pdf"

# ---- Brand colors (from site/css/styles.css :root) ------------------------
$colBlack      = @(0.102, 0.102, 0.102)   # --black #1a1a1a
$colGreen      = @(0.239, 0.420, 0.310)   # --green #3d6b4f
$colGreenLight = @(0.918, 0.949, 0.925)   # --green-light #eaf2ec
$colGray400    = @(0.627, 0.627, 0.604)   # --gray-400 #a0a09a
$colGray200    = @(0.886, 0.886, 0.871)   # --gray-200 #e2e2de
$colWhite      = @(1, 1, 1)

# ---- Helvetica glyph widths (per 1000 em, standard AFM metrics) -----------
# Used to right-align price text and to indent text after the bold "Important:" lead-in.
$helvW = @{}
$helvBW = @{}
$defW = @(
    278,278,355,556,556,889,667,191,333,333,389,584,278,333,278,278,
    556,556,556,556,556,556,556,556,556,556,278,278,584,584,584,556,
    1015,667,667,722,722,667,611,778,722,278,500,667,556,833,722,778,
    667,778,722,667,611,722,667,944,667,667,611,278,278,278,469,556,
    333,556,556,500,556,556,278,556,556,222,222,500,222,833,556,556,
    556,556,333,500,278,556,500,722,500,500,500,334,260,334,584
)
$boldW = @(
    278,333,474,556,556,889,722,238,333,333,389,584,278,333,278,278,
    556,556,556,556,556,556,556,556,556,556,333,333,584,584,584,611,
    975,722,722,722,722,667,611,778,722,278,556,722,611,833,722,778,
    667,778,722,667,611,722,667,944,667,667,611,333,278,333,584,556,
    333,556,611,556,611,556,333,611,611,278,278,556,278,889,611,611,
    611,611,389,556,333,611,556,778,556,556,500,389,280,389,584
)
for ($i = 0; $i -lt $defW.Count; $i++) { $helvW[32 + $i] = $defW[$i] }
for ($i = 0; $i -lt $boldW.Count; $i++) { $helvBW[32 + $i] = $boldW[$i] }

function Get-TextWidth([string]$text, [hashtable]$table, [double]$size) {
    $units = 0
    foreach ($ch in $text.ToCharArray()) {
        $code = [int]$ch
        if ($table.ContainsKey($code)) { $units += $table[$code] } else { $units += 556 }
    }
    return ($units * $size / 1000.0)
}

function N([double]$v) { return [Math]::Round($v, 2).ToString($ic) }

# ---- Content model ----------------------------------------------------
$categories = @(
    @{ Name = "Examinations & Diagnostics"; Rows = @(
        @("Standard Check-up & Clean + Fluoride Package", "`$195"),
        @("Check-up & Clean + X-rays (Bitewings) Package", "`$265"),
        @("Examination", "`$45"),
        @("Emergency Consultation", "`$45"),
        @("Bitewing X-rays / Periapical", "`$35"),
        @("Full Mouth X-rays (OPG/LAT) - referred externally", "Bulk Billed"),
        @("Models / 3D Scans (for planning purposes only, fees apply if requested)", "`$0"),
        @("Intraoral Photographs", "`$0")
    )},
    @{ Name = "Preventive Care"; Rows = @(
        @("Fissure Sealants (per tooth)", "`$65"),
        @("Custom Mouthguard (Sports)", "`$280"),
        @("Custom Night Guard / Splint", "`$690")
    )},
    @{ Name = "Gum Care / Periodontics"; Rows = @(
        @("Gum Chart Assessment", "`$65"),
        @("Deep Gum Clean - per quadrant (Full Mouth x 4)", "`$250"),
        @("Supportive Gum Therapy - per appointment (every 3 months)", "`$250"),
        @("Periodontal Debridement - per tooth", "`$50")
    )},
    @{ Name = "Restorative Dentistry (Fillings)"; Rows = @(
        @("Composite Filling (1-5 surfaces)", "`$175 - `$350+"),
        @("Temporary Filling", "`$150")
    )},
    @{ Name = "Root Canal Treatment"; Rows = @(
        @("Emergency Drain / Nerve Removal", "`$350"),
        @("Anterior Tooth Root Canal (incl. filling)", "`$1,420"),
        @("Premolar Root Canal (incl. filling)", "`$1,695"),
        @("Molar Root Canal (incl. filling) - +`$250 per extra root", "`$1,945"),
        @("Core Build-up (as required)", "`$200"),
        @("Cast Post & Core", "`$650"),
        @("Post-RCT Overlay", "`$450 - `$850"),
        @("Post-RCT Crown", "`$1,550"),
        @("Internal Bleaching - per tooth", "`$490"),
        @("Retreatment of Root Canal", "Referral Required")
    )},
    @{ Name = "Extractions & Oral Surgery"; Rows = @(
        @("Simple Extraction", "`$290"),
        @("Surgical Extraction", "`$550+"),
        @("X-ray - per exposure", "`$35"),
        @("Wisdom Tooth Extraction", "`$550+")
    )},
    @{ Name = "Crowns, Bridges & Onlays"; Rows = @(
        @("Porcelain Crown", "`$1,550"),
        @("Zirconia Crown", "`$1,550"),
        @("Bridge (per unit)", "`$1,450"),
        @("Crown Re-cement", "`$250"),
        @("Onlay / Inlay (1-5 surfaces)", "`$450 - `$850")
    )},
    @{ Name = "Dentures"; Rows = @(
        @("Consultation", "Complimentary"),
        @("Full Denture - Acrylic / Partial Metal (Upper or Lower)", "`$2,300"),
        @("Partial Denture (1-12 teeth)", "`$1,150 - `$2,300"),
        @("Denture Repair (Full or Partial)", "`$590"),
        @("Denture Reline (Full or Partial)", "`$590"),
        @("Denture Adjustment", "`$65")
    )},
    @{ Name = "Dental Implants"; Rows = @(
        @("Consultation", "Complimentary"),
        @("Full Mouth X-rays (OPG/LAT, referred externally) / 3D CBCT", "Bulk Billed / CBCT ~`$250"),
        @("Single Implant, Abutment & Crown Package - per tooth", "`$6,000"),
        @("Implant Only", "`$3,450"),
        @("Implant Crown Only (implant placed elsewhere)", "`$2,550"),
        @("Implant Bridge Pontic - per tooth", "`$2,450"),
        @("Temporary Tooth in Removable Retainer - per tooth + retainer", "`$50ea + `$190"),
        @("Immediate Extraction + Implant Package", "TBC")
    )},
    @{ Name = "Cosmetic Dentistry"; Rows = @(
        @("Consultation", "Complimentary"),
        @("Teeth Whitening - In-chair", "`$490"),
        @("Take-home Whitening Kit (2 x Gels & Trays)", "`$250"),
        @("Edge Bonding (Composite)", "From `$350"),
        @("Composite Veneers", "From `$600"),
        @("Porcelain Veneers / Crowns", "`$1,550+")
    )},
    @{ Name = "Orthodontics - Braces & Clear Aligners"; Rows = @(
        @("Consultation", "Complimentary"),
        @("Full Treatment Fee Estimate", "`$4,250 - `$8,150"),
        @("Appliances / Functional Appliances / Expanders", "From `$2,500"),
        @("Phase 1 & Phase 2 Course of Orthodontics Package", "`$9,350"),
        @("Retainers - Single Removable or Wire", "`$190 ea"),
        @("Retainers - Dual Removable or Wire", "`$350"),
        @("3 x Removable Retainer Package - Single / Dual", "`$440 - `$700")
    )}
)

$noteLines = @(
    "This fee guide provides an estimate only. Exact costs are provided following consultation",
    "and a personalised treatment plan. Payment is due at the time of service unless prior",
    "arrangements have been made. We accept cash, EFTPOS, credit card, and payment plans.",
    "Health fund benefits apply - please check with your fund for your level of cover."
)

# ---- Layout constants -------------------------------------------------
$pageWidth = 595
$pageHeight = 842
$marginLeft = 50
$marginRight = 545
$contentWidth = $marginRight - $marginLeft
$topY = 792
$bottomLimit = 60
$kappa = 0.5523

$pages = @()
$current = New-Object System.Collections.Generic.List[string]
$y = $topY

function Flush-Page {
    $script:pages += ,(@($script:current.ToArray()) -join "`n")
    $script:current = New-Object System.Collections.Generic.List[string]
    $script:y = $topY
}

function Ensure-Space([double]$need) {
    if (($script:y - $need) -lt $bottomLimit) { Flush-Page }
}

function Add([string]$op) { [void]$script:current.Add($op) }

function Set-Fill([double[]]$c) { Add "$(N $c[0]) $(N $c[1]) $(N $c[2]) rg" }
function Set-Stroke([double[]]$c) { Add "$(N $c[0]) $(N $c[1]) $(N $c[2]) RG" }

function Draw-Text([string]$font, [double]$size, [double]$x, [double]$y, [string]$text, [double[]]$color) {
    Set-Fill $color
    Add "BT"
    Add "/$font $(N $size) Tf"
    Add "1 0 0 1 $(N $x) $(N $y) Tm"
    Add "($([regex]::Replace($text, '[\\()]', '\$0'))) Tj"
    Add "ET"
}

function Draw-TextRightAligned([string]$font, [double]$size, [double]$rightX, [double]$y, [string]$text, [double[]]$color, [hashtable]$widths) {
    $w = Get-TextWidth $text $widths $size
    Draw-Text $font $size ($rightX - $w) $y $text $color
}

function Draw-Line([double]$x1, [double]$y1, [double]$x2, [double]$y2, [double]$width, [double[]]$color) {
    Set-Stroke $color
    Add "$(N $width) w"
    Add "$(N $x1) $(N $y1) m"
    Add "$(N $x2) $(N $y2) l"
    Add "S"
}

function Draw-RoundedRect([double]$x, [double]$y, [double]$w, [double]$h, [double]$r, [double[]]$color) {
    Set-Fill $color
    $k = $r * $kappa
    Add "$(N ($x+$r)) $(N $y) m"
    Add "$(N ($x+$w-$r)) $(N $y) l"
    Add "$(N ($x+$w-$r+$k)) $(N $y) $(N ($x+$w)) $(N ($y+$r-$k)) $(N ($x+$w)) $(N ($y+$r)) c"
    Add "$(N ($x+$w)) $(N ($y+$h-$r)) l"
    Add "$(N ($x+$w)) $(N ($y+$h-$r+$k)) $(N ($x+$w-$r+$k)) $(N ($y+$h)) $(N ($x+$w-$r)) $(N ($y+$h)) c"
    Add "$(N ($x+$r)) $(N ($y+$h)) l"
    Add "$(N ($x+$r-$k)) $(N ($y+$h)) $(N $x) $(N ($y+$h-$r+$k)) $(N $x) $(N ($y+$h-$r)) c"
    Add "$(N $x) $(N ($y+$r)) l"
    Add "$(N $x) $(N ($y+$r-$k)) $(N ($x+$r-$k)) $(N $y) $(N ($x+$r)) $(N $y) c"
    Add "h f"
}

function Draw-Circle([double]$cx, [double]$cy, [double]$r, [double[]]$color) {
    Set-Fill $color
    $k = $r * $kappa
    Add "$(N ($cx+$r)) $(N $cy) m"
    Add "$(N ($cx+$r)) $(N ($cy+$k)) $(N ($cx+$k)) $(N ($cy+$r)) $(N $cx) $(N ($cy+$r)) c"
    Add "$(N ($cx-$k)) $(N ($cy+$r)) $(N ($cx-$r)) $(N ($cy+$k)) $(N ($cx-$r)) $(N $cy) c"
    Add "$(N ($cx-$r)) $(N ($cy-$k)) $(N ($cx-$k)) $(N ($cy-$r)) $(N $cx) $(N ($cy-$r)) c"
    Add "$(N ($cx+$k)) $(N ($cy-$r)) $(N ($cx+$r)) $(N ($cy-$k)) $(N ($cx+$r)) $(N $cy) c"
    Add "h f"
}

# ---- Build the document -------------------------------------------------

# Small green kicker label (letter-spaced, echoing .section-label)
$kicker = ($("FEE GUIDE 2026").ToCharArray() -join " ")
Draw-Text "F2" 9 $marginLeft $y $kicker $colGreen
$y -= 26

# Big serif heading (Times-Bold echoes the site's Lora serif headings)
Draw-Text "F3" 25 $marginLeft $y "Transparent Pricing" $colBlack
$y -= 22

Draw-Text "F1" 10 $marginLeft $y "All fees are listed below. A personalised treatment plan and exact costs will be" $colGray400
$y -= 14
Draw-Text "F1" 10 $marginLeft $y "confirmed at your consultation." $colGray400
$y -= 20

Draw-Line $marginLeft $y $marginRight $y 1 $colGray200
$y -= 26

# Note box (green-light, rounded, matching .pricing-note)
$noteLineH = 13
$notePadTop = 14
$notePadBottom = 12
$noteBoxH = $notePadTop + $notePadBottom + ($noteLines.Count * $noteLineH)
$noteBoxTop = $y
Draw-RoundedRect $marginLeft ($noteBoxTop - $noteBoxH) $contentWidth $noteBoxH 8 $colGreenLight
$textY = $noteBoxTop - $notePadTop
$importantW = Get-TextWidth "Important: " $helvBW 9
Draw-Text "F2" 9 ($marginLeft + 16) $textY "Important:" $colGreen
Draw-Text "F1" 9 ($marginLeft + 16 + $importantW) $textY $noteLines[0] $colGreen
for ($i = 1; $i -lt $noteLines.Count; $i++) {
    $textY -= $noteLineH
    Draw-Text "F1" 9 ($marginLeft + 16) $textY $noteLines[$i] $colGreen
}
$y = $noteBoxTop - $noteBoxH - 30

foreach ($cat in $categories) {
    Ensure-Space 46
    Draw-Circle ($marginLeft + 3) ($y + 3.5) 3 $colGreen
    Draw-Text "F2" 12 ($marginLeft + 14) $y $cat.Name $colBlack
    $y -= 8
    Draw-Line $marginLeft $y $marginRight $y 1.5 $colGreen
    $y -= 18
    $rowCount = $cat.Rows.Count
    for ($ri = 0; $ri -lt $rowCount; $ri++) {
        Ensure-Space 20
        $row = $cat.Rows[$ri]
        Draw-Text "F1" 9.5 $marginLeft $y $row[0] $colBlack
        Draw-TextRightAligned "F1" 9.5 $marginRight $y $row[1] $colBlack $helvW
        $y -= 8
        if ($ri -lt ($rowCount - 1)) {
            Draw-Line $marginLeft $y $marginRight $y 0.75 $colGray200
        }
        $y -= 12
    }
    $y -= 22
}

# Footer contact strip (green-light banner, matching .pricing-download-banner)
Ensure-Space 60
$y -= 6
$footerH = 40
Draw-RoundedRect $marginLeft ($y - $footerH) $contentWidth $footerH 8 $colGreenLight
Draw-Text "F2" 10 ($marginLeft + 16) ($y - 16) "Kings Dental Clinic" $colGreen
Draw-Text "F1" 9 ($marginLeft + 16) ($y - 30) "149 Kings Rd, Kings Park VIC 3021  |  (03) 9364 6156  |  info.kingsdentalclinic@gmail.com" $colGreen

Flush-Page

# ---- PDF assembly ----------------------------------------------------------

$pageCount = $pages.Count
$objects = New-Object System.Collections.Generic.List[string]

# Object numbering: 1=Catalog 2=Pages 3=F1(Helvetica) 4=F2(Helvetica-Bold) 5=F3(Times-Bold)
# then per page i (0-based): pageObj = 6+2*i, contentObj = 7+2*i
$kids = (0..($pageCount - 1) | ForEach-Object { "$(6 + 2*$_) 0 R" }) -join " "
$objects.Add("<< /Type /Catalog /Pages 2 0 R >>")
$objects.Add("<< /Type /Pages /Kids [$kids] /Count $pageCount >>")
$objects.Add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")
$objects.Add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>")
$objects.Add("<< /Type /Font /Subtype /Type1 /BaseFont /Times-Bold >>")

for ($i = 0; $i -lt $pageCount; $i++) {
    $contentObjNum = 7 + 2*$i
    $objects.Add("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $pageWidth $pageHeight] /Resources << /Font << /F1 3 0 R /F2 4 0 R /F3 5 0 R >> >> /Contents $contentObjNum 0 R >>")
    $streamText = $pages[$i]
    $byteLen = [System.Text.Encoding]::ASCII.GetByteCount($streamText)
    $objects.Add("<< /Length $byteLen >>`nstream`n$streamText`nendstream")
}

# ---- Write file with exact byte offsets ----------------------------------

$enc = [System.Text.Encoding]::ASCII
$fs = [System.IO.File]::Open($outPath, [System.IO.FileMode]::Create)
try {
    $offsets = New-Object System.Collections.Generic.List[long]

    $header = "%PDF-1.4`n"
    $fs.Write($enc.GetBytes($header), 0, $enc.GetByteCount($header))

    for ($n = 1; $n -le $objects.Count; $n++) {
        $offsets.Add($fs.Position)
        $objText = "$n 0 obj`n$($objects[$n-1])`nendobj`n"
        $bytes = $enc.GetBytes($objText)
        $fs.Write($bytes, 0, $bytes.Length)
    }

    $xrefOffset = $fs.Position
    $xrefHeader = "xref`n0 $($objects.Count + 1)`n"
    $fs.Write($enc.GetBytes($xrefHeader), 0, $enc.GetByteCount($xrefHeader))
    $fs.Write($enc.GetBytes("0000000000 65535 f`r`n"), 0, 20)
    foreach ($off in $offsets) {
        $entry = "{0:D10} 00000 n`r`n" -f $off
        $bytes = $enc.GetBytes($entry)
        if ($bytes.Length -ne 20) { throw "xref entry not 20 bytes: '$entry' ($($bytes.Length))" }
        $fs.Write($bytes, 0, 20)
    }

    $trailer = "trailer`n<< /Size $($objects.Count + 1) /Root 1 0 R >>`nstartxref`n$xrefOffset`n%%EOF"
    $fs.Write($enc.GetBytes($trailer), 0, $enc.GetByteCount($trailer))
}
finally {
    $fs.Close()
}

Write-Host "Wrote $outPath ($pageCount pages, $($objects.Count) objects)"
