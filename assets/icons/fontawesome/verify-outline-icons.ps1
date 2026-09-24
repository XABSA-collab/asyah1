$ErrorActionPreference = 'Stop'

$expectedIcons = @(
    'tabler-align-left.svg',
    'tabler-book.svg',
    'tabler-calendar.svg',
    'tabler-chart-bar.svg',
    'tabler-circle-check.svg',
    'tabler-contrast.svg',
    'tabler-clipboard-list.svg',
    'tabler-clock.svg',
    'tabler-world.svg',
    'tabler-mail.svg',
    'tabler-file-description.svg',
    'tabler-folder.svg',
    'tabler-device-laptop.svg',
    'tabler-diamond.svg',
    'tabler-stack.svg',
    'tabler-link.svg',
    'tabler-search.svg',
    'tabler-brand-telegram.svg',
    'tabler-phone.svg',
    'tabler-printer.svg',
    'tabler-share-3.svg',
    'tabler-share.svg',
    'tabler-hierarchy-3.svg',
    'tabler-checkbox.svg',
    'tabler-layout-grid.svg',
    'tabler-user.svg',
    'tabler-users.svg',
    'tabler-tool.svg',
    'tabler-x.svg'
)

$errors = [System.Collections.Generic.List[string]]::new()
$oldFontAwesome = Get-ChildItem -LiteralPath $PSScriptRoot -File -Filter 'fa-*.svg'
if ($oldFontAwesome.Count -gt 0) {
    $errors.Add("وجدت ملفات Font Awesome القديمة: $($oldFontAwesome.Name -join ', ')")
}

$htmlPath = Join-Path $PSScriptRoot 'index.html'
$html = Get-Content -Raw -LiteralPath $htmlPath
$inlineSvgs = [regex]::Matches($html, '(?is)<svg\b[^>]*>.*?</svg>')
$functionalSvgCount = 0
foreach ($svgMatch in $inlineSvgs) {
    $svg = $svgMatch.Value
    if ($svg -match 'brand-logo-colored' -or $svg -match '<svg width="100%" viewBox="0 0 960 520"') {
        continue
    }

    $functionalSvgCount++
    $rootTag = [regex]::Match($svg, '(?is)^<svg\b[^>]*>').Value
    if ($rootTag -notmatch 'fill="none"' -or $rootTag -notmatch 'stroke="currentColor"') {
        $errors.Add("أيقونة مضمنة ليست خطّية بالكامل: $($rootTag.Substring(0, [Math]::Min(180, $rootTag.Length)))")
    }
    if ($rootTag -notmatch 'icon-tabler-') {
        $errors.Add("أيقونة مضمنة ليست من الحزمة الموحدة: $($rootTag.Substring(0, [Math]::Min(180, $rootTag.Length)))")
    }
    if ($svg -match 'fill="(?!none)[^"]+"') {
        $errors.Add('أيقونة مضمنة تحتوي تعبئة غير مسموحة')
    }
    if ($svg -match '<path\s+stroke="none"') {
        $errors.Add('أيقونة مضمنة تحتوي مسار خلفية يمكن أن يتحول إلى تعبئة')
    }
    foreach ($shape in [regex]::Matches($svg, '(?is)<(?:path|circle|rect|polyline|line|ellipse|polygon)\b[^>]*>')) {
        if ($shape.Value -notmatch 'style="fill:none!important;stroke:currentColor!important"') {
            $errors.Add('عنصر داخل أيقونة مضمنة غير محمي من تعبئة CSS القديمة')
            break
        }
    }
}

if ($functionalSvgCount -ne 51) {
    $errors.Add("العدد المتوقع للأيقونات الوظيفية المضمنة هو 51، والموجود $functionalSvgCount")
}
if ($html -notmatch '(?is)ethaq\.tvtc\.gov\.sa.{0,500}icon-tabler-world') {
    $errors.Add('أيقونة إيثاق ليست كرة أرضية خطّية')
}
if ($html -notmatch '(?is)<style id="outline-icon-hardening">.*?svg\.icon-tabler.*?fill\s*:\s*none\s*!important.*?stroke\s*:\s*currentColor\s*!important') {
    $errors.Add('قاعدة حماية الأيقونات الخطّية من CSS القديم مفقودة')
}
if ($html -match "(?is)btn\.title\s*===\s*'اللون الرمادي'.{0,300}important\(el,'fill','currentColor'\)") {
    $errors.Add('سكريبت الترويسة ما زال يحول أيقونة اللون الرمادي إلى تعبئة مصمتة')
}

foreach ($fileName in $expectedIcons) {
    $path = Join-Path $PSScriptRoot $fileName
    if (-not (Test-Path -LiteralPath $path)) {
        $errors.Add("الملف مفقود: $fileName")
        continue
    }

    $svg = Get-Content -Raw -LiteralPath $path
    if ($svg -notmatch 'viewBox="0 0 24 24"') {
        $errors.Add("شبكة الرسم ليست 24x24: $fileName")
    }
    if ($svg -notmatch '<svg[^>]+fill="none"') {
        $errors.Add("الأيقونة لا تعطل التعبئة: $fileName")
    }
    if ($svg -notmatch '<svg[^>]+stroke="currentColor"') {
        $errors.Add("الأيقونة لا تستخدم حدود currentColor: $fileName")
    }
    if ($svg -match 'fill="(?!none)[^"]+"') {
        $errors.Add("الأيقونة تحتوي تعبئة غير مسموحة: $fileName")
    }
    if ($svg -match '<path\s+stroke="none"') {
        $errors.Add("الأيقونة تحتوي مسار خلفية يمكن أن يتحول إلى تعبئة: $fileName")
    }
    foreach ($shape in [regex]::Matches($svg, '(?is)<(?:path|circle|rect|polyline|line|ellipse|polygon)\b[^>]*>')) {
        if ($shape.Value -notmatch 'style="fill:none!important;stroke:currentColor!important"') {
            $errors.Add("عنصر داخل الأيقونة غير محمي من تعبئة CSS القديمة: $fileName")
            break
        }
    }
}

$mapPath = Join-Path $PSScriptRoot 'OUTLINE_ICON_MAP_AR.md'
if (-not (Test-Path -LiteralPath $mapPath)) {
    $errors.Add('خريطة الأيقونات الجديدة OUTLINE_ICON_MAP_AR.md مفقودة')
} else {
    $map = Get-Content -Raw -LiteralPath $mapPath
    if ($map -notmatch 'إيثاق[^\r\n]+tabler-world\.svg') {
        $errors.Add('خريطة إيثاق لا تشير إلى tabler-world.svg')
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "PASS: $($expectedIcons.Count) outline SVG icons verified."
