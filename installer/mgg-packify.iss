; Inno Setup Script — MGG Packify
; Requires Inno Setup 6+ (https://jrsoftware.org/isinfo.php)
; Run: ISCC installer\mgg-packify.iss

#define AppName "MGG Packify"
#define AppVersion "3.9.1"
#define AppPublisher "Manuel García González"
#define AppURL "https://github.com/mgg-171093/mgg-packify"
#define AppExeName "mgg_packify.exe"
#define ApiExeName "mgg-packify-api.exe"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={localappdata}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=Output
OutputBaseFilename=MGGPackify-{#AppVersion}-Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\{#AppExeName}
CloseApplications=yes
CloseApplicationsFilter=mgg_packify.exe,mgg-packify-api.exe
RestartIfNeededByRun=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Flutter app + all DLLs
Source: "..\staging\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; API executable
Source: "..\api\dist\{#ApiExeName}"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
; Fallback: force-kill the API process in case it wasn't stopped gracefully
; (e.g. manual install without going through the in-app updater).
; taskkill exits with code 128 if the process isn't found — Inno Setup ignores [Run] exit codes.
Filename: "taskkill.exe"; Parameters: "/F /IM {#ApiExeName}"; Flags: runhidden nowait; StatusMsg: "Cerrando servicios..."
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[InstallDelete]
; Don't delete user config on upgrade
; config.json and options.json live in %APPDATA%\mgg_packify_api\ (not in install dir)
; so they're never touched by the installer

[UninstallDelete]
Type: filesandordirs; Name: "{app}\data"
