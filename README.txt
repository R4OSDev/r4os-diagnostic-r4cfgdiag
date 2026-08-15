R4CFGD.R4X
==========

R4CFGD.R4X ist die R4STD-/R4S-Konfigurationsdiagnose.

Projektstruktur seit 0.51.21:
- `build.zig` baut die Diagnose als eigenes SDK-Projekt.
- `build.zig.zon` bindet `r4os_sdk` als Paket.
- `module.R4MF` beschreibt Artefakt, Zielpfad, R4L-Imports und Contract.

Build:

    cd Code\System\Diagnostics\R4CfgDiag
    ..\..\..\DevTools\Zig\zig.exe build

Ergebnis:

    Code\System\Diagnostics\R4CfgDiag\zig-out\R4CFGD.R4X

Contract:
- Build-Profil: `Zig/R4XStart`
- R4XStart-Entry: `r4cfgd_main`
- App-Klasse: `console`
- R4L-Imports: `R4SYS:Query:1`, `R4STD:SETTINGS_V1:1`,
  `R4STD:CONFIG_V1:1`
- Zielpfad im Image: `C:\R4OS\SOFTWARE\TERMINAL\DIAG\R4CFGD.R4X`
