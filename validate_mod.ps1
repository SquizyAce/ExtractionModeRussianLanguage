$ErrorActionPreference = 'Stop'

$modRoot = Join-Path $PSScriptRoot 'Contents\mods\ExtractionModeRussianLanguage'
$translationRoot = Join-Path $modRoot '42\media\lua\shared\Translate\RU'
$englishRoot = 'D:\SteamLibrary\steamapps\workshop\content\108600\3785397275\mods\ExtractionMode\42\media\lua\shared\Translate\EN'
$catalogs = @('ContextMenu.json', 'IG_UI.json', 'ItemName.json', 'Sandbox.json', 'Tooltip.json')
$errors = [System.Collections.Generic.List[string]]::new()
$totalKeys = 0

foreach ($catalog in $catalogs) {
    $english = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $englishRoot $catalog) |
        ConvertFrom-Json -AsHashtable
    $russianPath = Join-Path $translationRoot $catalog
    $russian = Get-Content -Raw -Encoding UTF8 -LiteralPath $russianPath |
        ConvertFrom-Json -AsHashtable

    $totalKeys += $english.Count
    foreach ($key in $english.Keys) {
        if (-not $russian.ContainsKey($key)) {
            $errors.Add("${catalog}: отсутствует ключ ${key}")
            continue
        }
        if ([string]::IsNullOrWhiteSpace([string]$russian[$key])) {
            $errors.Add("${catalog}: пустое значение ${key}")
        }

        $englishPlaceholders = [regex]::Matches([string]$english[$key], '%\d+') | ForEach-Object Value | Sort-Object
        $russianPlaceholders = [regex]::Matches([string]$russian[$key], '%\d+') | ForEach-Object Value | Sort-Object
        if (($englishPlaceholders -join ',') -ne ($russianPlaceholders -join ',')) {
            $errors.Add("${catalog}: несовпадение плейсхолдеров ${key}")
        }
        if ([regex]::IsMatch([string]$russian[$key], '(?<!%)%(?![%0-9])')) {
            $errors.Add("${catalog}: неэкранированный знак процента ${key}")
        }
    }
    foreach ($key in $russian.Keys) {
        if (-not $english.ContainsKey($key)) {
            $errors.Add("${catalog}: лишний ключ ${key}")
        }
    }
}

foreach ($manifest in @('mod.info', 'common\mod.info', '42\mod.info')) {
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $modRoot $manifest)
    foreach ($expected in @(
        'id=ExtractionModeRussianLanguage',
        'modversion=1.0.1',
        'versionMin=42.20',
        'require=ExtractionMode'
    )) {
        if (-not $content.Contains($expected)) {
            $errors.Add("${manifest}: отсутствует ${expected}")
        }
    }
}

$ui = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $translationRoot 'IG_UI.json') |
    ConvertFrom-Json -AsHashtable
$expectedLightingMessage = 'Освещение убежища отключено. Установите улучшение «Освещение убежища».'
if ($ui['IGUI_ExtractionMode_HideoutLightingOffline'] -cne $expectedLightingMessage) {
    $errors.Add('IG_UI.json: неверный перевод сообщения об освещении убежища')
}
foreach ($entry in $ui.GetEnumerator()) {
    if ([string]$entry.Value -match 'обновлен') {
        $errors.Add("IG_UI.json: upgrade переведён как обновление в $($entry.Key)")
    }
}

$layoutPatch = Join-Path $modRoot '42\media\lua\client\ExtractionModeRussianLanguage\RussianUILayout.lua'
$layout = Get-Content -Raw -Encoding UTF8 -LiteralPath $layoutPatch
foreach ($expected in @('local HUD_WIDTH = 680', 'local TOWN_PICKER_WIDTH = 760', '== "RU"')) {
    if (-not $layout.Contains($expected)) {
        $errors.Add("RussianUILayout.lua: отсутствует ${expected}")
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "OK: ${totalKeys} ключей, плейсхолдеры, манифесты и RU UI-патч проверены."
