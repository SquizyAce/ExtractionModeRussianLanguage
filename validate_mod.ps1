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
        $isPrivateRussianUiKey = $catalog -eq 'IG_UI.json' -and
            $key.StartsWith('IGUI_ExtractionMode_RussianLanguage_')
        if (-not $english.ContainsKey($key) -and -not $isPrivateRussianUiKey) {
            $errors.Add("${catalog}: лишний ключ ${key}")
        }
        if ($isPrivateRussianUiKey) {
            if ([string]::IsNullOrWhiteSpace([string]$russian[$key])) {
                $errors.Add("${catalog}: пустое значение ${key}")
            }
            if ([regex]::IsMatch([string]$russian[$key], '(?<!%)%(?![%0-9])')) {
                $errors.Add("${catalog}: неэкранированный знак процента ${key}")
            }
        }
    }
}

foreach ($manifest in @('mod.info', 'common\mod.info', '42\mod.info')) {
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $modRoot $manifest)
    foreach ($expected in @(
        'id=ExtractionModeRussianLanguage',
        'modversion=1.0.3',
        'versionMin=42.20',
        'require=ExtractionMode'
    )) {
        if (-not $content.Contains($expected)) {
            $errors.Add("${manifest}: отсутствует ${expected}")
        }
    }
}

$workshop = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'workshop.txt')
if (-not $workshop.Contains('Extraction Mode 0.8.74')) {
    $errors.Add('workshop.txt: неверная версия переведённого оригинала')
}

$ui = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $translationRoot 'IG_UI.json') |
    ConvertFrom-Json -AsHashtable
$expectedLightingMessage = 'Освещение убежища отключено. Установите улучшение «Освещение убежища».'
if ($ui['IGUI_ExtractionMode_HideoutLightingOffline'] -cne $expectedLightingMessage) {
    $errors.Add('IG_UI.json: неверный перевод сообщения об освещении убежища')
}
$expectedUiTranslations = @{
    'IGUI_ExtractionMode_AddUpToLiters' = 'ДОБАВИТЬ %1 ЛИТРОВ'
    'IGUI_ExtractionMode_TurnIn' = 'СДАТЬ'
    'IGUI_ExtractionMode_Upgrade_ammo_delivery_Requirement_4' = 'Стальной лист'
    'IGUI_ExtractionMode_Upgrade_generator_tuneup_Requirement_2' = 'Изолента'
    'IGUI_ExtractionMode_Upgrade_generator_governor_Requirement_4' = 'Электрические детали'
    'IGUI_ExtractionMode_Upgrade_generator_governor_Skill_1' = 'Электрика'
    'IGUI_ExtractionMode_CoopWelcome_GotIt' = 'ПОНЯТНО'
    'IGUI_ExtractionMode_GarageDoorLocked' = 'Гараж заперт. Эвакуируйте автомобиль из рейда, чтобы открыть его.'
    'IGUI_ExtractionMode_OptOut' = 'ПРОПУСТИТЬ РЕЙД'
    'IGUI_ExtractionMode_JoinRaid' = 'ПРИСОЕДИНИТЬСЯ К РЕЙДУ'
    'IGUI_ExtractionMode_RussianLanguage_Garage_Message_VehicleSavedAfterRaid' = 'Автомобиль «%1» сохранён в вашем личном гараже.'
    'IGUI_ExtractionMode_RussianLanguage_Garage_Error_ExtractionDataUnsafe' = 'Эвакуация автомобиля отменена: данные машины или груза не удалось безопасно сохранить: %1'
}
foreach ($expectedTranslation in $expectedUiTranslations.GetEnumerator()) {
    if ($ui[$expectedTranslation.Key] -cne $expectedTranslation.Value) {
        $errors.Add("IG_UI.json: неверный перевод $($expectedTranslation.Key)")
    }
}
foreach ($entry in $ui.GetEnumerator()) {
    if ([string]$entry.Value -match 'обновлен') {
        $errors.Add("IG_UI.json: upgrade переведён как обновление в $($entry.Key)")
    }
    if ([string]$entry.Value -cmatch 'Листовой металл|Клейкая лента|Электронный лом|электронный лом') {
        $errors.Add("IG_UI.json: устаревший термин в $($entry.Key)")
    }
    if ($entry.Key -match '_Skill_\d+$' -and [string]$entry.Value -cmatch '^Электричество$|^Электрический$') {
        $errors.Add("IG_UI.json: навык электричества переведён неверно в $($entry.Key)")
    }
}

$layoutPatch = Join-Path $modRoot '42\media\lua\client\ExtractionModeRussianLanguage\RussianUILayout.lua'
$layout = Get-Content -Raw -Encoding UTF8 -LiteralPath $layoutPatch
foreach ($expected in @(
    'local HUD_WIDTH = 680',
    'local TOWN_PICKER_WIDTH = 760',
    'local COOP_WELCOME_WIDTH = 760',
    'local COOP_WELCOME_HEIGHT = 500',
    '== "RU"'
)) {
    if (-not $layout.Contains($expected)) {
        $errors.Add("RussianUILayout.lua: отсутствует ${expected}")
    }
}

$garagePatch = Join-Path $modRoot '42\media\lua\client\ExtractionModeRussianLanguage\RussianGarageCompatibility.lua'
$garage = Get-Content -Raw -Encoding UTF8 -LiteralPath $garagePatch
foreach ($expected in @(
    'require "ExtractionMode/GaragePanel"',
    'require "ExtractionMode/GarageControls"',
    'local PRIVATE_KEY_PREFIX = "IGUI_ExtractionMode_RussianLanguage_Garage_"',
    'local function patchGaragePanel()',
    'local function patchRawGarageMessages()',
    'Message_VehicleSavedAfterRaid',
    'Vehicle extraction was cancelled because its vehicle or cargo data could not be saved safely:',
    'self.storeButton:setY(534)',
    'self.transferButton:setY(614)',
    '== "RU"'
)) {
    if (-not $garage.Contains($expected)) {
        $errors.Add("RussianGarageCompatibility.lua: отсутствует ${expected}")
    }
}
if ($garage -match '[А-Яа-яЁё]') {
    $errors.Add('RussianGarageCompatibility.lua: кириллица должна храниться в Translate/RU, а не в клиентском Lua')
}

$privateGaragePrefix = 'IGUI_ExtractionMode_RussianLanguage_Garage_'
$privateGarageKeys = @($ui.Keys | Where-Object { $_.StartsWith($privateGaragePrefix) })
if ($privateGarageKeys.Count -eq 0) {
    $errors.Add('IG_UI.json: отсутствуют приватные ключи локализации гаража')
}
$referencedGarageSuffixes = [regex]::Matches($garage, 'localized\("([A-Za-z0-9_]+)"') |
    ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
foreach ($suffix in $referencedGarageSuffixes) {
    $key = $privateGaragePrefix + $suffix
    if (-not $ui.ContainsKey($key)) {
        $errors.Add("IG_UI.json: отсутствует используемый адаптером ключ ${key}")
    }
}
$mappedGarageSuffixes = [regex]::Matches($garage, '= "((?:Message|Error)_[A-Za-z0-9_]+)"') |
    ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
foreach ($suffix in $mappedGarageSuffixes) {
    $key = $privateGaragePrefix + $suffix
    if (-not $ui.ContainsKey($key)) {
        $errors.Add("IG_UI.json: отсутствует используемый адаптером ключ ${key}")
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "OK: ${totalKeys} штатных и $($privateGarageKeys.Count) приватных ключей, плейсхолдеры, манифесты и RU UI-патч проверены."
