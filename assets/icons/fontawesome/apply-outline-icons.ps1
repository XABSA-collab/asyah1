$ErrorActionPreference = 'Stop'

$htmlPath = Join-Path $PSScriptRoot 'index.html'
$tablerIcons = Get-ChildItem -LiteralPath $PSScriptRoot -File -Filter 'tabler-*.svg'
foreach ($iconFile in $tablerIcons) {
    $iconSource = Get-Content -Raw -LiteralPath $iconFile.FullName
    $sanitizedSource = [regex]::Replace(
        $iconSource,
        '(?is)\s*<path\s+stroke="none"\s+d="M0 0h24v24H0z"\s+fill="none"\s*/>',
        ''
    )
    $sanitizedSource = [regex]::Replace(
        $sanitizedSource,
        '<(path|circle|rect|polyline|line|ellipse|polygon)\b(?![^>]*\bstyle=)',
        '<$1 style="fill:none!important;stroke:currentColor!important"'
    )
    if ($sanitizedSource -ne $iconSource) {
        [System.IO.File]::WriteAllText($iconFile.FullName, $sanitizedSource, [System.Text.UTF8Encoding]::new($false))
    }
}

$html = Get-Content -Raw -LiteralPath $htmlPath
$matches = [regex]::Matches($html, '(?is)<svg\b[^>]*>.*?</svg>')
if ($matches.Count -ne 53) {
    throw "تغيّر عدد SVG في الصفحة؛ المتوقع 53 والموجود $($matches.Count)."
}

$replacements = @{
     0 = @{ Name='mail';             Size=16; Class='site-icon icon-email' }
     2 = @{ Name='search';           Size=18 }
     3 = @{ Name='phone';            Size=16 }
     4 = @{ Name='search';           Size=16 }
     5 = @{ Name='contrast';         Size=18 }
     6 = @{ Name='contrast';         Size=18 }
     7 = @{ Name='printer';          Size=18 }
     8 = @{ Name='share-3';          Size=18 }
     9 = @{ Name='user';             Size=24 }
    10 = @{ Name='clipboard-list';   Size=28 }
    11 = @{ Name='checkbox';         Size=18 }
    12 = @{ Name='checkbox';         Size=26 }
    13 = @{ Name='diamond';          Size=28; Class='rayat-link-icon' }
    14 = @{ Name='chart-bar';        Size=18 }
    15 = @{ Name='checkbox';         Size=18 }
    16 = @{ Name='link';             Size=18 }
    17 = @{ Name='user';             Size=18 }
    18 = @{ Name='diamond';          Size=18 }
    19 = @{ Name='file-description'; Size=18 }
    20 = @{ Name='layout-grid';      Size=28; Class='icon' }
    21 = @{ Name='book';             Size=28 }
    22 = @{ Name='folder';           Size=28 }
    23 = @{ Name='device-laptop';    Size=28 }
    24 = @{ Name='world';            Size=28 }
    25 = @{ Name='share';            Size=28 }
    26 = @{ Name='brand-telegram';   Size=28 }
    27 = @{ Name='tool';             Size=28 }
    28 = @{ Name='user';             Size=28 }
    29 = @{ Name='link';             Size=28; Class='icon' }
    30 = @{ Name='phone';            Size=28; Class='icon' }
    31 = @{ Name='phone';            Size=18 }
    32 = @{ Name='hierarchy-3';      Size=24; Class='icon' }
    33 = @{ Name='x';                Size=18 }
    34 = @{ Name='stack';            Size=24 }
    35 = @{ Name='user';             Size=24 }
    36 = @{ Name='tool';             Size=24 }
    37 = @{ Name='circle-check';     Size=24 }
    38 = @{ Name='users';            Size=24 }
    39 = @{ Name='book';             Size=24 }
    40 = @{ Name='hierarchy-3';      Size=24 }
    41 = @{ Name='folder';           Size=24 }
    42 = @{ Name='align-left';       Size=28; Class='icon' }
    43 = @{ Name='x';                Size=18 }
    44 = @{ Name='clock';            Size=28; Class='icon' }
    45 = @{ Name='clock';            Size=28; Class='icon' }
    46 = @{ Name='calendar';         Size=28; Class='icon' }
    47 = @{ Name='x';                Size=18 }
    48 = @{ Name='x';                Size=18 }
    49 = @{ Name='x';                Size=18 }
    51 = @{ Name='x';                Size=18 }
    52 = @{ Name='calendar';         Size=17 }
}

function Get-IconMarkup {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [int] $Size,
        [string] $ExtraClass = ''
    )

    $iconPath = Join-Path $PSScriptRoot "tabler-$Name.svg"
    if (-not (Test-Path -LiteralPath $iconPath)) {
        throw "ملف الأيقونة مفقود: $iconPath"
    }

    $markup = Get-Content -Raw -LiteralPath $iconPath
    $markup = [regex]::Replace(
        $markup,
        '(?is)\s*<path\s+stroke="none"\s+d="M0 0h24v24H0z"\s+fill="none"\s*/>',
        ''
    )
    $markup = [regex]::Replace($markup, '\s+', ' ').Trim()
    $markup = [regex]::Replace($markup, 'width="24"', "width=`"$Size`"", 1)
    $markup = [regex]::Replace($markup, 'height="24"', "height=`"$Size`"", 1)
    $markup = [regex]::Replace($markup, '<svg\s+', '<svg aria-hidden="true" focusable="false" ', 1)
    if ($ExtraClass) {
        $markup = [regex]::Replace(
            $markup,
            'class="([^"]+)"',
            { param($m) 'class="' + $ExtraClass + ' ' + $m.Groups[1].Value + '"' },
            1
        )
    }
    return $markup
}

foreach ($index in ($replacements.Keys | Sort-Object -Descending)) {
    $match = $matches[$index]
    $config = $replacements[$index]
    $replacement = Get-IconMarkup -Name $config.Name -Size $config.Size -ExtraClass $config.Class
    $html = $html.Remove($match.Index, $match.Length).Insert($match.Index, $replacement)
}

[System.IO.File]::WriteAllText($htmlPath, $html, [System.Text.UTF8Encoding]::new($false))
Write-Output "Updated $($replacements.Count) inline icons in index.html."
