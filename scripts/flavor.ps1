param(
  [ValidateSet('dev','prod')][string]$Flavor = 'dev',
  [ValidateSet('run','build','release')][string]$Action = 'run',
  [switch]$Arm64Only
)
$ErrorActionPreference = 'Stop'
switch ($Action) {
  'run'   { flutter run --flavor $Flavor --dart-define=FLAVOR=$Flavor }
  'build' { flutter build apk --debug --flavor $Flavor --dart-define=FLAVOR=$Flavor }
  'release' {
    # Release: obfuscated, per-ABI by default (Play Store requires split APKs).
    # -Arm64Only produces a single android-arm64 APK for internal testing.
    $targets = if ($Arm64Only) { @('--target-platform','android-arm64') } else { @('--split-per-abi') }
    $cmd = @(
      'build','apk','--release','--obfuscate',
      "--split-debug-info=build/symbols/$Flavor",
      '--flavor',$Flavor,"--dart-define=FLAVOR=$Flavor"
    ) + $targets
    flutter @cmd
  }
}
