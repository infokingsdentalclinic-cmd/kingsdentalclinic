#requires -Version 5.1
# Generates site/assets/kdc-price-list-2026.pdf directly (no external PDF libraries needed).
# Pricing data is transcribed verbatim from site/pricing.html so the PDF never drifts from the live page.

$ErrorActionPreference = "Stop"

$outPath = Join-Path $PSScriptRoot "..\site\assets\kdc-price-list-2026.pdf"

# ---- Content model -------------------------------------------------------

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
    "Important: This fee guide provides an estimate only. Exact costs are provided following",
    "consultation and a personalised treatment plan. Payment is due at the time of service unless",
    "prior arrangements have been made. We accept cash, EFTPOS, credit card, and payment plans.",
    "Health fund benefits apply - please check with your fund for your level of cover."
)

# ---- Layout: turn the content model into per-page draw commands ----------
# Each command: @{ F='F1'|'F2'; S=size; X=x; Y=y; T=text }

$pageWidth = 595
$pageHeight = 842
$marginLeft = 50
$marginRight = 50
$priceX = 400
$topY = 800
$bottomLimit = 55

$pages = @()
$current = @()
$y = $topY

function New-Page {
    $script:pages += ,$script:current
    $script:current = @()
    $script:y = $topY
}

function Add-Cmd([string]$font, [int]$size, [int]$x, [string]$text) {
    $script:current += @{ F = $font; S = $size; X = $x; Y = $script:y; T = $text }
}

function Ensure-Space([int]$need) {
    if (($script:y - $need) -lt $bottomLimit) {
        New-Page
    }
}

# Title block
Add-Cmd "F2" 18 $marginLeft "KINGS DENTAL CLINIC"
$y -= 22
Add-Cmd "F2" 13 $marginLeft "2026 Fee Guide"
$y -= 24

foreach ($line in $noteLines) {
    Add-Cmd "F1" 9 $marginLeft $line
    $y -= 13
}
$y -= 12

foreach ($cat in $categories) {
    Ensure-Space 30
    Add-Cmd "F2" 12 $marginLeft $cat.Name.ToUpper()
    $y -= 6
    Add-Cmd "F1" 8 $marginLeft "----------------------------------------------------------------------------------------"
    $y -= 14
    foreach ($row in $cat.Rows) {
        Ensure-Space 13
        Add-Cmd "F1" 9 $marginLeft $row[0]
        Add-Cmd "F1" 9 $priceX $row[1]
        $y -= 13
    }
    $y -= 12
}

Ensure-Space 40
$y -= 10
Add-Cmd "F1" 9 $marginLeft "149 Kings Rd, Kings Park VIC 3021  |  (03) 9364 6156  |  info.kingsdentalclinic@gmail.com"
$y -= 13
Add-Cmd "F1" 9 $marginLeft "kingsdentalclinic.com"

New-Page  # flush the last (current) page into $pages

# ---- PDF assembly ----------------------------------------------------------

function Escape-Pdf([string]$s) {
    # PowerShell's -replace uses .NET regex replacement text, where only `$` is special —
    # a literal backslash in the replacement is just itself, so a 2-char single-quoted
    # string ('\\') is what actually inserts two literal backslashes into the string.
    $s = $s -replace '\\', '\\'
    $s = $s -replace '\(', '\('
    $s = $s -replace '\)', '\)'
    return $s
}

$pageCount = $pages.Count
$contentStreams = New-Object System.Collections.Generic.List[string]

foreach ($page in $pages) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("BT`n")
    foreach ($cmd in $page) {
        $fontSize = $cmd.S
        $font = $cmd.F
        $x = $cmd.X
        $yPos = $cmd.Y
        $text = Escape-Pdf $cmd.T
        [void]$sb.Append("/$font $fontSize Tf`n")
        [void]$sb.Append("1 0 0 1 $x $yPos Tm`n")
        [void]$sb.Append("($text) Tj`n")
    }
    [void]$sb.Append("ET")
    $contentStreams.Add($sb.ToString())
}

# Object numbering: 1=Catalog 2=Pages 3=F1(Helvetica) 4=F2(Helvetica-Bold)
# then per page i (0-based): pageObj = 5+2*i, contentObj = 6+2*i
$objects = New-Object System.Collections.Generic.List[string]

$kids = (0..($pageCount - 1) | ForEach-Object { "$(5 + 2*$_) 0 R" }) -join " "
$objects.Add("<< /Type /Catalog /Pages 2 0 R >>")                                              # 1
$objects.Add("<< /Type /Pages /Kids [$kids] /Count $pageCount >>")                              # 2
$objects.Add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")                          # 3
$objects.Add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>")                     # 4

for ($i = 0; $i -lt $pageCount; $i++) {
    $pageObjNum = 5 + 2*$i
    $contentObjNum = 6 + 2*$i
    $objects.Add("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $pageWidth $pageHeight] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents $contentObjNum 0 R >>")
    $streamText = $contentStreams[$i]
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
