param(
  [ValidateSet('dev','prod')][string]$Flavor = 'dev',
  [ValidateSet('run','build')][string]$Action = 'run'
)
$ErrorActionPreference = 'Stop'
switch ($Action) {
  'run'   { flutter run --flavor $Flavor --dart-define=FLAVOR=$Flavor }
  'build' { flutter build apk --debug --flavor $Flavor --dart-define=FLAVOR=$Flavor }
}
